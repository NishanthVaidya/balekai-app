package balekai.designpatterns.config;

import jakarta.servlet.Filter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import balekai.designpatterns.security.FirebaseTokenFilter;

@Configuration
@Profile("!test") // Don't load this configuration in test profile
public class WebSecurityConfig {
    // Filter registration moved to FilterConfig to avoid conflicts
}
