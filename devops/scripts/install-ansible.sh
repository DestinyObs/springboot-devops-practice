#!/bin/bash

# Simple setup script to ensure Ansible is ready before running Terraform

echo "Checking if Ansible is installed..."

if ! command -v ansible &> /dev/null; then
    echo "Ansible not found. Installing now..."
    sudo apt update
    sudo apt install -y ansible
    echo "Ansible installed successfully."
else
    echo "Ansible is already installed."
    ansible --version
fi

echo "Ansible is set up and you're ready to run Terraform."
