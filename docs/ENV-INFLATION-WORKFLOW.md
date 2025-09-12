# Environment File Inflation from 1Password

## Quick Setup for New Project

### Method 1: Using the Setup Script

```bash
# Clone and set up in one command
/opt/asw/scripts/setup-project-env.sh https://github.com/yourusername/your-project.git

# Or specify a directory name
/opt/asw/scripts/setup-project-env.sh https://github.com/yourusername/your-project.git my-project
```

This script will:
1. Clone your repository
2. Check 1Password access
3. Find `.env.template` or `.env.example`
4. Inflate `.env` with secrets from 1Password
5. Copy Claude config
6. Install dependencies

### Method 2: Manual Setup with Templates

#### Step 1: Create `.env.template` in your repo

```env
# .env.template - commit this to your repo
DATABASE_URL="op://TennisTracker-Dev-Vault/database/url"
API_KEY="op://TennisTracker-Dev-Vault/api/key"
ELEVENLABS_API_KEY="op://TennisTracker-Dev-Vault/elevenlabs - API - claude-code/credential"
STRIPE_SECRET="op://TennisTracker-Dev-Vault/stripe/secret_key"
```

#### Step 2: After cloning, inflate the .env

```bash
# Clone your repo
git clone https://github.com/yourusername/your-project.git
cd your-project

# Ensure 1Password is authenticated
op vault list > /dev/null || eval $(op signin)

# Inflate .env from template
op inject -i .env.template -o .env

# Verify
cat .env
```

### Method 3: Direct Secret Retrieval

```bash
# Get individual secrets
echo "ELEVENLABS_API_KEY=$(op item get 'elevenlabs - API - claude-code' --vault 'TennisTracker-Dev-Vault' --fields label=credential --reveal)" >> .env

# Or use a simple function
get_secret() {
    op item get "$1" --vault "TennisTracker-Dev-Vault" --fields "${2:-password}" --reveal
}

# Use it
echo "API_KEY=$(get_secret 'api-key' 'credential')" >> .env
```

## Template Reference Format

1Password template syntax: `op://vault/item/field`

Examples:
```env
# Basic format
SECRET="op://MyVault/MyItem/password"

# With spaces in names (use URL encoding or quotes)
API_KEY="op://TennisTracker-Dev-Vault/elevenlabs - API - claude-code/credential"

# Common field names
PASSWORD="op://vault/item/password"
USERNAME="op://vault/item/username"
URL="op://vault/item/url"
NOTES="op://vault/item/notes"
```

## Best Practices

### 1. Repository Setup

**Commit these files:**
- `.env.template` or `.env.example` (with 1Password references)
- `.vault-config` (optional, specifies default vault)

**Never commit:**
- `.env` (add to .gitignore)
- `.env.local` 
- Any file with actual secrets

### 2. Project Structure

```
your-project/
├── .env.template       # Template with op:// references (commit this)
├── .env               # Actual env file (never commit)
├── .vault-config      # Optional: default vault name
├── .gitignore         # Must include .env
└── package.json
```

### 3. .vault-config File (Optional)

```bash
# .vault-config
VAULT_NAME="TennisTracker-Dev-Vault"
```

### 4. Team Collaboration

Share with your team:
1. The vault name in 1Password
2. The `.env.template` file
3. This setup command:

```bash
# One-liner for team members
git clone <repo> && cd <project> && op inject -i .env.template -o .env && npm install
```

## Troubleshooting

### 1Password Not Authenticated

```bash
# Sign in to 1Password
eval $(op signin)

# Verify access
op vault list
```

### Can't Find Vault

```bash
# List all vaults
op vault list

# Search for vault
op vault list | grep -i tennis
```

### Can't Find Item

```bash
# List items in vault
op item list --vault "TennisTracker-Dev-Vault"

# Search for item
op item list --vault "TennisTracker-Dev-Vault" | grep -i elevenlabs
```

### Template Not Working

```bash
# Test template syntax
op inject -i .env.template

# Debug mode
export OP_DEBUG=1
op inject -i .env.template -o .env
```

## Complete Example

Here's a complete workflow for a Next.js project:

```bash
# 1. In your repo, create .env.template
cat > .env.template << 'EOF'
DATABASE_URL="op://TennisTracker-Dev-Vault/database/url"
NEXT_PUBLIC_API_URL="http://localhost:3000"
ELEVENLABS_API_KEY="op://TennisTracker-Dev-Vault/elevenlabs - API - claude-code/credential"
STRIPE_SECRET_KEY="op://TennisTracker-Dev-Vault/stripe/secret_key"
JWT_SECRET="op://TennisTracker-Dev-Vault/jwt/secret"
EOF

# 2. Clone and setup (what your team does)
git clone https://github.com/yourusername/tennis-tracker.git
cd tennis-tracker

# 3. Authenticate with 1Password
op vault list > /dev/null || eval $(op signin)

# 4. Inflate environment
op inject -i .env.template -o .env

# 5. Install and run
npm install
npm run dev
```

## Aliases for Convenience

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Quick environment setup
alias env-inflate='op inject -i .env.template -o .env'

# Get secret from default vault
get-secret() {
    local vault="${VAULT_NAME:-TennisTracker-Dev-Vault}"
    op item get "$1" --vault "$vault" --fields "${2:-password}" --reveal
}

# Clone and setup project
clone-setup() {
    git clone "$1" && cd "$(basename "$1" .git)" && \
    [[ -f .env.template ]] && op inject -i .env.template -o .env && \
    npm install
}
```

Then use:
```bash
# Quick clone and setup
clone-setup https://github.com/yourusername/your-project.git
```