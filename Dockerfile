FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

RUN useradd -m -u 1000 -s /sbin/nologin appuser && chown -R appuser:appuser /app

USER appuser

CMD ["java", "-version"]
