# Use OpenJDK 17 as base image for AWS compatibility
FROM --platform=linux/amd64 openjdk:17-jdk-slim

# Set working directory
WORKDIR /app

# Copy the JAR file
COPY target/balekai-1.0-SNAPSHOT.jar app.jar

# Copy Firebase configuration from target/classes (Maven build output) if it exists
# COPY target/classes/firebase-service-account.json firebase-service-account.json

# Expose port 8080
EXPOSE 8080

# Set JVM options for production
ENV JAVA_OPTS="-Xmx512m -Xms256m"

# Run the application with test profile (no database required)
CMD ["java", "-Xmx512m", "-Xms256m", "-jar", "app.jar", "--spring.profiles.active=prod"]
