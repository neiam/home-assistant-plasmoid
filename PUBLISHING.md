# Publishing & Development Automation

This repository includes automated workflows for packaging and releasing the Home Assistant plasmoid to the KDE Store.

## 🚀 Automated Release Process

### Creating a Release

**Method 1: Git Tags (Recommended)**
```bash
git tag v2.1
git push origin v2.1
```

**Method 2: Manual Trigger**
1. Go to repository Actions tab on GitHub
2. Select "Create Plasmoid Release" 
3. Click "Run workflow"
4. Enter version number
5. Click "Run workflow"

### What Happens Automatically

1. ✅ **Package Creation**: Creates `.tar.gz` and `.zip` files
2. ✅ **Version Update**: Updates `metadata.json` with new version
3. ✅ **GitHub Release**: Creates release with download links
4. ✅ **Upload Instructions**: Provides step-by-step KDE Store guide

## 🏪 Publishing to KDE Store

After automation completes:

1. **Download** the `.tar.gz` file from GitHub release
2. **Login** to [store.kde.org](https://store.kde.org)
3. **Navigate** to your plasmoid page
4. **Add new version** and upload the package
5. **Publish** the update

## 🧪 Local Development

### Local Packaging
```bash
# Create development package
./package.sh

# Create specific version
./package.sh 2.1
```

### Testing Installation
```bash
# Install locally for testing
kpackagetool6 --type Plasma/Applet --install home-assistant-plasmoid-2.0.tar.gz

# Remove after testing
kpackagetool6 --type Plasma/Applet --remove org.neiam.kde.homeassistant
```

## 🔧 Workflow Configuration

### Repository Setup

The workflows require GitHub repository permissions:

1. Go to **Settings** → **Actions** → **General**
2. Under "Workflow permissions":
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"
3. Click **Save**

### Available Workflows

1. **Release Workflow** (`.github/workflows/release.yml`)
   - Triggers: Git tags starting with `v`
   - Creates packages and GitHub releases
   - Provides KDE Store upload instructions

2. **Validation Workflow** (`.github/workflows/validate.yml`)
   - Triggers: Push to main branches, PRs
   - Validates plasmoid structure and metadata
   - Checks QML syntax and package integrity

## 📋 Best Practices

### Version Management
- Use semantic versioning: `v1.0.0`, `v1.1.0`, `v2.0.0`
- Update version in `metadata.json` before tagging
- Write meaningful commit messages for changelog

### Pre-Release Checklist
- [ ] Test plasmoid functionality locally
- [ ] Update README with new features
- [ ] Verify metadata.json version
- [ ] Run `./package.sh` to test packaging
- [ ] Check QML syntax and structure

### Release Process
1. **Development**: Make changes and test locally
2. **Commit**: Push changes to main branch
3. **Validation**: Ensure validation workflow passes
4. **Tag**: Create version tag to trigger release
5. **Upload**: Download package and upload to KDE Store

## 🐛 Troubleshooting

### GitHub Actions Issues

**403 Permission Error:**
- Update repository workflow permissions (see above)
- Ensure workflows have `permissions: contents: write`

**Package Creation Fails:**
- Check required files exist (`metadata.json`, `contents/ui/main.qml`)
- Verify JSON syntax in metadata.json
- Review workflow logs for specific errors

**Release Creation Fails:**
- Verify tag format starts with `v` (e.g., `v2.0`)
- Check repository permissions
- Ensure no existing release with same tag

### Local Packaging Issues

**Script Fails:**
- Ensure `rsync` is installed
- Check file permissions (`chmod +x package.sh`)
- Verify no syntax errors in script

**Package Too Large:**
- Review included files (check `.gitignore`)
- Remove unnecessary development files
- Optimize images and assets

### KDE Store Upload Issues

**Wrong Package Format:**
- Use `.tar.gz` file, not `.zip`
- Ensure proper directory structure inside package

**Version Conflicts:**
- Ensure version number is unique
- Match version in `metadata.json` and store

**Metadata Issues:**
- Validate JSON syntax
- Ensure all required KPlugin fields present
- Check icon and category specifications

## 📖 Additional Resources

- [KDE Store Documentation](https://store.kde.org)
- [Plasma Applet Development Guide](https://develop.kde.org/docs/plasma/applets/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [KDE Community Resources](https://community.kde.org)

## 🔄 Future Enhancements

The automation system can be extended with:
- Automated changelog generation from commits
- Integration testing in different Plasma versions
- Automated screenshots for store listings
- Multi-platform package generation
- Automated dependency checking
