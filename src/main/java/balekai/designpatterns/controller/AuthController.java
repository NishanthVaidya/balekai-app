package balekai.designpatterns.controller;
import org.mindrot.jbcrypt.BCrypt;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import balekai.designpatterns.model.User;
import balekai.designpatterns.repository.UserRepository;
import balekai.designpatterns.request.LoginRequest;
import balekai.designpatterns.request.RegisterRequest;
import balekai.designpatterns.service.JwtService;

import java.util.Optional;
import java.util.Map;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Profile("!test") // Don't load this controller in test profile
public class AuthController {

    private final UserRepository userRepository;
    private final JwtService jwtService;

    @GetMapping("/test")
    public ResponseEntity<?> testFirebase() {
        try {
            // Check if Firebase is initialized
            com.google.firebase.FirebaseApp app = com.google.firebase.FirebaseApp.getInstance();
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "Firebase is working!",
                "firebaseApp", app.getName(),
                "firebaseProject", app.getOptions().getProjectId()
            ));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of(
                "status", "error",
                "message", "Firebase not working: " + e.getMessage()
            ));
        }
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        if (userRepository.findByEmail(request.getEmail()).isPresent()) {
            return ResponseEntity.badRequest().body("Email already in use");
        }

        String hashedPassword = BCrypt.hashpw(request.getPassword(), BCrypt.gensalt());

        // Generate a unique ID for traditional registration
        String userId = "user_" + System.currentTimeMillis() + "_" + (int)(Math.random() * 1000);

        User user = User.builder()
                .id(userId)
                .name(request.getName())
                .email(request.getEmail())
                .password(hashedPassword)
                .build();

        userRepository.save(user);
        String jwt = jwtService.generateToken(user.getEmail());
        return ResponseEntity.ok(jwt);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody RegisterRequest request) {
        Optional<User> userOptional = userRepository.findByEmail(request.getEmail());

        if (userOptional.isEmpty()) {
            return ResponseEntity.status(401).body("Invalid credentials");
        }

        User user = userOptional.get();

        if (!BCrypt.checkpw(request.getPassword(), user.getPassword())) {
            return ResponseEntity.status(401).body("Invalid credentials");
        }

        String jwt = jwtService.generateToken(user.getEmail());
        return ResponseEntity.ok(jwt);
    }
}
