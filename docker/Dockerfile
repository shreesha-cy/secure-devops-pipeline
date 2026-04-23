FROM eclipse-temurin:17-jdk

WORKDIR /app

COPY app/target/*.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]