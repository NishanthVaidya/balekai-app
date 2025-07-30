package trelllo.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import trelllo.model.User;
import trelllo.repository.UserRepository;

@Configuration
public class DataLoader {

    @Bean
    CommandLineRunner loadUsers(UserRepository userRepository) {
        return args -> {
            if (userRepository.count() == 0) {
                userRepository.save(User.builder().id("user1").name("John").email("john@example.com").build());
                userRepository.save(User.builder().id("user2").name("Paul").email("paul@example.com").build());
                userRepository.save(User.builder().id("user3").name("George").email("george@example.com").build());
                userRepository.save(User.builder().id("user4").name("Ringo").email("ringo@example.com").build());
            }
        };
    }
}
