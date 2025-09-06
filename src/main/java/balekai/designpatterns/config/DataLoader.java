package balekai.designpatterns.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import balekai.designpatterns.model.User;
import balekai.designpatterns.repository.UserRepository;

@Configuration
@Profile("!test & !prod") // Don't load this configuration in test or production profiles
public class DataLoader {

    @Bean
    CommandLineRunner loadUsers(UserRepository userRepository) {
        return args -> {
            if (userRepository.count() == 0) {
                userRepository.save(User.builder().id("test-user-1").name("John").email("john@test.com").build());
                userRepository.save(User.builder().id("test-user-2").name("Paul").email("paul@test.com").build());
                userRepository.save(User.builder().id("test-user-3").name("George").email("george@test.com").build());
                userRepository.save(User.builder().id("test-user-4").name("Ringo").email("ringo@test.com").build());
            }
        };
    }
}
