#! /usr/bin/bash

# Exit on any error
set -e

# === Install Docker if not installed ===
if ! command -v docker &> /dev/null; then
    echo "[+] Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y docker.io docker-compose
else
    echo "[✓] Docker is already installed."
fi

# === Start Docker if not running ===
if ! systemctl is-active --quiet docker; then
    echo "[+] Enabling and starting Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
else
    echo "[✓] Docker service is already running."
fi

# === Add user to docker group (optional, for non-root docker) ===
if groups $USER | grep -qw docker; then
    echo "[✓] User '$USER' is already in the docker group."
else
    echo "[+] Adding user '$USER' to the docker group..."
    sudo usermod -aG docker $USER
    echo "⚠️ Please log out and back in or run 'newgrp docker' to apply group changes."
fi

# ===  Install X11 Server Utils if not installed ===
if ! command -v xhost &> /dev/null; then
    echo "[+] Installing X11 server utilities..."
    sudo apt-get update
    sudo apt-get install -y x11-xserver-utils
else
    echo "[✓] X11 server utilities already installed."
fi

# Set the JENKINS_HOME environment variable. This will cause
# Jenkins will run from this directory.
# Create the JENKINS_HOME directory if it doesn't exist.
export JENKINS_HOME=~/webpage_ws/jenkins
mkdir -p $JENKINS_HOME

# Install java. We are using JRE 17.
sudo apt-get update -y || true
sudo apt-get install -y openjdk-17-jre

# Download the Jenkins .war file, if not there already
cd $JENKINS_HOME
JENKINS_FILE="$JENKINS_HOME/jenkins.war"
if [ ! -f "$JENKINS_FILE" ]; then
    wget https://updates.jenkins.io/download/war/2.511/jenkins.war
fi

# Jenkins is about to run, but we must check if 
# it's is already running
string=`ps ax | grep jenkins`
if [[ $string == *"jenkins.war"* ]]; then
    # Don't proceed further. Jenkings is already running
    echo "Jenkins is running already. Exiting."
    exit 0
else
    # Start Jenkins, since it's not running yet. 
    # Run Jenkins with a prefix. A prefix is needed because we are using a 
    # reverse proxy to run it on the Academy. This may not be necessary in your setup.
    # Store Jenkins proceess ID in JENKINS_PID
    java -jar jenkins.war --prefix="/$SLOT_PREFIX/jenkins/" &
    JENKINS_PID=$!
    sleep 15s

    # Calculate the Jenkins proxy address
    # This is NOT required for running Jenkins. It's just something we
    # need to do on the Academy. INSTANCE_ID and SLOT_PREFIX are Academy variables.
    INSTANCE_ID=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
    URL=`echo "https://$INSTANCE_ID.robotigniteacademy.com/$SLOT_PREFIX/jenkins/"`
    echo ""
    echo "1. Jenkins is running in the background."
    echo "2. Webpage: $URL"

    # Create a file that will store vital information
    # about the Jenkins instance
    # Save the running instance info to the file
    # This is just for your convenience
    STATE_FILE=$JENKINS_HOME/jenkins__pid__url.txt
    touch $STATE_FILE
    echo "To stop Jenkins, run:" > $STATE_FILE
    echo "kill $JENKINS_PID" >> $STATE_FILE
    echo "" >> $STATE_FILE
    echo "Jenkins URL: " >> $STATE_FILE
    echo $URL >> $STATE_FILE
    echo "3. See '$STATE_FILE' for Jenkins PID and URL."
fi

ssh-keyscan github.com >> ~/.ssh/known_hosts
