#!/bin/bash
cd /home/container

# Output Current Java Version
java -version
python --version

# Replace Startup Variables
MODIFIED_STARTUP=$(eval echo "${STARTUP}")
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Check if requirements file exists and install if it does
if [[ -f "/home/container/${REQUIREMENTS_FILE}" ]]; then
    pip install -U --prefix .local -r "${REQUIREMENTS_FILE}"
fi

# Run the Server
if [ "$START_LAVALINK" = "true" ]; then
    /usr/local/bin/python /home/container/main.py &
    java -jar /home/container/server/Lavalink.jar
else
    /usr/local/bin/python /home/container/main.py
fi
