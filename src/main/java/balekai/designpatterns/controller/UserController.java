package balekai.designpatterns.controller;

import balekai.designpatterns.model.User;
import balekai.designpatterns.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.servlet.http.HttpServletRequest;

import java.util.List;
import java.util.Optional;

@RestController
@RequiredArgsConstructor
@Slf4j
@Profile("!test") // Don't load this controller in test profile
public class UserController {

    private final UserRepository userRepository;

    @GetMapping("/")
    public String root() {
        return "Kardo API is running!";
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }

    @GetMapping("/users")
    public ResponseEntity<?> getUsers(HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        List<User> users = userRepository.findAll();
        return ResponseEntity.ok(users);
    }

    @GetMapping("/users/{id}")
    public ResponseEntity<?> getUserById(@PathVariable String id, HttpServletRequest request) {
        // Get authenticated user
        String userEmail = (String) request.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        Optional<User> user = userRepository.findById(id);
        if (user.isPresent()) {
            return ResponseEntity.ok(user.get());
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/users/{id}")
    public ResponseEntity<?> updateUser(@PathVariable String id, @RequestBody UserUpdateRequest request, HttpServletRequest httpRequest) {
        // Get authenticated user
        String userEmail = (String) httpRequest.getAttribute("authenticatedUserEmail");
        if (userEmail == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        User authenticatedUser = userRepository.findByEmail(userEmail).orElse(null);
        if (authenticatedUser == null) {
            return ResponseEntity.status(401).body("User not found");
        }

        log.info("Updating user {} with data: name={}, email={}", id, request.getName(), request.getEmail());
        
        try {
            Optional<User> existingUser = userRepository.findById(id);
            if (!existingUser.isPresent()) {
                log.warn("User not found with id: {}", id);
                return ResponseEntity.notFound().build();
            }

            User user = existingUser.get();
            
            // Check if email is being changed and if it already exists
            if (request.getEmail() != null && !request.getEmail().equals(user.getEmail())) {
                Optional<User> emailExists = userRepository.findByEmail(request.getEmail());
                if (emailExists.isPresent() && !emailExists.get().getId().equals(id)) {
                    log.warn("Email {} already exists for another user", request.getEmail());
                    return ResponseEntity.badRequest().body("Email already in use");
                }
                user.setEmail(request.getEmail());
            }
            
            // Update name if provided
            if (request.getName() != null && !request.getName().trim().isEmpty()) {
                user.setName(request.getName().trim());
            }
            
            User updatedUser = userRepository.save(user);
            log.info("Successfully updated user {}: name={}, email={}", id, updatedUser.getName(), updatedUser.getEmail());
            
            return ResponseEntity.ok(updatedUser);
            
        } catch (Exception e) {
            log.error("Error updating user {}: {}", id, e.getMessage(), e);
            return ResponseEntity.internalServerError().body("Failed to update user profile");
        }
    }

    // Request DTO for user updates
    public static class UserUpdateRequest {
        private String name;
        private String email;

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getEmail() {
            return email;
        }

        public void setEmail(String email) {
            this.email = email;
        }
    }
}

