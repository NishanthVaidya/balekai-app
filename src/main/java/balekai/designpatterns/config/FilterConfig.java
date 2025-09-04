package balekai.designpatterns.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import balekai.designpatterns.security.FirebaseTokenFilter;

@Configuration
@Profile("!test") // Don't load this configuration in test profile
public class FilterConfig {

    @Bean
    public FirebaseTokenFilter firebaseTokenFilterInstance() {
        return new FirebaseTokenFilter();
    }

    @Bean
    public FilterRegistrationBean<FirebaseTokenFilter> firebaseTokenFilter(FirebaseTokenFilter filter) {
        FilterRegistrationBean<FirebaseTokenFilter> registrationBean = new FilterRegistrationBean<>();
        registrationBean.setFilter(filter);
        registrationBean.addUrlPatterns("/auth", "/auth/*", "/boards", "/boards/*", "/lists", "/lists/*", "/cards", "/cards/*");
        registrationBean.setOrder(1);
        return registrationBean;
    }
}
