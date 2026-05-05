FROM eclipse-temurin:17-jdk

WORKDIR /app

COPY app/target/*.jar app.jar

RUN useradd -m -u 1000 -s /sbin/nologin appuser && chown -R appuser:appuser /app

USER appuser

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD java -cp app.jar org.springframework.boot.loader.JarLauncher --version || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]