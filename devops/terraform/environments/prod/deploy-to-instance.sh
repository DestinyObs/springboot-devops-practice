#!/bin/bash

# Production Server Configuration Script
# Run this script on each production instance to install development tools

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to install Ansible if not present
install_ansible() {
    if ! command -v ansible &> /dev/null; then
        log "Installing Ansible..."
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository --yes --update ppa:ansible/ansible
        sudo apt install -y ansible
        log "Ansible installed successfully"
    else
        log "Ansible already installed"
    fi
}

# Function to create Ansible directory structure
create_ansible_structure() {
    log "Creating Ansible directory structure..."
    
    mkdir -p /home/ubuntu/ansible/{playbooks,roles,inventory,group_vars}
    mkdir -p /home/ubuntu/ansible/roles/{common,java,maven,docker}/tasks
    mkdir -p /home/ubuntu/ansible/roles/{common,java,maven,docker}/handlers
    mkdir -p /home/ubuntu/ansible/roles/{common,java,maven,docker}/vars
}

# Function to create inventory file
create_inventory() {
    log "Creating inventory file..."
    
    cat > /home/ubuntu/ansible/inventory/local.ini << 'EOF'
[servers]
localhost ansible_connection=local

[servers:vars]
ansible_user=ubuntu
ansible_become=yes
EOF
}

# Function to create group variables
create_group_vars() {
    log "Creating group variables..."
    
    cat > /home/ubuntu/ansible/group_vars/all.yml << 'EOF'
# Java Configuration
java_version: "17"

# Maven Configuration
maven_version: "3.9.6"

# Docker Configuration
docker_compose_version: "2.24.6"

# User Configuration
server_user: "ubuntu"
EOF
}

# Function to create common role
create_common_role() {
    log "Creating common role..."
    
    cat > /home/ubuntu/ansible/roles/common/tasks/main.yml << 'EOF'
---
- name: Update package cache
  apt:
    update_cache: yes
    cache_valid_time: 3600

- name: Install essential packages
  apt:
    name:
      - curl
      - wget
      - unzip
      - vim
      - htop
      - git
      - build-essential
      - tree
      - nano
      - screen
      - tmux
    state: present
EOF
}

# Function to create Java role
create_java_role() {
    log "Creating Java role..."
    
    cat > /home/ubuntu/ansible/roles/java/tasks/main.yml << 'EOF'
---
- name: Install OpenJDK
  apt:
    name: "openjdk-{{ java_version }}-jdk"
    state: present

- name: Set JAVA_HOME environment variable
  lineinfile:
    path: /etc/environment
    line: 'JAVA_HOME="/usr/lib/jvm/java-{{ java_version }}-openjdk-amd64"'
    create: yes

- name: Verify Java installation
  command: java -version
  register: java_version_output
  changed_when: false

- name: Display Java version
  debug:
    var: java_version_output.stderr_lines
EOF
}

# Function to create Maven role
create_maven_role() {
    log "Creating Maven role..."
    
    cat > /home/ubuntu/ansible/roles/maven/tasks/main.yml << 'EOF'
---
- name: Download Maven
  get_url:
    url: "https://archive.apache.org/dist/maven/maven-3/{{ maven_version }}/binaries/apache-maven-{{ maven_version }}-bin.tar.gz"
    dest: "/tmp/apache-maven-{{ maven_version }}-bin.tar.gz"

- name: Create Maven directory
  file:
    path: "/opt/maven"
    state: directory

- name: Extract Maven
  unarchive:
    src: "/tmp/apache-maven-{{ maven_version }}-bin.tar.gz"
    dest: "/opt/maven"
    remote_src: yes
    creates: "/opt/maven/apache-maven-{{ maven_version }}"

- name: Create Maven symlink
  file:
    src: "/opt/maven/apache-maven-{{ maven_version }}"
    dest: "/opt/maven/current"
    state: link

- name: Add Maven to PATH
  lineinfile:
    path: /etc/environment
    line: 'PATH="/opt/maven/current/bin:$PATH"'
    regexp: '^PATH='
    backup: yes

- name: Set MAVEN_HOME
  lineinfile:
    path: /etc/environment
    line: 'MAVEN_HOME="/opt/maven/current"'
    create: yes

- name: Verify Maven installation
  shell: /opt/maven/current/bin/mvn -version
  register: maven_version_output
  changed_when: false

- name: Display Maven version
  debug:
    var: maven_version_output.stdout_lines
EOF
}

# Function to create Docker role
create_docker_role() {
    log "Creating Docker role..."
    
    cat > /home/ubuntu/ansible/roles/docker/tasks/main.yml << 'EOF'
---
- name: Install Docker dependencies
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
    state: present

- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present

- name: Install Docker
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
    state: present
    update_cache: yes

- name: Add user to docker group
  user:
    name: "{{ server_user }}"
    groups: docker
    append: yes

- name: Start and enable Docker service
  systemd:
    name: docker
    state: started
    enabled: yes

- name: Install Docker Compose
  get_url:
    url: "https://github.com/docker/compose/releases/download/v{{ docker_compose_version }}/docker-compose-Linux-x86_64"
    dest: "/usr/local/bin/docker-compose"
    mode: '0755'

- name: Verify Docker installation
  command: docker --version
  register: docker_version_output
  changed_when: false

- name: Display Docker version
  debug:
    var: docker_version_output.stdout
EOF
}

# Function to create main playbook
create_main_playbook() {
    log "Creating main playbook..."
    
    cat > /home/ubuntu/ansible/playbooks/configure-server.yml << 'EOF'
---
- name: Configure Production Server
  hosts: servers
  become: yes
  
  roles:
    - common
    - java
    - maven
    - docker
  
  post_tasks:
    - name: Display server configuration summary
      debug:
        msg: 
          - "Server configuration completed successfully"
          - "Java 17 installed and configured"
          - "Maven installed and configured"
          - "Docker installed and configured"
          - "Essential development tools installed"
          - "Server is ready for application deployment"
EOF
}

# Main execution
main() {
    log "Starting server configuration..."
    
    install_ansible
    create_ansible_structure
    create_inventory
    create_group_vars
    create_common_role
    create_java_role
    create_maven_role
    create_docker_role
    create_main_playbook
    
    log "Ansible structure created successfully"
    log "Running server configuration playbook..."
    
    cd /home/ubuntu/ansible
    ansible-playbook -i inventory/local.ini playbooks/configure-server.yml
    
    log "Server configuration completed successfully"
    log "Tools installed: Java 17, Maven, Docker, Git, and essential packages"
    log "Server is ready for your application deployment"
}

# Run main function
main "$@"
