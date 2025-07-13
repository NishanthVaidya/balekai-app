package kardo.designpatterns.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import kardo.designpatterns.security.FirebaseTokenFilter;

@Configuration
public class FilterConfig {

    @Bean
    public FirebaseTokenFilter firebaseTokenFilterInstance() {
        return new FirebaseTokenFilter();
    }

    @Bean
    public FilterRegistrationBean<FirebaseTokenFilter> firebaseTokenFilter(FirebaseTokenFilter filter) {
        FilterRegistrationBean<FirebaseTokenFilter> registrationBean = new FilterRegistrationBean<>();
        registrationBean.setFilter(filter);
        registrationBean.addUrlPatterns("/auth/*", "/boards/*", "/cards/*");
        registrationBean.setOrder(1);
        return registrationBean;
    }
}
