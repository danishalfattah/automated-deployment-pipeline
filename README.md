# CI/CD Pipeline for Automated Application Deployment and Code Quality Analysis

This repository contains the implementation of a CI/CD pipeline designed to automate application deployment and ensure high code quality. The project leverages Jenkins for automation, SonarQube for code analysis, and Docker for containerization, all hosted on AWS EC2.

This project was created by:
- Muhammad Danish Alfattah Lubis (235150207111008)
- Muhammad Bagas Anugrah (235150201111008)
- Yusrizal Harits Firdaus (235150207111011)

## Table of Contents

1.  [Project Overview](#project-overview)
2.  [Objectives](#objectives)
3.  [Architecture and Design](#architecture-and-design)
4.  [Team Roles and Responsibilities](#team-roles-and-responsibilities)
5.  [Implementation Steps](#implementation-steps)
6.  [Challenges and Solutions](#challenges-and-solutions)
7.  [Final Result](#final-result)

## Project Overview

[cite_start]This project aims to accelerate the application release process while minimizing errors commonly associated with manual deployments[cite: 3]. [cite_start]We designed an automated CI/CD pipeline that handles the build, testing, and deployment processes every time a change is pushed to the GitHub repository[cite: 4].

The core technologies used are:
-   [cite_start]**Jenkins:** The primary automation server for the CI/CD pipeline[cite: 5].
-   [cite_start]**SonarQube:** Integrated for static code analysis to maintain high code quality[cite: 5].
-   [cite_start]**Docker & AWS EC2:** Used as an efficient and scalable environment for running the containerized application[cite: 5].

[cite_start]This automated approach ensures that the integration and release process is more reliable, consistent, and easy to monitor[cite: 6].

## Objectives

The main goals of this project are:
1.  [cite_start]To implement automated application deployment using Jenkins and AWS EC2[cite: 9].
2.  [cite_start]To establish an efficient CI/CD pipeline to support rapid development and release cycles[cite: 10].
3.  [cite_start]To ensure code quality through static analysis with SonarQube, identifying and fixing bugs, vulnerabilities, and code smells[cite: 11].

## Architecture and Design

[cite_start]This project implements a cloud-native solution using AWS EC2 and Docker for application hosting, with Jenkins automating the entire pipeline[cite: 12].

1.  **CI/CD Pipeline with Jenkins:**
    -   [cite_start]Jenkins automates the build, test, and deployment process, triggered by code changes in GitHub[cite: 13].
    -   [cite_start]Static code quality analysis with SonarQube is integrated into the pipeline to automatically identify potential bugs and vulnerabilities before deployment[cite: 14].

2.  **Application Hosting with AWS EC2 and Docker:**
    -   [cite_start]The application is deployed inside a Docker container hosted on an AWS EC2 instance[cite: 15, 16].
    -   [cite_start]AWS manages the underlying EC2 infrastructure, while Docker provides a consistent and isolated environment for the application[cite: 17].

## Team Roles and Responsibilities

-   **Yusrizal Harits Firdaus:**
    -   [cite_start]Responsible for setting up AWS EC2 for application hosting[cite: 18].
    -   [cite_start]Managed the underlying cloud infrastructure required for Docker deployment on EC2[cite: 19].
-   **Muhammad Danish Alfattah Lubis:**
    -   [cite_start]Implemented the Jenkins pipeline for CI/CD automation[cite: 20].
    -   [cite_start]Integrated GitHub with Jenkins to automate the build, test, and deploy stages[cite: 21].
    -   [cite_start]Integrated SonarQube into the Jenkins pipeline for code quality analysis[cite: 22].
-   **Muhammad Bagas Anugrah:**
    -   [cite_start]Conducted functional testing of the application after deployment to verify its functionality[cite: 23].
    -   [cite_start]Assisted with Docker configuration and application deployment scripts[cite: 24].

## Implementation Steps

1.  [cite_start]**Create 3 AWS EC2 Instances:** One instance each for Jenkins, SonarQube, and Docker[cite: 25].
2.  [cite_start]**Assign Elastic IPs (EIP):** Each instance was assigned an EIP to ensure its public IP address remains static[cite: 26]. [cite_start]This is crucial for stable inter-instance configurations[cite: 27].
3.  **Install and Configure Jenkins:**
    -   [cite_start]Accessed the Jenkins instance via SSH and installed the Jenkins service[cite: 28].
    -   [cite_start]Completed initial setup via the web interface and connected Jenkins to the GitHub repository using Webhooks to automatically trigger the pipeline on code changes[cite: 29, 30].
4.  **Install and Configure SonarQube:**
    -   [cite_start]Accessed the SonarQube instance via SSH, installed the service, and performed the initial configuration via the web interface[cite: 31, 32].
    -   [cite_start]Created a freestyle project in SonarQube to be used for code analysis[cite: 33].
5.  [cite_start]**Integrate SonarQube with Jenkins:** Configured Jenkins to send code to SonarQube for analysis as a pipeline stage[cite: 34].
6.  [cite_start]**Install Docker:** Accessed the Docker instance via SSH and installed the Docker service[cite: 35].
7.  [cite_start]**Configure SSH on Docker Instance:** Modified the `sshd_config` file on the Docker instance to allow Jenkins to access it via SSH for file transfers[cite: 36, 37].
8.  **Connect Jenkins to Docker for Deployment:**
    -   [cite_start]Configured Jenkins to transfer application files to the Docker instance using the previously configured SSH connection[cite: 38, 39].
    -   This was achieved using the **Publish Over SSH** plugin.
9.  [cite_start]**Deploy Application:** The application is deployed to a Docker container and becomes accessible via the public IP of the EC2 instance[cite: 40, 41].

## Challenges and Solutions

-   [cite_start]**Problem:** We encountered failures when trying to transfer files from Jenkins to the Docker instance using the `ssh2easy` plugin[cite: 43].
-   [cite_start]**Solution:** We replaced the `ssh2easy` plugin with the **Publish Over SSH** plugin in Jenkins[cite: 44]. [cite_start]This plugin provided the same functionality for file transfer and remote command execution and resolved the issue[cite: 45].

## Final Result

The application was successfully deployed and is accessible via the public IP of the Docker host instance. [cite_start]The final deployment showcases the "Danishian Films" web application[cite: 42].

![Final Deployment Screenshot](https://i.imgur.com/r3g4bC3.jpeg)
