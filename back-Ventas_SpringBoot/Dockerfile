# Stage 1: Build the Maven application
FROM maven:3.9.6-eclipse-temurin-17-alpine AS build
WORKDIR /app
COPY Springboot-API-REST/pom.xml .
COPY Springboot-API-REST/src ./src
RUN mvn clean package -DskipTests

# Stage 2: Run the application
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
# Run as non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
