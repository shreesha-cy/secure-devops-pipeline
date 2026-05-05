FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

RUN useradd -m -u 10001 -s /sbin/nologin appuser && chown -R appuser:appuser /app

USER appuser

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

CMD ["java", "-version"]
