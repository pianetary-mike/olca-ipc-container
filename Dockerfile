# collect Maven dependencies
FROM --platform=$BUILDPLATFORM maven:3.9.12-eclipse-temurin-21 AS mvn
WORKDIR /olca-ipc
COPY pom.xml .
RUN mvn package

# Native libraries stage - FORCE AMD64 since no ARM64 libs exist
FROM --platform=linux/amd64 eclipse-temurin:21-jre AS native-downloader
WORKDIR /tmp

# Download x64 native libraries (only platform available)
RUN apt-get update && apt-get install -y curl unzip && \
    mkdir -p /app/native && \
    echo "Downloading x64 native libraries..." && \
    curl -fSL -o native.zip "https://github.com/GreenDelta/olca-native/releases/download/v0.0.1/olca-native-blas-linux-x64.zip" && \
    unzip native.zip -d /tmp/extracted && \
    find /tmp/extracted -name "*.so" -exec cp {} /app/native/ \; && \
    rm -rf native.zip /tmp/extracted && \
    echo "Native library contents:" && ls -la /app/native/

# Final image - FORCE AMD64
FROM --platform=linux/amd64 eclipse-temurin:21-jre
WORKDIR /app

COPY --from=mvn /olca-ipc/target/lib /app/lib
COPY --from=native-downloader /app/native /app/native
COPY run.sh /app
RUN chmod +x /app/run.sh

RUN echo "Final native lib check:" && ls -la /app/native/

ENTRYPOINT ["/app/run.sh"]