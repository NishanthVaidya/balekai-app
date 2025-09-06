package balekai.designpatterns.service;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import balekai.designpatterns.model.User;
import balekai.designpatterns.repository.UserRepository;
import balekai.designpatterns.repository.BoardRepository;
import balekai.designpatterns.repository.CardRepository;

import java.util.Optional;

@Service
@Slf4j
public class FirebaseAuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BoardRepository boardRepository;

    @Autowired
    private CardRepository cardRepository;

    /**
     * Authenticates a Firebase token and returns the user ID
     * Also handles user linking if the email matches an existing email/password account
     */
    public String authenticateAndGetUserId(HttpServletRequest request) {
        try {
            String authHeader = request.getHeader("Authorization");
            if (authHeader == null || !authHeader.startsWith("Bearer ")) {
                log.warn("🔐 FirebaseAuthService: No valid Authorization header found");
                return null;
            }

            String token = authHeader.substring(7);
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(token);
            
            String firebaseUid = decodedToken.getUid();
            String email = decodedToken.getEmail();
            String name = decodedToken.getName();

            log.info("🔐 FirebaseAuthService: Authenticated Firebase user - UID: {}, Email: {}, Name: {}", 
                    firebaseUid, email, name);

            // Check if user exists with Firebase UID
            Optional<User> existingFirebaseUser = userRepository.findById(firebaseUid);
            if (existingFirebaseUser.isPresent()) {
                log.info("🔐 FirebaseAuthService: User found with Firebase UID: {}", firebaseUid);
                return firebaseUid;
            }

            // Check if user exists with same email but different ID (email/password account)
            Optional<User> existingEmailUser = userRepository.findByEmail(email);
            if (existingEmailUser.isPresent()) {
                User emailUser = existingEmailUser.get();
                log.info("🔐 FirebaseAuthService: Found existing email/password user with email: {}, ID: {}", 
                        email, emailUser.getId());
                
                // Link the Firebase account to the existing email/password account
                linkFirebaseUserToExistingAccount(emailUser.getId(), firebaseUid);
                return firebaseUid;
            }

            // Create new user for Firebase authentication
            User newUser = User.builder()
                    .id(firebaseUid)
                    .name(name)
                    .email(email)
                    .password("") // Empty password for Firebase users
                    .build();

            userRepository.save(newUser);
            log.info("🔐 FirebaseAuthService: Created new Firebase user with UID: {}", firebaseUid);
            
            return firebaseUid;

        } catch (Exception e) {
            log.error("🔐 FirebaseAuthService: Authentication failed: {}", e.getMessage());
            return null;
        }
    }

    /**
     * Links a Firebase user to an existing email/password account
     * Updates all foreign key references and then updates the user ID
     */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.REQUIRES_NEW)
    private void linkFirebaseUserToExistingAccount(String oldUserId, String newUserId) {
        try {
            // First, update all boards that reference the old user ID
            boardRepository.updateOwnerId(oldUserId, newUserId);
            log.info("🔐 FirebaseAuthService: Updated board ownership from {} to {}", oldUserId, newUserId);
            
            // Update all cards that reference the old user ID
            cardRepository.updateAssignedUserId(oldUserId, newUserId);
            log.info("🔐 FirebaseAuthService: Updated card assignments from {} to {}", oldUserId, newUserId);
            
            // Update the user's primary key using native SQL
            userRepository.updateUserId(oldUserId, newUserId);
            log.info("🔐 FirebaseAuthService: Updated user ID from {} to {}", oldUserId, newUserId);
            
        } catch (Exception e) {
            log.error("🔐 FirebaseAuthService: Failed to link Firebase user to existing account: {}", e.getMessage());
            throw new RuntimeException("Failed to link user accounts", e);
        }
    }
}
