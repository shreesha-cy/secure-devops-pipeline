# Secure DevOps Pipeline - Enhanced security
FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

COPY build/libs/*.jar app.jar

RUN useradd -m -u 1000 -s /sbin/nologin appuser && chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
