package balekai.designpatterns.controller;
import org.mindrot.jbcrypt.BCrypt;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
import java.util.UUID;
import java.util.List;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
@Slf4j
@Profile("!test") // Don't load this controller in test profile
public class AuthController {

    private final UserRepository userRepository;
    private final JwtService jwtService;

    @GetMapping("/db-test")
    public ResponseEntity<?> testDatabase() {
        String requestId = UUID.randomUUID().toString().substring(0, 8);
        long startTime = System.currentTimeMillis();
        
        log.info("[{}] DB_TEST_START", requestId);
        
        try {
            // Test database connection
            long dbStart = System.currentTimeMillis();
            long userCount = userRepository.count();
            long dbTime = System.currentTimeMillis() - dbStart;
            
            long totalTime = System.currentTimeMillis() - startTime;
            
            log.info("[{}] DB_TEST_SUCCESS - DB query took {}ms, total {}ms, userCount: {}", 
                requestId, dbTime, totalTime, userCount);
            
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "requestId", requestId,
                "dbQueryTime", dbTime,
                "totalTime", totalTime,
                "userCount", userCount,
                "timestamp", System.currentTimeMillis()
            ));
            
        } catch (Exception e) {
            long totalTime = System.currentTimeMillis() - startTime;
            log.error("[{}] DB_TEST_ERROR - Failed after {}ms: {}", requestId, totalTime, e.getMessage(), e);
            
            return ResponseEntity.status(500).body(Map.of(
                "status", "error",
                "requestId", requestId,
                "error", e.getMessage(),
                "totalTime", totalTime,
                "timestamp", System.currentTimeMillis()
            ));
        }
    }

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
        String requestId = UUID.randomUUID().toString().substring(0, 8);
        long startTime = System.currentTimeMillis();
        
        log.info("[{}] REGISTER_START - Email: {}, Name: {}", requestId, request.getEmail(), request.getName());
        
        try {
            // Step 1: Check if email exists
            log.info("[{}] REGISTER_STEP_1 - Checking email existence", requestId);
            long step1Start = System.currentTimeMillis();
            
            if (userRepository.findByEmail(request.getEmail()).isPresent()) {
                log.warn("[{}] REGISTER_FAILED - Email already exists: {}", requestId, request.getEmail());
                return ResponseEntity.badRequest().body("Email already in use");
            }
            
            long step1Time = System.currentTimeMillis() - step1Start;
            log.info("[{}] REGISTER_STEP_1_COMPLETE - Email check took {}ms", requestId, step1Time);

            // Step 2: Hash password with optimized cost
            log.info("[{}] REGISTER_STEP_2 - Starting password hash", requestId);
            long step2Start = System.currentTimeMillis();
            
            // Use cost 8 for faster hashing on constrained containers
            String hashedPassword = BCrypt.hashpw(request.getPassword(), BCrypt.gensalt(8));
            
            long step2Time = System.currentTimeMillis() - step2Start;
            log.info("[{}] REGISTER_STEP_2_COMPLETE - Password hash took {}ms", requestId, step2Time);

            // Step 3: Create user object
            log.info("[{}] REGISTER_STEP_3 - Creating user object", requestId);
            String userId = "user_" + System.currentTimeMillis() + "_" + (int)(Math.random() * 1000);

            User user = User.builder()
                    .id(userId)
                    .name(request.getName())
                    .email(request.getEmail())
                    .password(hashedPassword)
                    .build();

            // Step 4: Save to database
            log.info("[{}] REGISTER_STEP_4 - Saving user to database", requestId);
            long step4Start = System.currentTimeMillis();
            
            userRepository.save(user);
            
            long step4Time = System.currentTimeMillis() - step4Start;
            log.info("[{}] REGISTER_STEP_4_COMPLETE - Database save took {}ms", requestId, step4Time);

            // Step 5: Generate JWT tokens
            log.info("[{}] REGISTER_STEP_5 - Generating JWT tokens", requestId);
            long step5Start = System.currentTimeMillis();
            
            Map<String, String> tokens = jwtService.generateTokenPair(user.getEmail());
            
            long step5Time = System.currentTimeMillis() - step5Start;
            log.info("[{}] REGISTER_STEP_5_COMPLETE - JWT generation took {}ms", requestId, step5Time);

            long totalTime = System.currentTimeMillis() - startTime;
            log.info("[{}] REGISTER_SUCCESS - Total time: {}ms, UserId: {}", requestId, totalTime, userId);
            
            // Return only tokens (previous behavior)
            return ResponseEntity.ok(tokens);
            
        } catch (Exception e) {
            long totalTime = System.currentTimeMillis() - startTime;
            log.error("[{}] REGISTER_ERROR - Failed after {}ms: {}", requestId, totalTime, e.getMessage(), e);
            return ResponseEntity.status(500).body("Registration failed: " + e.getMessage());
        }
    }

    @PostMapping("/register-debug")
    public ResponseEntity<?> registerDebug(@RequestBody RegisterRequest request) {
        String requestId = UUID.randomUUID().toString().substring(0, 8);
        long startTime = System.currentTimeMillis();
        
        log.info("[{}] DEBUG_REGISTER_START - Email: {}, Name: {}", requestId, request.getEmail(), request.getName());
        
        try {
            // Step 1: Quick email check
            log.info("[{}] DEBUG_STEP_1 - Quick email check", requestId);
            long step1Start = System.currentTimeMillis();
            
            if (userRepository.findByEmail(request.getEmail()).isPresent()) {
                log.warn("[{}] DEBUG_FAILED - Email already exists: {}", requestId, request.getEmail());
                return ResponseEntity.badRequest().body("Email already in use");
            }
            
            long step1Time = System.currentTimeMillis() - step1Start;
            log.info("[{}] DEBUG_STEP_1_COMPLETE - Email check took {}ms", requestId, step1Time);

            // Step 2: Skip password hashing (use plain text for debugging)
            log.info("[{}] DEBUG_STEP_2 - Skipping password hash", requestId);
            String debugPassword = "DEBUG_HASHED_" + request.getPassword();

            // Step 3: Create user object
            log.info("[{}] DEBUG_STEP_3 - Creating user object", requestId);
            String userId = "debug_user_" + System.currentTimeMillis();

            User user = User.builder()
                    .id(userId)
                    .name(request.getName())
                    .email(request.getEmail())
                    .password(debugPassword)
                    .build();

            // Step 4: Save to database
            log.info("[{}] DEBUG_STEP_4 - Saving user to database", requestId);
            long step4Start = System.currentTimeMillis();
            
            userRepository.save(user);
            
            long step4Time = System.currentTimeMillis() - step4Start;
            log.info("[{}] DEBUG_STEP_4_COMPLETE - Database save took {}ms", requestId, step4Time);

            // Step 5: Generate JWT
            log.info("[{}] DEBUG_STEP_5 - Generating JWT token", requestId);
            long step5Start = System.currentTimeMillis();
            
            String jwt = jwtService.generateToken(user.getEmail());
            
            long step5Time = System.currentTimeMillis() - step5Start;
            log.info("[{}] DEBUG_STEP_5_COMPLETE - JWT generation took {}ms", requestId, step5Time);

            long totalTime = System.currentTimeMillis() - startTime;
            log.info("[{}] DEBUG_SUCCESS - Total time: {}ms, UserId: {}", requestId, totalTime, userId);
            
            return ResponseEntity.ok(Map.of(
                "token", jwt,
                "debug", true,
                "timing", Map.of(
                    "total", totalTime,
                    "emailCheck", step1Time,
                    "dbSave", step4Time,
                    "jwtGeneration", step5Time
                ),
                "userId", userId
            ));
            
        } catch (Exception e) {
            long totalTime = System.currentTimeMillis() - startTime;
            log.error("[{}] DEBUG_ERROR - Failed after {}ms: {}", requestId, totalTime, e.getMessage(), e);
            return ResponseEntity.status(500).body(Map.of(
                "error", "Debug registration failed: " + e.getMessage(),
                "timing", totalTime
            ));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        Optional<User> userOptional = userRepository.findByEmail(request.getEmail());

        if (userOptional.isEmpty()) {
            return ResponseEntity.status(401).body("Invalid credentials");
        }

        User user = userOptional.get();

        if (!BCrypt.checkpw(request.getPassword(), user.getPassword())) {
            return ResponseEntity.status(401).body("Invalid credentials");
        }

        // Generate both access and refresh tokens
        Map<String, String> tokens = jwtService.generateTokenPair(user.getEmail());
        
        // Return only tokens (previous behavior)
        return ResponseEntity.ok(tokens);
    }
    
    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(@RequestBody Map<String, String> request) {
        String refreshToken = request.get("refreshToken");
        
        if (refreshToken == null || refreshToken.isEmpty()) {
            return ResponseEntity.status(401).body("Refresh token is required");
        }
        
        try {
            // Validate the refresh token
            if (jwtService.isTokenExpired(refreshToken)) {
                return ResponseEntity.status(401).body("Refresh token has expired");
            }
            
            if (!jwtService.isRefreshToken(refreshToken)) {
                return ResponseEntity.status(401).body("Invalid refresh token type");
            }
            
            // Extract username from refresh token
            String username = jwtService.extractUsername(refreshToken);
            
            // Verify user still exists
            Optional<User> userOptional = userRepository.findByEmail(username);
            if (userOptional.isEmpty()) {
                return ResponseEntity.status(401).body("User not found");
            }
            
            // Generate new token pair
            Map<String, String> newTokens = jwtService.generateTokenPair(username);
            
            log.info("Token refreshed successfully for user: {}", username);
            return ResponseEntity.ok(newTokens);
            
        } catch (Exception e) {
            log.error("Token refresh failed: {}", e.getMessage());
            return ResponseEntity.status(401).body("Invalid refresh token");
        }
    }

    @DeleteMapping("/cleanup-test-users")
    public ResponseEntity<?> cleanupTestUsers() {
        String requestId = UUID.randomUUID().toString().substring(0, 8);
        long startTime = System.currentTimeMillis();
        
        log.info("[{}] CLEANUP_START - Removing test users", requestId);
        
        try {
            // Find and delete test users
            List<User> allUsers = userRepository.findAll();
            int deletedCount = 0;
            
            for (User user : allUsers) {
                // Delete users with test patterns
                if (user.getId().startsWith("test-user-") || 
                    user.getId().startsWith("debug_user_") ||
                    user.getId().startsWith("user_") ||
                    user.getEmail().contains("@test.com") ||
                    user.getEmail().contains("test-") ||
                    user.getEmail().contains("debug-") ||
                    user.getName().contains("Test") ||
                    user.getName().contains("AWS Test")) {
                    
                    log.info("[{}] DELETING_TEST_USER - ID: {}, Email: {}, Name: {}", 
                        requestId, user.getId(), user.getEmail(), user.getName());
                    
                    userRepository.delete(user);
                    deletedCount++;
                }
            }
            
            long totalTime = System.currentTimeMillis() - startTime;
            long remainingUsers = userRepository.count();
            
            log.info("[{}] CLEANUP_SUCCESS - Deleted {} test users, {} users remaining, took {}ms", 
                requestId, deletedCount, remainingUsers, totalTime);
            
            return ResponseEntity.ok(Map.of(
                "status", "success",
                "requestId", requestId,
                "deletedCount", deletedCount,
                "remainingUsers", remainingUsers,
                "totalTime", totalTime
            ));
            
        } catch (Exception e) {
            long totalTime = System.currentTimeMillis() - startTime;
            log.error("[{}] CLEANUP_FAILED - Error: {}, took {}ms", requestId, e.getMessage(), totalTime);
            return ResponseEntity.status(500).body(Map.of(
                "status", "error",
                "requestId", requestId,
                "error", e.getMessage(),
                "totalTime", totalTime
            ));
        }
    }
}
