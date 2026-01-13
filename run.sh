#!/bin/bash

# Use JAVA_MAX_RAM_PERCENTAGE if set, otherwise default to 70%
# This allows docker-compose to control memory via mem_limit
MAX_RAM_PERCENTAGE=${JAVA_MAX_RAM_PERCENTAGE:-70}

# Use OLCA_TIMEOUT if set, otherwise default to 600 seconds (10 min for large matrices)
TIMEOUT=${OLCA_TIMEOUT:-600}

# Find native library directory (olca-native expects specific structure)
NATIVE_LIB_DIR="/app/native/olca-native/0.0.1/x64"

# Check if native libraries exist
if [ -d "$NATIVE_LIB_DIR" ] && [ "$(ls -A $NATIVE_LIB_DIR/*.so 2>/dev/null)" ]; then
    echo "Native libraries found in $NATIVE_LIB_DIR:"
    ls -la $NATIVE_LIB_DIR/*.so 2>/dev/null | head -5
    echo "  ... ($(ls $NATIVE_LIB_DIR/*.so 2>/dev/null | wc -l) total .so files)"
    NATIVE_FLAG="-native /app/native"
    # Set LD_LIBRARY_PATH so native libs can find each other
    export LD_LIBRARY_PATH="$NATIVE_LIB_DIR:$LD_LIBRARY_PATH"
    JAVA_LIB_PATH="$NATIVE_LIB_DIR"
else
    echo "WARNING: No native libraries found in $NATIVE_LIB_DIR - calculations may fail!"
    NATIVE_FLAG=""
    JAVA_LIB_PATH="/app/native"
fi

echo "Starting OpenLCA IPC Server..."
echo "  Max RAM Percentage: ${MAX_RAM_PERCENTAGE}%"
echo "  Calculation Timeout: ${TIMEOUT}s"
echo "  Native libraries: ${NATIVE_FLAG:-none}"
echo "  LD_LIBRARY_PATH: ${LD_LIBRARY_PATH:-not set}"
echo "  Arguments: $@"

exec java \
    -XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=${MAX_RAM_PERCENTAGE} \
    -XX:+ExitOnOutOfMemoryError \
    -Djava.library.path=$JAVA_LIB_PATH \
    -cp "/app/lib/*" \
    org.openlca.ipc.Server \
    -timeout ${TIMEOUT} \
    ${NATIVE_FLAG} \
    -data /app/data \
    "$@"
