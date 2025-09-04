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
            // Load Firebase service account from classpath resources
            ClassPathResource resource = new ClassPathResource("firebase-service-account.json");
            log.info("📁 Firebase config file found: {}", resource.exists());
            log.info("📁 Firebase config file path: {}", resource.getPath());
            
            if (!resource.exists()) {
                log.error("❌ Firebase service account file not found!");
                return;
            }
            
            try (InputStream serviceAccount = resource.getInputStream()) {
                log.info("📖 Reading Firebase service account...");
                
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                log.info("🔧 Firebase options built successfully");
                log.info("🔧 Project ID: {}", options.getProjectId());

                if (FirebaseApp.getApps().isEmpty()) {
                    FirebaseApp app = FirebaseApp.initializeApp(options);
                    log.info("✅ Firebase initialized successfully: {}", app.getName());
                } else {
                    log.info("ℹ️ Firebase already initialized");
                }
            }
        } catch (Exception e) {
            log.error("❌ Error initializing Firebase: {}", e.getMessage(), e);
            throw e;
        }
    }
}
