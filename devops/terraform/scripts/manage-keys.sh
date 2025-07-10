#!/bin/bash

PROJECT_NAME="user-registration-microservice"

# Quick check: is AWS CLI installed and set up?
check_aws() {
    if ! command -v aws &> /dev/null; then
        echo "AWS CLI isn't installed. Please install it first."
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        echo "AWS credentials aren't configured. Run: aws configure"
        exit 1
    fi
}

# Create a key pair for the environment (dev, test, prod)
create_key() {
    env=$1
    key_name="${PROJECT_NAME}-${env}-key"
    pem_file="${key_name}.pem"
    pub_file="${key_name}.pub"

    if [ -z "$env" ]; then
        echo "Please specify environment: dev, test, or prod"
        exit 1
    fi

    if aws ec2 describe-key-pairs --key-names "$key_name" &> /dev/null; then
        echo "Key '$key_name' exists. Recreate it? (y/N): "
        read confirm
        if [[ $confirm =~ ^[yY](es)?$ ]]; then
            aws ec2 delete-key-pair --key-name "$key_name"
            echo "Old key deleted"
        else
            echo "Keeping the old key"
            return
        fi
    fi

    aws ec2 create-key-pair \
        --key-name "$key_name" \
        --key-type rsa \
        --key-format pem \
        --query 'KeyMaterial' \
        --output text > "$pem_file"

    chmod 600 "$pem_file"

    ssh-keygen -y -f "$pem_file" > "$pub_file" 2>/dev/null

    echo "Key created:"
    echo "- Private: $pem_file"
    echo "- Public: $pub_file"
    echo "- AWS Name: $key_name"
}

# List all key pairs for this project
list_keys() {
    aws ec2 describe-key-pairs \
        --query "KeyPairs[?contains(KeyName, '$PROJECT_NAME')].{Name:KeyName}" \
        --output table
}

# Delete a key pair by environment
delete_key() {
    env=$1
    key_name="${PROJECT_NAME}-${env}-key"
    pem_file="${key_name}.pem"
    pub_file="${key_name}.pub"

    if [ -z "$env" ]; then
        echo "Specify the environment to delete: dev, test, or prod"
        exit 1
    fi

    echo "Really delete '$key_name'? Type yes to confirm:"
    read confirmation
    if [ "$confirmation" != "yes" ]; then
        echo "Canceled"
        exit
    fi

    aws ec2 delete-key-pair --key-name "$key_name" 2>/dev/null && \
        echo "Deleted from AWS"

    rm -f "$pem_file" "$pub_file"
    echo "Deleted local files"
}

# What should we do?
case "$1" in
    create)
        check_aws
        create_key "$2"
        ;;
    list)
        check_aws
        list_keys
        ;;
    delete)
        check_aws
        delete_key "$2"
        ;;
    *)
        echo ""
        echo "USAGE: ./key-tool.sh [create|list|delete] <env>"
        echo "Examples:"
        echo "  ./key-tool.sh create dev"
        echo "  ./key-tool.sh list"
        echo "  ./key-tool.sh delete prod"
        echo ""
        ;;
esac
