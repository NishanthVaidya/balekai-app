package balekai.designpatterns.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
@Profile("!test") // Don't load this configuration in test profile
public class WebSecurityConfig {
    // Firebase authentication is now handled in the controllers via FirebaseAuthService
}
