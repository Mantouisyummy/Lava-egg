#!/bin/bash
cd /home/container

# Output Current Java Version
java -version
python --version
pip --version

# Replace Startup Variables
if [[ -f /home/container/${REQUIREMENTS_FILE} ]]; then
    pip install -U --prefix .local -r ${REQUIREMENTS_FILE}
fi

if [ "$START_LAVALINK" = "true" ]; then
    STARTUP="python /home/container/main.py & java -jar /home/container/server/Lavalink.jar"
else
    STARTUP="python /home/container/main.py"
fi

# Evaluate and execute the startup command
eval $STARTUP
