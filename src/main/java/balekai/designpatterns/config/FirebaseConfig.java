package balekai.designpatterns.config;

import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;

import java.io.IOException;
import java.io.InputStream;

@Slf4j
@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void init() throws IOException {
        log.info("🔥 Initializing Firebase configuration...");
        
        try {
            // Try to load Firebase service account from classpath resources first
            ClassPathResource resource = new ClassPathResource("firebase-service-account.json");
            log.info("📁 Firebase config file found: {}", resource.exists());
            log.info("📁 Firebase config file path: {}", resource.getPath());
            
            if (resource.exists()) {
                try (InputStream serviceAccount = resource.getInputStream()) {
                    log.info("📖 Reading Firebase service account from file...");
                    
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                            .build();

                    log.info("🔧 Firebase options built successfully from file");
                    log.info("🔧 Project ID: {}", options.getProjectId());

                    if (FirebaseApp.getApps().isEmpty()) {
                        FirebaseApp app = FirebaseApp.initializeApp(options);
                        log.info("✅ Firebase initialized successfully from file: {}", app.getName());
                    } else {
                        log.info("ℹ️ Firebase already initialized");
                    }
                    return;
                }
            } else {
                log.warn("⚠️ Firebase service account file not found, trying environment variables...");
                
                // Try to initialize with environment variables
                String projectId = System.getenv("FIREBASE_PROJECT_ID");
                String privateKey = System.getenv("FIREBASE_PRIVATE_KEY");
                String clientEmail = System.getenv("FIREBASE_CLIENT_EMAIL");
                
                if (projectId != null && privateKey != null && clientEmail != null) {
                    log.info("📖 Reading Firebase service account from environment variables...");
                    
                    // Create service account JSON from environment variables
                    String privateKeyId = System.getenv("FIREBASE_PRIVATE_KEY_ID");
                    String clientId = System.getenv("FIREBASE_CLIENT_ID");
                    
                    if (privateKeyId == null) privateKeyId = "default-key-id";
                    if (clientId == null) clientId = "default-client-id";
                    
                    String serviceAccountJson = String.format(
                        "{\"type\":\"service_account\",\"project_id\":\"%s\",\"private_key_id\":\"%s\",\"private_key\":\"%s\",\"client_email\":\"%s\",\"client_id\":\"%s\",\"auth_uri\":\"https://accounts.google.com/o/oauth2/auth\",\"token_uri\":\"https://oauth2.googleapis.com/token\",\"auth_provider_x509_cert_url\":\"https://www.googleapis.com/oauth2/v1/certs\",\"client_x509_cert_url\":\"https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%%40%s.iam.gserviceaccount.com\",\"universe_domain\":\"googleapis.com\"}",
                        projectId, privateKeyId, privateKey, clientEmail, clientId, projectId
                    );
                    
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(
                                new java.io.ByteArrayInputStream(serviceAccountJson.getBytes())
                            ))
                            .build();

                    log.info("🔧 Firebase options built successfully from environment");
                    log.info("🔧 Project ID: {}", options.getProjectId());

                    if (FirebaseApp.getApps().isEmpty()) {
                        FirebaseApp app = FirebaseApp.initializeApp(options);
                        log.info("✅ Firebase initialized successfully from environment: {}", app.getName());
                    } else {
                        log.info("ℹ️ Firebase already initialized");
                    }
                    return;
                } else {
                    log.warn("⚠️ Firebase environment variables not found, Firebase authentication will be disabled");
                    log.warn("⚠️ Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL environment variables");
                    return;
                }
            }
        } catch (Exception e) {
            log.error("❌ Firebase initialization failed: {}", e.getMessage());
            log.warn("⚠️ Firebase authentication will be disabled");
            // Don't throw the exception to allow the application to start without Firebase
        }
    }
}
