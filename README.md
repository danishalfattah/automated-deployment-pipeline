# CI/CD Pipeline with Jenkins, SonarQube, and Docker

An end-to-end CI/CD pipeline implementation to automate the workflow from code commit to deployment. It integrates Jenkins, SonarQube, Docker, and GitHub Webhooks on a cloud infrastructure.

## Table of Contents

1.  [Architecture](#architecture)
2.  [Prerequisites](#prerequisites)
3.  [Step 1: Infrastructure Setup on AWS EC2](#step-1-infrastructure-setup-on-aws-ec2)
4.  [Step 2: Jenkins Server Setup](#step-2-jenkins-server-setup)
5.  [Step 3: SonarQube Server Setup](#step-3-sonarqube-server-setup)
6.  [Step 4: Docker Host (Deployment Server) Setup](#step-4-docker-host-deployment-server-setup)
7.  [Step 5: System Configuration](#step-5-system-configuration)
8.  [Step 6: Creating the Project Files](#step-6-creating-the-project-files)
9.  [Step 7: Creating the Jenkins Pipeline](#step-7-creating-the-jenkins-pipeline)
10. [Step 8: Testing the Pipeline](#step-8-testing-the-pipeline)

## Architecture

The project follows a straightforward CI/CD workflow:

`Code Push` -> `GitHub Webhook` -> `Jenkins Pipeline Trigger` -> `SonarQube Analysis` -> `File Transfer to Docker Host` -> `Docker Build & Deploy`

![Architecture Diagram](https://user-images.githubusercontent.com/8951939/188879532-62342502-3165-455a-94b2-603350257cbc.png)
*(Feel free to replace this with your own diagram)*

## Prerequisites

-   An **AWS Account** with permissions to create EC2 instances.
-   A **GitHub Account** and a new repository for your project.
-   Basic knowledge of Linux commands and shell scripting.
-   Familiarity with Docker and Jenkins concepts.

---

## Step 1: Infrastructure Setup on AWS EC2

We need three separate servers for this setup.

1.  **Launch EC2 Instances:**
    -   **Jenkins Server:**
        -   AMI: `Ubuntu Server`
        -   Instance Type: `t2.medium or higher`.
    -   **SonarQube Server:**
        -   AMI: `Ubuntu Server`
        -   Instance Type: `t2.medium or higher`.
    -   **Docker Host (Deployment Server):**
        -   AMI: `Ubuntu Server`
        -   Instance Type: `t2.medium or higher`.

2.  **Assign Elastic IPs (EIP):**
    -   After launching, assign an Elastic IP to each of the three instances. This ensures that their public IP addresses are static and will not change after a reboot.

3.  **Configure Security Groups:**
    -   **For Jenkins Instance:**
        -   `SSH` (Port `22`) from your IP.
        -   `HTTP` (Port `8080`) from anywhere (`0.0.0.0/0`).
    -   **For SonarQube Instance:**
        -   `SSH` (Port `22`) from your IP.
        -   `HTTP` (Port `9000`) from anywhere (`0.0.0.0/0`).
    -   **For Docker Host Instance:**
        -   `SSH` (Port `22`) from your IP and from the Jenkins instance's IP.
        -   `Custom TCP` (Port `8085`) from anywhere (`0.0.0.0/0`) to access the deployed application.

## Step 2: Jenkins Server Setup

1.  SSH into your Jenkins instance.

2.  **Install Java and Jenkins:**
    ```bash
    sudo apt update
    sudo apt install -y openjdk-11-jre
    curl -fsSL [https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key](https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key) | sudo tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      [https://pkg.jenkins.io/debian-stable](https://pkg.jenkins.io/debian-stable) binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y jenkins
    ```

3.  **Initial Jenkins Setup:**
    -   Access the Jenkins GUI dashboard via its public IP at `http://<YOUR_JENKINS_PUBLIC_IP>:8080`.
    -   Get the initial admin password:
        ```bash
        sudo cat /var/lib/jenkins/secrets/initialAdminPassword
        ```
    -   Paste the password, click **Install suggested plugins**, and create an admin user.

4.  **Install Additional Plugins:**
    -   Go to **Manage Jenkins > Plugins > Available plugins**.
    -   Install `SonarQube Scanner` and **`Publish Over SSH`**.

## Step 3: SonarQube Server Setup

1.  SSH into your SonarQube instance.

2.  **Install Java and Unzip Utility:**
    ```bash
    sudo apt update
    sudo apt install -y openjdk-11-jre unzip
    ```

3.  **Download and Set Up SonarQube:**
    ```bash
    wget [https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.0.65446.zip](https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.0.65446.zip)
    unzip sonarqube-9.9.0.65446.zip
    cd sonarqube-9.9.0.65446/bin/linux-x86-64/
    ./sonar.sh console
    ```

4.  **Access SonarQube GUI:**
    -   Access the SonarQube GUI dashboard via its public IP at `http://<YOUR_SONARQUBE_PUBLIC_IP>:9000`.
    -   Log in with default credentials: `admin` / `admin`.

## Step 4: Docker Host (Deployment Server) Setup

1.  SSH into your Docker Host instance.

2.  **Install Docker:**
    ```bash
    sudo apt update
    sudo apt install -y docker.io
    sudo usermod -aG docker ${USER}
    newgrp docker
    ```

## Step 5: System Configuration

### A. Connect Jenkins to SonarQube
1.  **In SonarQube:** Go to **Administration > Security > Users**, and generate a new token for the `admin` user.
2.  **In Jenkins:** Go to **Manage Jenkins > Credentials**, add a new `Secret text` credential with the SonarQube token. Then, go to **Manage Jenkins > Configure System**, add a SonarQube server, and link the credential.

### B. Configure Publish Over SSH Plugin
1.  **In Jenkins:** Go to **Manage Jenkins > Configure System**.
2.  Scroll down to **Publish over SSH**.
3.  Add a new SSH server:
    -   **Name**: `Docker-Host`
    -   **Hostname**: `<YOUR_DOCKER_HOST_IP>`
    -   **Username**: `ubuntu`
    -   Click **Advanced...** and provide your authentication method (e.g., password or private key).
4.  Click **Test Configuration** to verify the connection.

### C. Configure GitHub Webhook
1.  **In GitHub:** Go to your repository's **Settings > Webhooks**.
2.  Add a new webhook with the Payload URL `http://<YOUR_JENKINS_IP>:8080/github-webhook/`.

## Step 6: Creating the Project Files

In your GitHub repository, create the following files.

1.  **`index.html`**
    ```html
    <!DOCTYPE html>
    <html lang="en">
    <body>
        <h1>CI/CD Pipeline Successful!</h1>
        <p>This page was automatically deployed by a Jenkins pipeline using Publish Over SSH.</p>
    </body>
    </html>
    ```

2.  **`Dockerfile`**
    ```dockerfile
    FROM nginx:alpine
    COPY . /usr/share/nginx/html
    EXPOSE 80
    ```

3.  **`Jenkinsfile`**
    ```groovy
    pipeline {
        agent any

        environment {
            DOCKER_IMAGE_NAME = "my-web-app"
            DOCKER_HOST_CONFIG = "Docker-Host"
        }

        stages {
            stage('Checkout from Git') {
                steps {
                    git '[https://github.com/](https://github.com/)<YOUR_USERNAME>/<YOUR_REPO_NAME>.git'
                }
            }

            stage('Code Analysis') {
                steps {
                    script {
                        echo "Skipping SonarQube analysis for this example."
                    }
                }
            }

            stage('Build & Deploy') {
                steps {
                    echo "Starting deployment using Publish Over SSH plugin..."
                    sshPublisher(
                        publishers: [
                            sshPublisherDesc(
                                configName: DOCKER_HOST_CONFIG,
                                transfers: [
                                    sshTransfer(
                                        sourceFiles: '**',
                                        remoteDirectory: '/home/ubuntu/app',
                                        execCommand: '''
                                            cd /home/ubuntu/app
                                            docker build -t ${DOCKER_IMAGE_NAME} .
                                            docker stop ${DOCKER_IMAGE_NAME} || true
                                            docker rm ${DOCKER_IMAGE_NAME} || true
                                            docker run -d --name ${DOCKER_IMAGE_NAME} -p 8085:80 ${DOCKER_IMAGE_NAME}
                                        '''
                                    )
                                ]
                            )
                        ]
                    )
                }
            }
        }
        post {
            always {
                echo 'Pipeline finished.'
            }
        }
    }
    ```
    **Note:** Replace `<YOUR_USERNAME>/<YOUR_REPO_NAME>.git` with your repository URL.

## Step 7: Creating the Jenkins Pipeline

1.  Go to your Jenkins dashboard, click **New Item**, enter a name, select **Pipeline**, and click **OK**.
2.  In the configuration page, scroll down to the **Pipeline** section.
    -   Definition: **Pipeline script from SCM**.
    -   SCM: **Git**.
    -   Repository URL: `https://github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>.git`.
    -   Branch: `*/main` or `*/master`.
    -   Script Path: `Jenkinsfile`.
3.  Click **Save**.

## Step 8: Testing the Pipeline

1.  Commit and push all files to your GitHub repository.
    ```bash
    git add .
    git commit -m "Final project setup with port 8085"
    git push origin main
    ```
2.  The `push` will trigger the Jenkins pipeline.
3.  Monitor the pipeline's progress in the Jenkins dashboard.
4.  Once completed, navigate to `http://<YOUR_DOCKER_HOST_IP>:8085`. You should see your web page live.
