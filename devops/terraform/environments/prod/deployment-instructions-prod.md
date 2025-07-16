# Production Manual Deployment

## Quick Start:

1. **Connect to any instance:**
   aws ssm start-session --target i-063c923479cc8145e or i-0eb9cd0227720147c or i-0e46e3efedc493526

2. **Run Ansible playbook:**
   cd /home/ubuntu/ansible
   ansible-playbook -i inventory/prod.ini playbooks/site.yml --connection=local

## Instance Information:
- Environment: prod
- Instances: i-063c923479cc8145e, i-0eb9cd0227720147c, i-0e46e3efedc493526
- ALB URL: https://user-reg-prod-alb-976927690.us-east-2.elb.amazonaws.com

## Ansible files are already on each instance at: /home/ubuntu/ansible

