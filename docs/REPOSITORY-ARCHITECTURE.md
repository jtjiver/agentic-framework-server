# ASW Framework Repository Architecture

A comprehensive guide to understanding the ASW Framework's **Golden Source Submodule** architecture and why it's designed this way.

## 🏗️ Architecture Overview

The ASW Framework uses a **Golden Source Submodule** pattern where:

- **Main repository**: `agentic-framework-server` orchestrates everything
- **Each submodule**: Is its own independent GitHub repository (golden source)
- **Development workflow**: Changes flow from submodule → golden source → other projects

## 📊 Repository Structure

```
Main Repository: github.com/jtjiver/agentic-framework-server
├── 📁 /opt/asw/agentic-claude-config     ← github.com/jtjiver/agentic-claude-config
├── 📁 /opt/asw/agentic-framework-core    ← github.com/jtjiver/agentic-framework-core  
├── 📁 /opt/asw/agentic-framework-dev     ← github.com/jtjiver/agentic-framework-dev
├── 📁 /opt/asw/agentic-framework-infrastructure ← github.com/jtjiver/agentic-framework-infrastructure
└── 📁 /opt/asw/agentic-framework-security ← github.com/jtjiver/agentic-framework-security
```

### Repository Sizes & Complexity

| Submodule | Size | Purpose | Files |
|-----------|------|---------|-------|
| **agentic-claude-config** | 2.3MB | AI tooling configuration, slash commands | ~50 files |
| **agentic-framework-core** | 1.2MB | Shared utilities, logging, base libraries | ~40 files |
| **agentic-framework-dev** | 1.2MB | Development environment, project templates | ~35 files |
| **agentic-framework-infrastructure** | 1.1MB | Port management, nginx, deployment tools | ~45 files |
| **agentic-framework-security** | 900KB | 1Password integration, security scanning | ~30 files |

## 🎯 Why This Architecture?

### ✅ **Golden Source Submodules = Perfect for ASW**

1. **Independent Functionality**: Each submodule has substantial, distinct capabilities
2. **Cross-Project Reuse**: Claude configs, security tools, infrastructure utilities shared across all projects  
3. **Version Control**: Each component can evolve independently
4. **Team Collaboration**: Different specialists can own different submodules
5. **Deployment Flexibility**: Projects can choose which submodule versions to use

### ❌ **Alternative Patterns We Avoided**

**Monorepo**: Would be too large, hard to manage permissions
**Separate Repos Only**: Would lose orchestration and integrated setup
**Lightweight Submodules**: Would require separate golden source maintenance

## 🔄 Development Workflow

### The 3-Step Golden Source Pattern

```bash
# 1. Develop in the golden source submodule
cd /opt/asw/agentic-framework-core
# Make your changes...

# 2. Commit and push the golden source
git add .
git commit -m "Add new utility function"
git push origin main

# 3. Update the main repository pointer
cd /opt/asw
git add agentic-framework-core
git commit -m "Update core submodule with new utility"
git push origin master
```

### Why This Workflow?

1. **Golden source gets updated first** → ensures other projects can pull latest
2. **Main repo tracks specific commits** → ensures reproducible builds
3. **Other projects pull when ready** → controlled adoption of updates

## 🌐 Cross-Project Sharing

### How Other Projects Use These Golden Sources

```bash
# New project wants Claude configuration
git submodule add https://github.com/jtjiver/agentic-claude-config.git .claude

# Existing project wants latest security tools  
cd project-directory
git submodule update --remote agentic-framework-security

# Personal project wants infrastructure utilities
git submodule add https://github.com/jtjiver/agentic-framework-infrastructure.git infrastructure
```

### Real-World Example: Personal Projects

```
/opt/dev-containers/projects/personal/tennis-tracker/
├── .claude/                    ← FROM agentic-claude-config golden source
├── infrastructure/             ← FROM agentic-framework-infrastructure golden source  
├── security/                   ← FROM agentic-framework-security golden source
└── [project-specific files]
```

## 🏆 Benefits Achieved

### ✅ **For ASW Framework**
- **Centralized golden sources** for all shared components
- **Integrated setup** with single command (`complete-server-setup.sh`)
- **Comprehensive testing** across all components
- **Unified documentation** and user guide

### ✅ **For Other Projects**  
- **Pick and choose** which ASW components to include
- **Stay updated** by pulling from golden sources when ready
- **Inherit improvements** automatically (Claude configs, security updates)
- **Maintain independence** while benefiting from shared infrastructure

### ✅ **For Development**
- **Clear ownership** of each submodule
- **Independent versioning** and release cycles
- **Reduced duplication** across projects
- **Consistent tooling** and configurations

## 🔧 Technical Implementation Details

### Git Configuration

All submodules are configured with:
```bash
# Each submodule has proper git identity
user.name = "John Townsend"  
user.email = "jrtownsend@gmail.com"

# All submodules track their main branch
branch = main
remote = origin
```

### Security Integration

- **Main repo** handles comprehensive security scanning via Husky hooks
- **Submodules** remain lightweight - no duplicate security infrastructure  
- **TruffleHog scanning** covers all submodules through main repo integration

### Testing Integration

- **Docker testing environment** validates all submodules together
- **CI/CD workflows** test cross-submodule dependencies
- **Unified test reporting** across all components

## 📋 Maintenance Guidelines

### Adding New Submodules

1. **Create GitHub repository** with descriptive name (`agentic-framework-[purpose]`)
2. **Add as submodule** to main repo:
   ```bash
   git submodule add https://github.com/jtjiver/agentic-framework-newmodule.git agentic-framework-newmodule
   ```
3. **Configure git identity** in new submodule
4. **Update documentation** and setup scripts
5. **Add to testing framework**

### Updating Existing Submodules

1. **Work in submodule directory** (e.g., `/opt/asw/agentic-framework-core`)
2. **Test changes locally** using Docker testing framework
3. **Commit and push submodule** to its golden source repo
4. **Update main repo pointer** and commit
5. **Document breaking changes** in submodule's CHANGELOG.md

### Removing Submodules

1. **Remove submodule reference**: `git submodule deinit agentic-framework-oldmodule`
2. **Remove from .gitmodules**: Edit `.gitmodules` file
3. **Remove directory**: `rm -rf agentic-framework-oldmodule`
4. **Update setup scripts** and documentation
5. **Archive golden source repo** (don't delete - other projects might use it)

## 🔍 Troubleshooting Common Issues

### Detached HEAD State
```bash
# Fix: Checkout main branch in submodule
cd /opt/asw/agentic-framework-[name]
git checkout main
```

### Missing Git Configuration
```bash
# Fix: Set git identity in submodule
git -C agentic-framework-[name] config user.name "John Townsend"
git -C agentic-framework-[name] config user.email "jrtownsend@gmail.com"
```

### Submodule Not Updating
```bash
# Fix: Update submodule to latest
git submodule update --remote agentic-framework-[name]
```

### Permission Errors During Commit
```bash
# Fix: Ensure proper branch checkout
cd /opt/asw/agentic-framework-[name]
git checkout main
git pull origin main
# Then make your changes and commit
```

## 📈 Future Scalability

This architecture scales well for:

### ✅ **More Team Members**
- Each person can own specific submodules
- Clear boundaries reduce merge conflicts  
- Independent development cycles

### ✅ **More Projects**
- New projects easily adopt existing golden sources
- Shared improvements benefit entire ecosystem
- Reduced maintenance overhead

### ✅ **Enterprise Features**
- Access control per submodule repository
- Independent CI/CD pipelines if needed
- Gradual migration strategies

## 🎯 Comparison with Alternatives

| Aspect | Golden Source Submodules | Monorepo | Separate Repos |
|--------|-------------------------|----------|----------------|
| **Setup Complexity** | Medium | Low | High |
| **Cross-Project Sharing** | Excellent | Poor | Manual |
| **Version Management** | Excellent | Good | Complex |
| **Team Collaboration** | Excellent | Good | Poor |
| **CI/CD Integration** | Good | Excellent | Complex |
| **Maintenance Overhead** | Medium | Low | High |

## 🏁 Conclusion

The ASW Framework's **Golden Source Submodule** architecture provides the optimal balance of:

- **Integration** (comprehensive setup and testing)
- **Modularity** (independent golden source repositories)  
- **Reusability** (cross-project sharing of components)
- **Maintainability** (clear ownership and update workflows)

This architecture enables rapid development of new projects while maintaining consistency and quality across the entire ASW ecosystem.

---

**Last Updated**: September 2025  
**Architecture Version**: 1.0  
**Maintained By**: ASW Framework Team