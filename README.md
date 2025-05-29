# Continuous Integration Project for ROS2 Galactic
The goal of this project is to automate a CI (continuous integration) process to be triggered whenever a commit is pushed to a remote repository.
A continuous integration pipeline is created and deployed using Jenkins.

## Section A: Installations in Local Machine
This project requires following programs:
- java
- Jenkins
- Docker

### 1. Clone this repo

```bash
mkdir -p ~/ros2_ws/src
git clone git@github.com:kailash197/cp24_ros2_ci.git
mv cp24_ros2_ci ros2_ci
```

### 2. Install Docker, Xhost, Java, and Jenkins
The following script automatically checks and installs the packages if not already installed.  

[Terminal 1]
```bash
cd ~/ros2_ws/src/ros2_ci
./start_jenkins.sh
```

## Section B: Test Instructions
The jenkins pipeline will automatically configure, build and test the ROS2 Galactic project in a docker container.  
The stages are:
- Configure and start a docker container
- Start roscore and gazebo simulation in the docker container
- Start waypoint action server in the docker container
- Run the passing tests
- Run the failing tests

The pipeline is triggered by a `push` event to this repository.

### 1. Make change to a file by adding current date and time

[Terminal 2]
```bash
cd ~/ros2_ws/src/ros2_ci
echo "Current date and time: $(date +"%Y%m%d at %H:%M:%S")" >> changeme.txt
```

### 2. Make a new commit

[Terminal 2]
``` bash
cd ~/ros2_ws/src/ros2_ci
git add changeme.txt
git commit -m "Commit: $(date +"%Y%m%d at %H:%M:%S")"
```

### 3. Create a pull request
Please create a pull request and wait for it to be accepted.

### 4. Monitor Jenkins webpage 

- Find the Jenkins webpage

    [Terminal 2]
    ```bash
    cat ~/webpage_ws/jenkins/jenkins__pid__url.txt
    ```

    Expected Output:
    ```bash
    To stop Jenkins, run:
    kill 18754

    Jenkins URL:
    https://i-02160f8104f117f8b.robotigniteacademy.com/8bab3219-1fe5-4a28-8469-70b3d139923b/jenkins/
    ```
- Open the Jenkins webpage

- Monitor build process for `ROS2 Auto Test Pipeline` pipeline. Its output can be seen on the `Console Output`.


## Section C: Setup Instructions
Please follow the following instructions to setup this system in your local environment.

### 1. **Setup `SSH` & `git` in local environment**

#### 1.1 Setup SSH, git, private and public keys
- Run the following command to setup SSH and git  
    [Terminal 1]
    ```bash
    cd ~/ros2_ws/src/ros2_ci
    bash setup_ssh_git.sh
    ```

- Ensures that git and SSH are automatically setup when you come back to the course after a break  
    [Terminal 1]
    ```bash
    echo "bash ~/ros2_ws/src/ros2_ci/setup_ssh_git.sh" >> ~/.bashrc
    ```

- View private and public key  
    [Terminal 1]
    ```bash
    cat ~/.ssh/id_rsa_ros2.pub && echo '' && cat ~/.ssh/id_rsa_ros2
    ```

#### 1.2 Add GitHub’s SSH Key to known_hosts
The SSH client stores GitHub’s ECDSA key fingerprint in `~/.ssh/known_hosts`.
This ensures future connections to github.com are trusted automatically.

[Terminal 1]
```bash
ssh-keyscan github.com >> ~/.ssh/known_hosts
```

### 2. **Setup Github repository**

#### 2.1 Create a repository
Create a new github repository which you want your pipeline to build and test automatically on every successfull push.

#### 2.2 Add deploy keys
Add deploy keys to Github repository. Deploy keys use an SSH key to grant readonly or write access to a single repository.   
Go to Github Repo > Settings > Security > Deploy keys  
- Add new
- Title: Provide suitable title
- Key: Add public key here
- Allow write acess also
- Add key

####  2.3 Setup a webhook
Now, setup a webhook URL on the GitHub repository.  
1. Find the webhook URL
    [Terminal 1]
    ```bash
    echo "$(jenkins_address)github-webhook/"
    ```

    Sample output:
    ```bash
    https://i-02160f8104f117f8b.robotigniteacademy.com/8bab3219-1fe5-4a28-8469-70b3d139923b/jenkins/github-webhook/
    ```

2. Use the webhook URL to setup Github  
    Goto Github repo > Settings > webhooks
    - Payload URL: <Copy & paste from previous step>
    - Content type: application/json
    - SSL verification: Enable SSL verification
    - Trigger events: Just the push event
    - Select Active
    - Add webhook

### 3. **Setup jenkins**

#### 3.1 Start the jenkins server
Run the following command and start the jenkins server.  

Note: The script automatically checks and installs the packages if not already installed.  

[Terminal 1]
```bash
cd ~/ros2_ws/src/ros2_ci
./start_jenkins.sh
cat ~/webpage_ws/jenkins/jenkins__pid__url.txt
```

#### 3.2 Open Jenkins webpage
Open the jenkins webpage using URL output from previous step.

#### 3.3 Install plugins in Jenkins
1. Go to Jenkins > Manage Jenkins > Plugins.
2. Install following plugins:
    - Git
    - Github
    - Pipeline

#### 3.4 Add credentials to access Github repository
Follow the instructions below to add a new credential to access Github repo.  
Go to Jenkins > Manage Jenkins > Credentials > global > Add credentials  
* Kind: SSH Username with private key
* Username: user
* Private Key: 
    - Select `Enter Directly`
    - Select `Add key`
    - Paste private key
* Create

#### 3.5 Create a new pipeline
1. Create new pipeline project in jenkins  
    Go to Jenkins > New item  
    - Name of item: `ROS2 Auto Test Pipeline`
    - Select item type: Select `Pipeline`  
    - OK

2. Configure the pipeline  
    Go to Jenkins > select your pipeline > Configure  
    - Triggers: `Github hook trigger for GITScm polling`  
    - Pipeline:   
        - Definition: `Pipeline script from SCM`
        - SCM: `Git`
        - Repository URL: `<link to github repo>`
        - Credentials: user
        - Script Path: Jenkinsfile
    - Save  
