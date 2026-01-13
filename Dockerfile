# collect Maven dependencies
FROM --platform=$BUILDPLATFORM maven:3.9.12-eclipse-temurin-21 AS mvn
WORKDIR /olca-ipc
COPY pom.xml .
RUN mvn package

# Native libraries stage - download UMFPACK (newer, better compatibility)
FROM --platform=linux/amd64 eclipse-temurin:21-jre AS native-downloader
WORKDIR /tmp

# Download UMFPACK native libraries (not BLAS - UMFPACK has better compatibility)
RUN apt-get update && apt-get install -y curl unzip && \
    mkdir -p /app/native/olca-native/0.0.1/x64 && \
    echo "Downloading UMFPACK native libraries..." && \
    curl -fSL -o native.zip "https://github.com/GreenDelta/olca-native/releases/download/v0.0.1/olca-native-umfpack-linux-x64.zip" && \
    unzip native.zip -d /app/native/olca-native/0.0.1/x64/ && \
    rm native.zip && \
    echo "Native library contents:" && find /app/native -name "*.so" -exec ls -la {} \;

# Final image - FORCE AMD64
FROM --platform=linux/amd64 eclipse-temurin:21-jre
WORKDIR /app

COPY --from=mvn /olca-ipc/target/lib /app/lib
COPY --from=native-downloader /app/native /app/native
COPY run.sh /app
RUN chmod +x /app/run.sh

# Verify native libraries
RUN echo "=== Native lib structure ===" && find /app/native -type f && \
    echo "=== Checking library dependencies ===" && \
    find /app/native -name "*.so" -exec sh -c 'echo "--- {} ---"; ldd "{}" 2>/dev/null || true' \;

ENTRYPOINT ["/app/run.sh"]
