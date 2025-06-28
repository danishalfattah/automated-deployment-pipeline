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

`Code Push` -> `GitHub Webhook` -> `Jenkins Pipeline Trigger` -> `SonarQube Analysis` -> `Docker Build & Deploy`

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
        -   Instance Type: `t2.small` or higher.
    -   **SonarQube Server:**
        -   AMI: `Ubuntu Server`
        -   Instance Type: `t2.medium` or higher (SonarQube requires at least 2GB of RAM).
    -   **Docker Host (Deployment Server):**
        -   AMI: `Ubuntu Server`
        -   Instance Type: `t2.micro` or higher.

2.  **Configure Security Groups:**
    -   **For Jenkins Instance:**
        -   `SSH` (Port `22`) from your IP.
        -   `HTTP` (Port `8080`) from anywhere (`0.0.0.0/0`) to access the Jenkins dashboard.
    -   **For SonarQube Instance:**
        -   `SSH` (Port `22`) from your IP.
        -   `HTTP` (Port `9000`) from anywhere (`0.0.0.0/0`) to access the SonarQube dashboard.
    -   **For Docker Host Instance:**
        -   `SSH` (Port `22`) from your IP.
        -   `HTTP` (Port `80`) from anywhere (`0.0.0.0/0`) to access the deployed application.

## Step 2: Jenkins Server Setup

1.  SSH into your Jenkins instance.

2.  **Install Java (Required for Jenkins):**
    ```bash
    sudo apt update
    sudo apt install -y openjdk-11-jre
    ```

3.  **Install Jenkins:**
    ```bash
    curl -fsSL [https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key](https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key) | sudo tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      [https://pkg.jenkins.io/debian-stable](https://pkg.jenkins.io/debian-stable) binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y jenkins
    ```

4.  **Initial Jenkins Setup:**
    -   Access Jenkins at `http://<YOUR_JENKINS_IP>:8080`.
    -   Get the initial admin password:
        ```bash
        sudo cat /var/lib/jenkins/secrets/initialAdminPassword
        ```
    -   Paste the password, click **Install suggested plugins**, and create an admin user.

5.  **Install Additional Plugins:**
    -   Go to **Manage Jenkins > Plugins > Available plugins**.
    -   Install `SonarQube Scanner` and `Docker Pipeline`.

## Step 3: SonarQube Server Setup

1.  SSH into your SonarQube instance.

2.  **Increase Virtual Memory for Elasticsearch:**
    ```bash
    sudo sysctl -w vm.max_map_count=262144
    ```

3.  **Install SonarQube using Docker (Recommended):**
    ```bash
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo docker run -d --name sonarqube -p 9000:9000 -p 9092:9092 sonarqube:lts-community
    ```

4.  Access SonarQube at `http://<YOUR_SONARQUBE_IP>:9000`. Log in with default credentials: `admin` / `admin`. You will be prompted to change the password.

## Step 4: Docker Host (Deployment Server) Setup

1.  SSH into your Docker Host instance.

2.  **Install Docker:**
    ```bash
    sudo apt update
    sudo apt install -y docker.io
    ```

3.  **Add your user to the `docker` group** to run Docker commands without `sudo`.
    ```bash
    sudo usermod -aG docker ${USER}
    # You will need to log out and log back in for this to take effect.
    newgrp docker
    ```

## Step 5: System Configuration

### A. Connect Jenkins to SonarQube

1.  **In SonarQube:**
    -   Go to **Administration > Security > Users**.
    -   Click the token icon for the `admin` user to generate a new token. Name it `jenkins-token` and copy it.

2.  **In Jenkins:**
    -   Go to **Manage Jenkins > Credentials > System > Global credentials**.
    -   Click **Add Credentials**.
        -   Kind: `Secret text`.
        -   Secret: Paste the SonarQube token you generated.
        -   ID: `sonarqube-token`.
    -   Go to **Manage Jenkins > Configure System**.
    -   Scroll down to **SonarQube servers**.
        -   Click **Add SonarQube**.
        -   Name: `SonarQubeServer`.
        -   Server URL: `http://<YOUR_SONARQUBE_IP>:9000`.
        -   Server authentication token: Select the `sonarqube-token` credential.

### B. Configure SonarQube Scanner Tool

1.  **In Jenkins:**
    -   Go to **Manage Jenkins > Global Tool Configuration**.
    -   Click **Add SonarQube Scanner**.
    -   Name: `SonarScanner`.
    -   Choose **Install automatically**.

### C. Configure GitHub Webhook

1.  **In your GitHub Repository:**
    -   Go to **Settings > Webhooks**.
    -   Click **Add webhook**.
        -   Payload URL: `http://<YOUR_JENKINS_IP>:8080/github-webhook/`.
        -   Content type: `application/json`.
        -   Select **Just the `push` event**.
    -   Click **Add webhook**. A green checkmark indicates success.

## Step 6: Creating the Project Files

In your GitHub repository, create the following three files.

1.  **`index.html` (A simple website to deploy):**
    ```html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>CI/CD Project</title>
        <style>
            body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px; background-color: #282c34; color: white; }
            h1 { font-size: 3em; color: #61dafb; }
        </style>
    </head>
    <body>
        <h1>CI/CD Pipeline Successful!</h1>
        <p>This page was automatically deployed by a Jenkins pipeline.</p>
    </body>
    </html>
    ```

2.  **`Dockerfile` (Instructions to build the application image):**
    ```dockerfile
    # Use an official Nginx runtime as a parent image
    FROM nginx:alpine

    # Copy the static content from the current directory to the Nginx html directory
    COPY . /usr/share/nginx/html

    # Expose port 80 to the outside world
    EXPOSE 80
    ```

3.  **`Jenkinsfile` (The heart of the pipeline):**
    ```groovy
    pipeline {
        agent any

        tools {
            // Must match the name in Global Tool Configuration
            sonarqube 'SonarScanner'
        }

        environment {
            // Use the credential ID from Jenkins
            SCANNER_TOKEN = credentials('sonarqube-token')
            DOCKER_IMAGE_NAME = "my-web-app"
        }

        stages {
            stage('Checkout from Git') {
                steps {
                    git '[https://github.com/](https://github.com/)<YOUR_USERNAME>/<YOUR_REPO_NAME>.git'
                }
            }

            stage('Code Analysis') {
                steps {
                    // This stage is a placeholder. A real project would require a sonar-project.properties
                    // file or more specific scanner arguments to run a meaningful analysis.
                    script {
                        echo "Skipping SonarQube analysis for this simple example."
                    }
                }
            }

            stage('Build & Deploy Docker Image') {
                steps {
                    script {
                        // We build the image on the Jenkins agent itself
                        def dockerImage = docker.build(DOCKER_IMAGE_NAME)

                        // To deploy, we SSH into the Docker Host and run the container.
                        // This requires setting up SSH credentials in Jenkins.
                        // Go to Manage Jenkins > Credentials > Add Credentials:
                        // Kind: SSH Username with private key
                        // ID: docker-host-ssh-key
                        // Private Key: Enter the private key for your Docker Host.
                        sshagent(['docker-host-ssh-key']) {
                            sh """
                                ssh -o StrictHostKeyChecking=no ubuntu@<YOUR_DOCKER_HOST_IP> '
                                    docker stop ${DOCKER_IMAGE_NAME} || true
                                    docker rm ${DOCKER_IMAGE_NAME} || true
                                    docker run -d --name ${DOCKER_IMAGE_NAME} -p 80:80 ${DOCKER_IMAGE_NAME}
                                '
                            """
                        }
                    }
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
    **Note on the `Jenkinsfile`:**
    -   Replace `<YOUR_USERNAME>/<YOUR_REPO_NAME>.git` with your repository URL.
    -   Replace `<YOUR_DOCKER_HOST_IP>` with the public IP of your deployment server.
    -   The `sshagent` step requires you to add an SSH credential (the private key for your Docker Host) to Jenkins with the ID `docker-host-ssh-key`.

## Step 7: Creating the Jenkins Pipeline

1.  Go to your Jenkins dashboard and click **New Item**.
2.  Enter a name (e.g., `WebApp-Deployment-Pipeline`), select **Pipeline**, and click **OK**.
3.  In the configuration page, scroll down to the **Pipeline** section.
    -   Definition: **Pipeline script from SCM**.
    -   SCM: **Git**.
    -   Repository URL: `https://github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>.git`.
    -   Branch: `*/main` or `*/master`.
    -   Script Path: `Jenkinsfile`.
4.  Click **Save**.

## Step 8: Testing the Pipeline

1.  Commit and push all three files (`index.html`, `Dockerfile`, `Jenkinsfile`) to your GitHub repository.
    ```bash
    git add .
    git commit -m "Initial project setup"
    git push origin main
    ```
2.  The `push` will trigger the GitHub webhook, which in turn starts your Jenkins pipeline.
3.  Open your Jenkins dashboard to monitor the pipeline's progress through the stages.
4.  Once the pipeline completes successfully, open your web browser and navigate to `http://<YOUR_DOCKER_HOST_IP>`.
5.  You should see your `index.html` page live!
