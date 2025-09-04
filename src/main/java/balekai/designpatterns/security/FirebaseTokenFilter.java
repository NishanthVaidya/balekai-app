package balekai.designpatterns.security;

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
        
        // Skip authentication for auth endpoints
        if (requestURI.startsWith("/auth")) {
            log.info("🔐 FirebaseTokenFilter: Skipping auth for auth endpoint {}", requestURI);
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
                String username = jwtService.extractUsername(token);
                log.info("🔐 FirebaseTokenFilter: JWT token verified for user {}", username);
                
                // Store the decoded token attributes on the request for controller access
                request.setAttribute("firebaseUid", username);
                request.setAttribute("firebaseName", username);
                request.setAttribute("firebaseEmail", username);
                
                // Continue with the request
                log.info("🔐 FirebaseTokenFilter: Continuing filter chain for {}", requestURI);
                filterChain.doFilter(request, response);
                return;
                
            } catch (Exception e) {
                log.info("🔐 FirebaseTokenFilter: JWT token verification failed, trying Firebase token");
                
                // Try Firebase token
                try {
                    FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(token);
                    String uid = decodedToken.getUid();
                    String name = decodedToken.getName();
                    String email = decodedToken.getEmail();

                    log.info("🔐 FirebaseTokenFilter: Firebase token verified for user {}", uid);

                    // Store the decoded token attributes on the request for controller access
                    request.setAttribute("firebaseUid", uid);
                    request.setAttribute("firebaseName", name);
                    request.setAttribute("firebaseEmail", email);

                    // Auto-create user in the local DB if they don't already exist
                    Optional<User> existingUser = userRepository.findById(uid);
                    if (existingUser.isEmpty()) {
                        User newUser = User.builder()
                                .id(uid)
                                .name(name != null ? name : "Unnamed")
                                .email(email != null ? email : "no-email")
                                .password("") // Password empty for Firebase-authenticated users
                                .build();
                        userRepository.save(newUser);
                        log.info("🔐 FirebaseTokenFilter: Created new user {}", uid);
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
