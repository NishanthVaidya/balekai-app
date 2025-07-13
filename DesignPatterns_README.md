
# 🧠 Design Patterns in the Trello Clone Backend

This project demonstrates thoughtful application of three key design patterns in the backend codebase, helping enforce clean architecture, maintainability, and flexibility in object management.

---

## 1. 🧭 Singleton Pattern (via Spring Beans)

### ✅ Where Used:
All classes annotated with `@Component`, `@Service`, `@Repository`, and `@Controller`.

### 💡 Why Used:
Spring Boot uses the Singleton Pattern by default for managing beans in its application context. That means:
- Each class is instantiated only once during the lifecycle of the application.
- The same instance is reused wherever it's injected.

### 🛠️ Benefits:
- **Performance**: Reduces memory footprint by reusing a single instance.
- **Consistency**: Ensures a consistent state across the app when accessing shared services (e.g., logging, repositories).
- **Simplicity**: Managed automatically by the Spring IoC container — no need to manually implement Singleton code.

---

## 2. 🏭 Factory Pattern

### ✅ Where Used:
- `designpatterns.factory.BoardFactory`
- `PrivateBoardFactory`
- `StandardBoardFactory`

### 💡 Why Used:
To abstract and encapsulate the logic of board creation based on type (private or standard).

### 🛠️ Benefits:
- **Encapsulation**: Keeps creation logic away from client code.
- **Flexibility**: Easily extendable to add new board types.
- **Separation of Concerns**: Controller or service layer just requests a board without worrying about the instantiation details.

---

## 3. 🧱 Builder Pattern (Lombok-based)

### ✅ Where Used:
- Model classes use `@Builder` annotation from **Lombok**.

### 💡 Why Used:
To simplify the construction of complex objects (like Board, Card, User, etc.) with optional or many fields, avoiding constructor overloading.

### 🛠️ Benefits:
- **Readable**: Instantiating objects becomes expressive and clean:
  ```java
  Board board = Board.builder()
                     .title("Sprint Tasks")
                     .isPrivate(true)
                     .build();
  ```
- **Immutable-Like Objects**: Combines with `@Value` or selective setters for safer state management.
- **Scalable**: Adding new optional fields doesn't break old code.

---

## 🚀 Summary Table

| Pattern    | Role in Project                                 | Benefit                                         |
|------------|--------------------------------------------------|-------------------------------------------------|
| Singleton  | Spring Beans (`@Service`, `@Controller`, etc.)   | Shared instance across app, memory efficient    |
| Factory    | Board creation logic                             | Abstracts instantiation logic, flexible         |
| Builder    | Lombok `@Builder` in models                      | Clean object creation with many fields          |

---

By using these patterns, the backend maintains **separation of concerns**, **testability**, and **future extensibility** — essential principles for building robust software systems.

