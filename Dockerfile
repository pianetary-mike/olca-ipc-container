# collect Maven dependencies
FROM --platform=$BUILDPLATFORM maven:3.9.12-eclipse-temurin-21 AS mvn
WORKDIR /olca-ipc
COPY pom.xml .
RUN mvn package

# Use GreenDelta's official native libraries (compatible with olca-ipc 2.x)
FROM ghcr.io/greendelta/gdt-server-native AS native-libs

# Final image - FORCE AMD64
FROM --platform=linux/amd64 eclipse-temurin:21-jre
WORKDIR /app

# Install libgfortran4 which is required by OpenBLAS (compiled with GCC 7)
# Ubuntu 22.04 (jammy) doesn't have libgfortran4, need to get from Ubuntu 20.04 (focal)
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    echo "deb http://archive.ubuntu.com/ubuntu focal main universe" > /etc/apt/sources.list.d/focal.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends libgfortran4 && \
    rm /etc/apt/sources.list.d/focal.list && \
    apt-get update && \
    rm -rf /var/lib/apt/lists/* && \
    echo "Installed libgfortran4:" && ldconfig -p | grep gfortran

COPY --from=mvn /olca-ipc/target/lib /app/lib
COPY --from=native-libs /app/native /app/native
COPY run.sh /app
RUN chmod +x /app/run.sh

# Verify native libraries
RUN echo "=== Native lib contents ===" && ls -la /app/native/ && \
    echo "=== Checking library dependencies ===" && \
    for f in /app/native/*.so; do echo "--- $f ---"; ldd "$f" 2>/dev/null || true; done

ENTRYPOINT ["/app/run.sh"]
