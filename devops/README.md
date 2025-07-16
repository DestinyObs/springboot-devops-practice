# DevOps Infrastructure & Automation

This directory contains all DevOps-related infrastructure and automation for the **User Registration Microservice** project. Following industry best practices with clear separation of concerns.

## Project Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Terraform     │───▶│     Ansible     │───▶│    CI/CD        │
│  (Infrastructure)│    │  (Configuration)│    │   (Jenkins)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        ▼                       ▼                       ▼
   AWS Resources          Server Setup           App Deployment
   • EC2 Instances        • Java/Maven           • Docker Build
   • VPC/Networking       • Docker Engine        • Container Deploy
   • Security Groups      • Docker Compose       • Health Checks
   • Key Pairs           • MySQL Container       • Monitoring
```
