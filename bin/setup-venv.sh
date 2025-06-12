#!/bin/bash

# Script to set up a Python virtual environment and install psycopg2

# Define the virtual environment directory name
# This script assumes it is run from the project root (pc-dae-voters/)
# and the bin directory is pc-dae-voters/bin/
VENV_DIR=".venv"

# Check if Python3 is available
if ! command -v python3 &> /dev/null
then
    echo "python3 could not be found, please install it."
    exit 1
fi

# Create the virtual environment
echo "Creating virtual environment in $VENV_DIR..."
python3 -m venv $VENV_DIR

if [ $? -ne 0 ]; then
    echo "Failed to create virtual environment."
    exit 1
fi

echo "Virtual environment '$VENV_DIR' created successfully."

# Activate the virtual environment
source $VENV_DIR/bin/activate

# Install psycopg2-binary
echo "Installing psycopg2-binary..."
pip install psycopg2-binary

if [ $? -ne 0 ]; then
    echo "Failed to install psycopg2-binary."
    # Deactivate and clean up if install fails
    deactivate
    # rm -rf $VENV_DIR # Optionally remove the venv directory on failure
    exit 1
fi

echo "psycopg2-binary installed successfully."

# Deactivate the virtual environment (optional, as the user will be prompted to activate)
deactivate

echo "Setup complete."
echo "To activate the virtual environment for manual use, run from the project root:"
echo "source $VENV_DIR/bin/activate" 