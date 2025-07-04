# CI/CD Pipeline with Jenkins, SonarQube, and Docker

An end-to-end CI/CD pipeline implementation to automate application deployment and ensure high code quality. The project leverages Jenkins for automation, SonarQube for code analysis, and Docker for containerization, all hosted on AWS EC2.

## Table of Contents

1.  [Architecture](#architecture)
2.  [Prerequisites](#prerequisites)
3.  [Step 1: Infrastructure Setup](#step-1-infrastructure-setup)
4.  [Step 2: Jenkins Server Setup](#step-2-jenkins-server-setup)
5.  [Step 3: SonarQube Server Setup](#step-3-sonarqube-server-setup)
6.  [Step 4: Docker Host Setup](#step-4-docker-host-setup)
7.  [Step 5: System Configuration](#step-5-system-configuration)
8.  [Step 6: Creating the Project Files](#step-6-creating-the-project-files)
9.  [Step 7: Creating and Configuring the Jenkins Job](#step-7-creating-and-configuring-the-jenkins-job)
10. [Step 8: Testing the Pipeline](#step-8-testing-the-pipeline)

## Architecture

The project follows a straightforward CI/CD workflow:

`Code Push` -> `GitHub Webhook` -> `Jenkins Job Trigger` -> `SonarQube Analysis` -> `File Transfer & Remote Execution` -> `Docker Build & Deploy`


## Prerequisites

-   An **AWS Account** with permissions to create EC2 instances.
-   A **GitHub Account** and a new repository for your project.
-   Basic knowledge of Linux commands.

---

## Step 1: Infrastructure Setup

1.  **Launch EC2 Instances:** Create three `t2.medium or higher` instances with Ubuntu Server AMI for Jenkins, SonarQube, and Docker.
2.  **Assign Elastic IPs (EIP):** Assign an Elastic IP to each instance to get a static public IP address.
3.  **Configure Security Groups:**
    -   **Jenkins SG:** Allow inbound TCP on port `8080` (from anywhere) and `22` (from your IP).
    -   **SonarQube SG:** Allow inbound TCP on port `9000` (from anywhere) and `22` (from your IP).
    -   **Docker Host SG:** Allow inbound TCP on port `8085` (from anywhere) and `22` (from your IP and Jenkins' IP).

## Step 2: Jenkins Server Setup

1.  SSH into the Jenkins instance.
2.  Install Java and Jenkins using the command line.
3.  Access the Jenkins GUI via its public IP at `http://<YOUR_JENKINS_PUBLIC_IP>:8080`.
4.  Complete the initial setup (unlock, install suggested plugins, create admin user).
5.  **Install Additional Plugins:** Go to **Manage Jenkins > Plugins > Available plugins** and install:
    -   `SonarQube Scanner`
    -   **`Publish Over SSH`**

## Step 3: SonarQube Server Setup

1.  SSH into your SonarQube instance.
2.  Install Java and the `unzip` utility.
3.  Download and set up SonarQube. It's recommended to get the latest LTS (Long-Term Support) version from the [SonarQube downloads page](https://www.sonarsource.com/products/sonarqube/downloads/).
    ```bash
    # Replace the link with the one you copied
    wget [https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.4.87374.zip](https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.4.87374.zip)
    unzip sonarqube-9.9.4.87374.zip
    sudo mv sonarqube-9.9.4.87374 /opt/sonarqube
    ```
4.  Create a dedicated user and set permissions for SonarQube:
    ```bash
    sudo adduser --system --no-create-home --group --disabled-login sonarqube
    sudo chown -R sonarqube:sonarqube /opt/sonarqube
    ```
5.  Create a systemd service file (`sudo nano /etc/systemd/system/sonar.service`) to run SonarQube in the background:
    ```ini
    [Unit]
    Description=SonarQube service
    After=syslog.target network.target

    [Service]
    Type=forking
    User=sonarqube
    Group=sonarqube
    PermissionsStartOnly=true
    ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
    ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
    StandardOutput=syslog
    LimitNOFILE=65536
    LimitNPROC=4096
    TimeoutStartSec=5
    Restart=always

    [Install]
    WantedBy=multi-user.target
    ```
6.  Start and enable the SonarQube service:
    ```bash
    sudo systemctl start sonar
    sudo systemctl enable sonar
    ```
7.  Access the SonarQube GUI via its public IP at `http://<YOUR_SONARQUBE_PUBLIC_IP>:9000`.

## Step 4: Docker Host Setup

1.  SSH into the Docker instance.
2.  Install Docker and add your user to the `docker` group.
    ```bash
    sudo apt update
    sudo apt install -y docker.io
    sudo usermod -aG docker ${USER}
    newgrp docker
    ```

## Step 5: System Configuration

### A. Connect Jenkins to SonarQube
1.  **In SonarQube:** Generate a user token (**Administration > Security > Users**).
2.  **In Jenkins:**
    -   Add the token as a `Secret text` credential.
    -   Go to **Manage Jenkins > Configure System**, add a SonarQube server, and link the credential.
    -   Go to **Manage Jenkins > Global Tool Configuration** to add a `SonarQube Scanner` installation.

### B. Configure Publish Over SSH Plugin
1.  **In Jenkins:** Go to **Manage Jenkins > Configure System**.
2.  Scroll down to **Publish over SSH**.
3.  Add a new SSH server with the details of your Docker Host (Name: `Docker-Host`, Hostname, Username, and authentication method).
4.  Test the connection to verify it works.

### C. Configure GitHub Webhook
1.  **In GitHub:** Go to your repository's **Settings > Webhooks**.
2.  Add a new webhook with the Payload URL `http://<YOUR_JENKINS_IP>:8080/github-webhook/`.

## Step 6: Creating the Project Files

At a minimum, your GitHub repository should contain an `index.html` and a `Dockerfile`. Here are the example contents for each file.

1.  **`index.html`**
    ```html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>CI/CD Project</title>
    </head>
    <body>
        <h1>CI/CD Pipeline Successful!</h1>
        <p>This page was automatically deployed by a Jenkins pipeline.</p>
    </body>
    </html>
    ```

2.  **`Dockerfile`**
    ```dockerfile
    # Use a lightweight Nginx image as the base
    FROM nginx:alpine

    # Copy all files from the current directory into the container
    COPY . /usr/share/nginx/html

    # Expose port 80 (the default Nginx port) inside the container
    EXPOSE 80
    ```

## Step 7: Creating and Configuring the Jenkins Job

1.  On the Jenkins dashboard, click **New Item**.
2.  Enter a name for your project, choose **Freestyle project**, and click **OK**.
3.  **Source Code Management** Tab:
    -   Select **Git**.
    -   **Repository URL:** Enter your GitHub repository URL.
4.  **Build Triggers** Tab:
    -   Check **GitHub hook trigger for GITScm polling**.
5.  **Build Steps** Section:
    -   (Optional) Click **Add build step** and choose **Execute SonarQube Scanner**.
6.  **Post-build Actions** Section:
    -   Click **Add post-build action** and choose **Send build artifacts over SSH**.
    -   **Name**: Select `Docker-Host` (the server you configured in Step 5).
    -   **Transfers**:
        -   **Source files**: `**/*` (this copies all files from the workspace).
        -   **Remote directory**: `/home/ubuntu/app` (a folder on your Docker host).
        -   **Exec command**: Enter the following script to build and run your Docker container on the remote server.
            ```bash
            cd /home/ubuntu/app

            echo "Building Docker image..."
            docker build -t my-web-app .

            echo "Stopping and removing old container..."
            docker stop my-web-app || true
            docker rm my-web-app || true

            echo "Running new Docker container..."
            docker run -d --name my-web-app -p 8085:80 my-web-app
            ```
7.  Click **Save**.

## Step 8: Testing the Pipeline

1.  Make a change to your `index.html` file.
2.  Commit and push the change to your GitHub repository.
    ```bash
    git add .
    git commit -m "Test automatic deployment"
    git push origin main
    ```
3.  The push will trigger the Jenkins job automatically.
4.  Monitor the build progress in the Jenkins dashboard.
5.  Once it succeeds, open your browser and navigate to `http://<YOUR_DOCKER_HOST_IP>:8085`. You should see your updated web page live.
