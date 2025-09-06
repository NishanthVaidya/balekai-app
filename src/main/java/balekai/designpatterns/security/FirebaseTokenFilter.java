package balekai.designpatterns.security;

import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Profile;
import org.springframework.web.filter.OncePerRequestFilter;
import balekai.designpatterns.model.User;
import balekai.designpatterns.repository.UserRepository;

import java.io.IOException;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import balekai.designpatterns.service.JwtService;

@Profile("!test") // Don't load this filter in test profile
public class FirebaseTokenFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(FirebaseTokenFilter.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtService jwtService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String requestURI = request.getRequestURI();
        String requestMethod = request.getMethod();
        log.info("🔐 FirebaseTokenFilter: Processing {} request to {}", requestMethod, requestURI);
        
        // Skip authentication for auth endpoints and health check
        if (requestURI.startsWith("/auth") || requestURI.equals("/health")) {
            log.info("🔐 FirebaseTokenFilter: Skipping auth for endpoint {}", requestURI);
            filterChain.doFilter(request, response);
            return;
        }
        
        // Allow OPTIONS requests (CORS preflight) to pass through
        if ("OPTIONS".equals(requestMethod)) {
            log.info("🔐 FirebaseTokenFilter: Allowing OPTIONS request for CORS preflight");
            filterChain.doFilter(request, response);
            return;
        }
        
        String authHeader = request.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            log.info("🔐 FirebaseTokenFilter: Found Authorization header");
            String token = authHeader.substring(7);

            // Try JWT token first
            try {
                String email = jwtService.extractUsername(token);
                log.info("🔐 FirebaseTokenFilter: JWT token verified for email {}", email);
                
                // Look up the user by email to get their actual user ID
                Optional<User> userOptional = userRepository.findByEmail(email);
                if (userOptional.isEmpty()) {
                    log.warn("🔐 FirebaseTokenFilter: JWT user not found in database: {}", email);
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.getWriter().write("{\"error\":\"Unauthorized\",\"message\":\"User not found\"}");
                    return;
                }
                
                User user = userOptional.get();
                log.info("🔐 FirebaseTokenFilter: Found user with ID: {}", user.getId());
                
                // Store the user's actual ID and other attributes
                request.setAttribute("firebaseUid", user.getId());
                request.setAttribute("firebaseName", user.getName());
                request.setAttribute("firebaseEmail", user.getEmail());
                
                // Continue with the request
                log.info("🔐 FirebaseTokenFilter: Continuing filter chain for {}", requestURI);
                filterChain.doFilter(request, response);
                return;
                
            } catch (Exception e) {
                log.info("🔐 FirebaseTokenFilter: JWT token verification failed, trying Firebase token");
                
                // Try Firebase token
                try {
                    // Check if Firebase is initialized
                    if (FirebaseApp.getApps().isEmpty()) {
                        log.warn("🔐 FirebaseTokenFilter: Firebase not initialized, skipping Firebase token verification");
                        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                        response.getWriter().write("{\"error\":\"Unauthorized\",\"message\":\"Firebase not configured\"}");
                        return;
                    }
                    
                    FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(token);
                    String uid = decodedToken.getUid();
                    String name = decodedToken.getName();
                    String email = decodedToken.getEmail();

                    log.info("🔐 FirebaseTokenFilter: Firebase token verified for user {}", uid);

                    // Store the decoded token attributes on the request for controller access
                    request.setAttribute("firebaseUid", uid);
                    request.setAttribute("firebaseName", name);
                    request.setAttribute("firebaseEmail", email);

                    // Check if user exists by Firebase UID first
                    Optional<User> existingUserByUid = userRepository.findById(uid);
                    if (existingUserByUid.isPresent()) {
                        log.info("🔐 FirebaseTokenFilter: Found existing user by Firebase UID: {}", uid);
                        // User already exists, continue
                    } else {
                        // Check if user exists by email (to link Firebase UID to existing user)
                        Optional<User> existingUserByEmail = userRepository.findByEmail(email);
                        if (existingUserByEmail.isPresent()) {
                            // User exists with email/password, link Firebase UID to existing user
                            User existingUser = existingUserByEmail.get();
                            log.info("🔐 FirebaseTokenFilter: Linking Firebase UID {} to existing user {}", uid, existingUser.getId());
                            
                            // Update the existing user's ID to the Firebase UID
                            // This is a bit tricky since we can't change the primary key directly
                            // We'll need to create a new user with the Firebase UID and delete the old one
                            User newUser = User.builder()
                                    .id(uid) // Use Firebase UID as the new ID
                                    .name(existingUser.getName())
                                    .email(existingUser.getEmail())
                                    .password(existingUser.getPassword()) // Keep the existing password
                                    .build();
                            
                            // Save the new user and delete the old one
                            userRepository.save(newUser);
                            userRepository.delete(existingUser);
                            
                            log.info("🔐 FirebaseTokenFilter: Successfully linked Firebase UID to existing user");
                        } else {
                            // Create new user for Firebase authentication
                            User newUser = User.builder()
                                    .id(uid)
                                    .name(name != null ? name : "Unnamed")
                                    .email(email != null ? email : "no-email")
                                    .password("") // Password empty for Firebase-authenticated users
                                    .build();
                            userRepository.save(newUser);
                            log.info("🔐 FirebaseTokenFilter: Created new user {}", uid);
                        }
                    }

                } catch (FirebaseAuthException fe) {
                    log.error("🔐 FirebaseTokenFilter: Both JWT and Firebase token verification failed");
                    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    response.getWriter().write("{\"error\":\"Unauthorized\",\"message\":\"Invalid token\"}");
                    return;
                }
            }
        } else {
            log.warn("🔐 FirebaseTokenFilter: No valid Authorization header found for {}", requestURI);
            // Block unauthenticated requests to protected endpoints
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\":\"Unauthorized\",\"message\":\"Authentication required\"}");
            return;
        }

        // Continue with the request for Firebase tokens
        log.info("🔐 FirebaseTokenFilter: Continuing filter chain for {}", requestURI);
        filterChain.doFilter(request, response);
    }
}