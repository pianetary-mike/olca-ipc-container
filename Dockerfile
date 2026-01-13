# collect Maven dependencies
FROM maven:3.9.12-eclipse-temurin-21 AS mvn
WORKDIR /olca-ipc
COPY pom.xml .
RUN mvn package

# native libraries from our own gdt-server-native image
FROM australia-southeast1-docker.pkg.dev/planetary-insights/pilca-service/gdt-server-native:latest AS native

# final image
FROM eclipse-temurin:21-jre
WORKDIR /app

COPY --from=mvn /olca-ipc/target/lib /app/lib
COPY --from=native /app/native /app/native
COPY run.sh /app
RUN chmod +x /app/run.sh

# Debug: show what native libs we have
RUN echo "=== Native library structure ===" && \
    find /app/native -type f -name "*.so*" | head -20 && \
    echo "=== All files ===" && \
    find /app/native -type f | wc -l

ENTRYPOINT ["/app/run.sh"]
