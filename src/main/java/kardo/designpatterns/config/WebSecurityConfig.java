package kardo.designpatterns.config;

import jakarta.servlet.Filter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import kardo.designpatterns.security.FirebaseTokenFilter;

@Configuration
public class WebSecurityConfig {

    @Bean
    public FilterRegistrationBean<Filter> firebaseFilterRegistration(FirebaseTokenFilter firebaseTokenFilter) {
        FilterRegistrationBean<Filter> registration = new FilterRegistrationBean<>();
        registration.setFilter(firebaseTokenFilter);
        registration.addUrlPatterns("/boards/*", "/lists/*", "/cards/*"); // Secure these
        registration.setOrder(1);
        return registration;
    }
}
