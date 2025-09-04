package balekai.designpatterns.controller;

import balekai.designpatterns.model.User;
import balekai.designpatterns.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequiredArgsConstructor
@Profile("!test") // Don't load this controller in test profile
public class UserController {

    private final UserRepository userRepository;

    @GetMapping("/")
    public String root() {
        return "Kardo API is running!";
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }

    @GetMapping("/users")
    public ResponseEntity<List<User>> getUsers() {
        List<User> users = userRepository.findAll();
        return ResponseEntity.ok(users);
    }
}

