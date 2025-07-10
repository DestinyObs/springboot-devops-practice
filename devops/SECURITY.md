# 🔐 DevOps Security Guidelines

## Files Safe to Commit ✅

**Infrastructure Code:**
- `*.tf` files (Terraform infrastructure code)
- `*.tf.json` files
- `terraform.tfvars.example` (templates)
- `variables.tf` (variable definitions)
- `outputs.tf` (output definitions)
- `README.md` and documentation

**Application Code:**
- All Java source code (`*.java`)
- Configuration templates (`application.properties.example`)
- Dockerfile and Docker Compose templates
- CI/CD pipeline definitions

## Files NEVER to Commit ❌

**Terraform Sensitive Files:**
- `terraform.tfvars` - Contains actual values
- `*.tfstate` - Contains infrastructure state & secrets
- `*.tfplan` - May contain sensitive data
- `.terraform/` - Terraform cache directory
- `*.pem` - SSH private keys

**Application Sensitive Files:**
- `application.properties` (with real passwords)
- `.env` files with real secrets
- AWS credentials or config files
- Database connection strings with passwords

## Quick Security Check

Before pushing, run:
```bash
# Check what you're about to commit
git status
git diff --cached

# Verify no sensitive files
git ls-files | grep -E '\.(tfvars|tfstate|pem|key)$'
# This should return nothing!
```

## Emergency: Accidentally Committed Secrets

If you accidentally commit sensitive data:

1. **DO NOT PUSH** to remote repository
2. Remove from commit history:
   ```bash
   git reset --soft HEAD~1  # Undo last commit but keep changes
   git reset HEAD filename  # Unstage the sensitive file
   ```
3. Add the file to `.gitignore`
4. Regenerate any exposed secrets (keys, passwords, etc.)

## Safe Deployment Workflow

1. **Development:**
   ```bash
   cd devops/terraform/environments/dev
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   terraform plan  # Review before applying
   terraform apply
   ```

2. **Before Committing:**
   ```bash
   # Make sure terraform.tfvars is NOT staged
   git status
   git add *.tf *.md  # Add only safe files
   git commit -m "Add infrastructure code"
   ```

3. **Team Collaboration:**
   - Share `terraform.tfvars.example` files
   - Each team member creates their own `terraform.tfvars`
   - Use separate AWS accounts/environments for dev/test/prod

---

**Remember:** When in doubt, ask! It's better to double-check than to expose secrets. 🛡️
