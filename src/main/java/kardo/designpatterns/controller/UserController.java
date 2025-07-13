package kardo.designpatterns.controller;

import org.springframework.web.bind.annotation.*;

@RestController
public class UserController {

    @GetMapping("/")
    public String root() {
        return "Kardo API is running!";
    }

    @GetMapping("/health")
    public String health() {
        return "OK";
    }

    @GetMapping("/users")
    public String getUsers() {
        return "Users endpoint";
    }
}

