package trelllo.security;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import trelllo.model.User;
import trelllo.repository.UserRepository;

import java.io.IOException;
import java.util.Optional;


public class FirebaseTokenFilter extends OncePerRequestFilter {

    @Autowired
    private UserRepository userRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);

            try {
                FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(token);
                String uid = decodedToken.getUid();
                String name = decodedToken.getName();
                String email = decodedToken.getEmail();

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
                }

            } catch (FirebaseAuthException e) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                return;
            }
        }

        filterChain.doFilter(request, response);
    }
}
