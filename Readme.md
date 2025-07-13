
# Trello Clone - Java Spring Boot + NextJs + Tailwind CSS + Google Authentication via Firebase and Firestore DB

This is a full-stack Trello-style task management application built using:
- **Spring Boot (Java)** for the backend
- **React.js** for the frontend
- **JWT-based Authentication** with support for manual registration/login and Google Sign-In

---

## 🌟 Features

### 🧑‍💼 Authentication
- JWT-based login & registration
- Google Sign-In using Firebase
- Profile creation and editing

### 📋 Board Management
- Create new boards (public/private)
- Inline editing of board names
- Drag and drop boards
- Delete boards

### 🗂️ List Management
- Create lists under boards
- Edit list names inline
- Drag and move lists
- Delete lists

### 🃏 Card Management
- Create cards in the "To Do" list only
- Move cards between 5 default states: To Do, In Progress, Blocked, Review, Done
- Assign and reassign cards to users
- Inline editing for title and label
- Search and filter by assigned user, state, or title
- Drawer for viewing/editing card details
- Full activity logs with state transitions and assignments

### 🔐 Backend Design Patterns
- **Factory Pattern**:
    - `BoardFactory`, `PrivateBoardFactory`, `StandardBoardFactory` are used for board creation based on type

---

## ⚙️ Technologies Used

### Backend
- Java 17, Spring Boot
- Spring Security
- JWT for authentication
- RESTful APIs
- Maven

### Frontend
- Next.js
- Tailwind CSS
- Firebase SDK for Google Auth

### Database
- PostgreSQL (via JPA/Hibernate)

---

## 🚀 Running the App

### Prerequisites
- Java 17
- Node.js & npm
- PostgreSQL
- Firebase Project (for Google Auth)

### Backend
```bash
cd Trelllo
./mvnw spring-boot:run
```

### Frontend
```bash
cd trello-clone
npm install
npm start
```

---

## 🏗️ Project Structure

```
Trelllo/
├── src/
│   └── main/
│       └── java/trelllo/
│           ├── controller/
│           ├── service/
│           ├── repository/
│           ├── model/
│           ├── request/
│           ├── response/
│           ├── config/
│           ├── security/
│           ├── exception/
│           └── designpatterns/
│               └── factory/
```

---

## 📚 To-Do / Enhancements

- [ ] Unit tests
- [ ] Pagination and infinite scroll for cards
- [ ] Real-time collaboration (WebSockets)
- [ ] Role-based access for shared boards

---

## 👤 Author

**Nishanth Vaidya**  
[Syracuse University Graduate Student]  
[LinkedIn](https://www.linkedin.com/in/nv2) | [GitHub](https://github.com/NishanthVaidya)

---

## 📜 License

This project is for educational use. All rights reserved.
# kardo
# kardo
