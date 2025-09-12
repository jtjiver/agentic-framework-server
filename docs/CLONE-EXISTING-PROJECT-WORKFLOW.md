# Clone Existing Project with ASW Tools

## Quick Start: Working with an Existing Next.js Project

This guide shows how to clone an existing project (like a Next.js app) and set it up with the ASW framework tools.

### Step 1: Clone Your Project

```bash
# Clone your existing project
git clone https://github.com/yourusername/your-nextjs-project.git
cd your-nextjs-project

# Or if using a specific directory
git clone https://github.com/yourusername/your-nextjs-project.git my-project
cd my-project
```

### Step 2: Add Claude Code Configuration

```bash
# Add the Claude config as a submodule
git submodule add https://github.com/jtjiver/agentic-claude-config.git .claude

# Initialize the submodule
git submodule update --init --recursive
```

### Step 3: Set Up Project Secrets (Optional)

If your project needs secrets management:

```bash
# Create vault configuration for the project
echo 'VAULT_NAME="YourProject-Secrets"' > .vault-config

# Source the vault manager
source /opt/asw/agentic-framework-security/lib/shared/vault-context-manager.sh

# Get project secrets (will use YourProject-Secrets vault)
get_secret "DATABASE_URL"
get_secret "API_KEY"
```

### Step 4: Install Project Dependencies

```bash
# For Next.js projects using npm
npm install

# Or if using yarn
yarn install

# Or if using pnpm
pnpm install
```

### Step 5: Set Up Environment Variables

```bash
# Copy example env file if it exists
cp .env.example .env.local

# Or create a new one
touch .env.local

# Add any required environment variables
echo "NEXT_PUBLIC_API_URL=http://localhost:3000" >> .env.local
```

### Step 6: Run the Development Server

```bash
# Start the Next.js development server
npm run dev

# Or with yarn
yarn dev

# Or with pnpm
pnpm dev
```

The server typically runs on `http://localhost:3000` by default.

### Step 7: Verify the Setup

```bash
# Check if the server is running
curl http://localhost:3000

# Or open in browser
open http://localhost:3000
```

## Complete Example Workflow

Here's a complete example for cloning and setting up a Next.js project:

```bash
# 1. Clone the project
PROJECT_NAME="my-nextjs-app"
git clone https://github.com/yourusername/${PROJECT_NAME}.git
cd ${PROJECT_NAME}

# 2. Add Claude Code config
git submodule add https://github.com/jtjiver/agentic-claude-config.git .claude
git submodule update --init --recursive

# 3. Install dependencies
npm install

# 4. Set up environment
cp .env.example .env.local || touch .env.local

# 5. Run development server
npm run dev &

# 6. Wait for server to start
sleep 5

# 7. Verify it's running
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Next.js server is running at http://localhost:3000"
else
    echo "❌ Server failed to start"
fi
```

## Working with Claude Code

Once your project is set up, you can use Claude Code to help with development:

```bash
# Start Claude in your project directory
cd /path/to/your-project
claude

# Claude will have access to:
# - Your project files
# - The .claude configuration
# - Any hooks you've set up
# - Project-specific commands
```

## Common Next.js Commands with ASW

```bash
# Development
npm run dev          # Start development server
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
npm run type-check   # Run TypeScript checks

# Testing
npm test            # Run tests
npm run test:watch  # Run tests in watch mode
npm run test:ci     # Run tests for CI

# With Claude assistance
claude "fix the TypeScript errors in my components"
claude "add a new API route for user authentication"
claude "optimize the performance of my homepage"
```

## Port Management (if using ASW infrastructure)

If you're using the full ASW infrastructure with port management:

```bash
# Allocate a port for your project
/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager allocate ${PROJECT_NAME}

# Get the allocated port
PORT=$(/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager get ${PROJECT_NAME})

# Run Next.js on the allocated port
PORT=${PORT} npm run dev
```

## Troubleshooting

### Server Won't Start
```bash
# Check if port 3000 is in use
lsof -i :3000

# Kill any process using the port
kill -9 $(lsof -t -i :3000)

# Try a different port
PORT=3001 npm run dev
```

### Dependencies Won't Install
```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

### Environment Variables Not Loading
```bash
# Make sure .env.local exists
ls -la .env*

# Check Next.js is reading the right file
# Next.js loads in this order:
# 1. .env.local
# 2. .env.[NODE_ENV]
# 3. .env
```

## File Structure After Setup

```
your-nextjs-project/
├── .claude/                    # Claude Code configuration
│   ├── hooks/                  # Custom hooks
│   └── utils/                  # Utility scripts
├── .env.local                  # Local environment variables
├── .vault-config              # Project vault configuration (optional)
├── node_modules/              # Project dependencies
├── pages/ or app/             # Next.js pages/app directory
├── public/                    # Static files
├── styles/                    # CSS/SCSS files
├── package.json               # Project configuration
└── next.config.js             # Next.js configuration
```

## Best Practices

1. **Always use `.env.local`** for local development secrets
2. **Never commit `.env.local`** to version control
3. **Use the vault manager** for production secrets
4. **Run typecheck and lint** before committing changes
5. **Keep Claude config updated** with `git submodule update --remote`

## Next Steps

- Set up CI/CD pipelines for automated deployment
- Configure production environment variables
- Add monitoring and logging
- Set up database connections
- Configure API integrations