#!/bin/bash
cd /home/container

# Output Current Java Version
java -version
python --version
pip --version

eval $STARTUP
