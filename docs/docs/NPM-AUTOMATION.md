# NPM Publishing Automation Guide

## Overview

The Agentic Framework Core provides complete NPM publishing automation with multiple safety layers:

1. **Local validation** (pre-push hooks)
2. **CI/CD automation** (GitHub Actions)
3. **Manual controls** (NPM scripts)

## 🛡️ Safety Layers

### Layer 1: Pre-Push Hook (Local)
Automatically installed by `asw-init`, validates before pushing:
- ✅ Package builds successfully
- ✅ Version format is valid (semver)
- ⚠️ Warns if version not bumped for code changes
- 🔒 Runs security scan

### Layer 2: GitHub Actions (Remote)
Two workflow options included:
- **Auto-publish**: Publishes on version change in main branch
- **Manual release**: Triggered manually with version selection

### Layer 3: NPM Scripts (Manual)
Quick commands for controlled releases:
- `npm run release:patch` - Patch version (1.0.0 → 1.0.1)
- `npm run release:minor` - Minor version (1.0.0 → 1.1.0)
- `npm run release:major` - Major version (1.0.0 → 2.0.0)

## 🚀 Setup Instructions

### 1. Install Framework
```bash
npm install @agentic-framework/core
npx asw-init --profile=foundational
```

This automatically installs:
- Pre-commit hook (security scanning)
- Post-commit hook (auto-tagging)
- **Pre-push hook (NPM validation)** ← New!

### 2. Setup GitHub Actions

#### Option A: Auto-Publishing (Recommended)
```bash
# Copy workflow to your project
cp node_modules/@agentic-framework/core/templates/github-workflows/npm-autopublish.yml \
   .github/workflows/npm-publish.yml

# Add NPM token to GitHub Secrets
# Settings → Secrets → Actions → New repository secret
# Name: NPM_TOKEN
# Value: Your NPM automation token
```

#### Option B: Manual Releases
```bash
# Copy manual workflow instead
cp node_modules/@agentic-framework/core/templates/github-workflows/npm-manual-release.yml \
   .github/workflows/npm-release.yml
```

### 3. Configure NPM Token

Get your NPM automation token:
```bash
# Login to NPM
npm login

# Create automation token
npm token create --read-only=false --cidr=0.0.0.0/0
```

Add to GitHub Secrets:
1. Go to: `https://github.com/YOUR_ORG/YOUR_REPO/settings/secrets/actions`
2. Click "New repository secret"
3. Name: `NPM_TOKEN`
4. Value: Your token from above

## 📦 Publishing Workflows

### Automatic Publishing (CI/CD)

1. **Make changes** to your code
2. **Bump version** locally:
   ```bash
   npm version patch  # or minor/major
   ```
3. **Commit and push**:
   ```bash
   git add -A
   git commit -m "feat: amazing new feature"
   git push origin main
   ```
4. **GitHub Actions automatically**:
   - Validates package
   - Runs tests
   - Publishes to NPM
   - Creates GitHub release
   - Tags version

### Manual Publishing (Local)

1. **Make changes** to your code
2. **Use release script**:
   ```bash
   npm run release:minor  # Bumps version AND publishes
   ```
3. **Push to GitHub**:
   ```bash
   git push origin main --follow-tags
   ```

### Manual Publishing (GitHub UI)

1. **Push changes** to main branch
2. Go to **Actions** tab in GitHub
3. Select **"NPM Manual Release"** workflow
4. Click **"Run workflow"**
5. Choose version type (patch/minor/major)
6. Click **"Run workflow"** button

## 🔍 Validation Commands

### Test package build without publishing:
```bash
npm run validate:package  # Dry run
npm pack                  # Creates .tgz file
```

### Check what will be published:
```bash
npm pack --dry-run  # Shows files that will be included
```

### Test locally before publishing:
```bash
npm pack
npm install ./your-package-1.0.0.tgz
```

## ⚙️ Advanced Configuration

### Custom Pre-Push Validation

Edit `.husky/pre-push` to add custom checks:
```bash
# Add custom validation
if [ -f "custom-validate.sh" ]; then
  ./custom-validate.sh || exit 1
fi
```

### Exclude Files from Package

Add to `.npmignore`:
```
# Development files
*.test.js
*.spec.js
/tests
/docs
/.github
/.husky
```

### Scoped Package Settings

For `@yourorg/package` packages:
```json
{
  "publishConfig": {
    "access": "public",  // or "restricted" for private
    "registry": "https://registry.npmjs.org"
  }
}
```

## 🚨 Troubleshooting

### Pre-push hook not running
```bash
# Reinstall hooks
npx husky install
chmod +x .husky/pre-push
```

### GitHub Actions failing
Check:
1. NPM_TOKEN is set in GitHub Secrets
2. Token has publish permissions
3. Package name is available on NPM

### Version conflicts
```bash
# Reset to NPM version
npm view your-package version
# Update local package.json to match
```

## 🔒 Security Best Practices

1. **Never commit NPM tokens** - Use GitHub Secrets
2. **Use automation tokens** - Not your personal token
3. **Enable 2FA on NPM** - Required for publishing
4. **Review package contents** - Use `npm pack --dry-run`
5. **Test locally first** - Install .tgz before publishing

## 📊 Monitoring Releases

### GitHub Release Page
- Automatic changelog
- Download statistics
- Version history

### NPM Package Page
- Download counts
- Version history
- Dependency graph

### Notifications (Optional)
Add to workflow for Slack/Discord notifications:
```yaml
env:
  SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
```

## 🎯 Quick Reference

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `npm run validate:package` | Test build | Before committing |
| `npm version patch` | Bump patch version | Bug fixes |
| `npm version minor` | Bump minor version | New features |
| `npm version major` | Bump major version | Breaking changes |
| `npm run release:patch` | Bump + publish | Quick patch release |
| `git push --follow-tags` | Push with tags | After version bump |

## 📝 Example: Full Release Flow

```bash
# 1. Make your changes
edit src/index.js

# 2. Commit changes
git add -A
git commit -m "fix: resolve critical bug"

# 3. Bump version
npm version patch  # 1.0.0 → 1.0.1

# 4. Push (pre-push hook validates)
git push origin main --follow-tags

# 5. GitHub Actions publishes to NPM automatically
# 6. Check: https://www.npmjs.com/package/@yourorg/package
```

---

**Remember**: The framework handles the complexity. You just need to:
1. Write code
2. Bump version
3. Push to GitHub
4. Everything else is automated! 🚀