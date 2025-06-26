# GitHub Actions for KDE Store Publishing

This repository includes GitHub Actions workflows to automate the packaging and release process for your plasmoid, making it easier to publish to the KDE Store.

## 🚀 Workflows

### 1. Release Workflow (`.github/workflows/release.yml`)

Automatically creates releases with packaged plasmoid files ready for KDE Store upload.

**Triggers:**
- **Git Tags:** Push a tag starting with `v` (e.g., `v2.1`, `v3.0`)
- **Manual:** Use GitHub's "Actions" tab to manually trigger with custom version

**What it does:**
- Updates `metadata.json` with the new version number
- Creates properly packaged `.tar.gz` and `.zip` files
- Creates a GitHub release with download links
- Provides step-by-step instructions for KDE Store upload

### 2. Validation Workflow (`.github/workflows/validate.yml`)

Validates your plasmoid structure and catches issues early.

**Triggers:**
- Push to main/master/develop branches
- Pull requests

**What it checks:**
- Required files exist (`metadata.json`, `contents/ui/main.qml`)
- `metadata.json` is valid JSON with required fields
- QML syntax (basic check)
- Package size and structure

## 📦 How to Create a Release

### Method 1: Git Tags (Recommended)

```bash
# Create and push a new tag
git tag v2.1
git push origin v2.1
```

The workflow will automatically:
1. Create packages for version 2.1
2. Update metadata.json
3. Create a GitHub release
4. Provide KDE Store upload instructions

### Method 2: Manual Trigger

1. Go to your repository on GitHub
2. Click "Actions" tab
3. Select "Create Plasmoid Release"
4. Click "Run workflow"
5. Enter the version number (e.g., `2.1`)
6. Click "Run workflow"

## 🏪 Publishing to KDE Store

After the GitHub Action completes:

1. **Download the package:** Go to the created GitHub release and download the `.tar.gz` file
2. **Login to KDE Store:** Go to [store.kde.org](https://store.kde.org) and login
3. **Navigate to your plasmoid:** Find your existing plasmoid page
4. **Add new version:** Click "Add Version" or similar button
5. **Upload package:** Upload the downloaded `.tar.gz` file
6. **Update details:** Add changelog, update version number
7. **Publish:** Submit for review/publish

## 🧪 Local Testing

Use the included `package.sh` script to test packaging locally:

```bash
# Create a development package
./package.sh

# Create a specific version package
./package.sh 2.1
```

This creates the same packages that the GitHub Action would create.

## 🔧 Configuration

### Required Repository Settings

No special configuration required! The workflows use the default `GITHUB_TOKEN` which is automatically available.

### Optional Customizations

You can customize the workflows by editing:

- **Package name:** Change `home-assistant-plasmoid` in `release.yml`
- **Excluded files:** Modify the `--exclude` patterns in both workflows
- **Release notes:** Edit the template in `release.yml`

### Version Management

The workflow automatically:
- Extracts version from git tags (removes `v` prefix)
- Updates `metadata.json` with the new version
- Uses the version in package filenames

## 📋 Best Practices

1. **Use semantic versioning:** `v1.0.0`, `v1.1.0`, `v2.0.0`
2. **Test locally first:** Use `./package.sh` before creating releases
3. **Write good commit messages:** They may be used in release notes
4. **Update README:** Keep installation instructions current
5. **Tag releases:** Always use git tags for version releases

## 🐛 Troubleshooting

### Workflow Fails

Check the Actions tab for detailed logs. Common issues:

- **Missing files:** Ensure `metadata.json` and `contents/ui/main.qml` exist
- **Invalid JSON:** Validate `metadata.json` syntax
- **Permission issues:** Usually resolve themselves, try re-running

### Package Issues

- **Too large:** Check for unnecessary files (logs, cache, etc.)
- **Missing files:** Verify your `.gitignore` isn't excluding needed files
- **Wrong structure:** Ensure the standard plasmoid directory structure

### KDE Store Upload Issues

- **Wrong format:** Use the `.tar.gz` file, not `.zip`
- **Version conflicts:** Ensure the version number is unique
- **Metadata mismatch:** Version in `metadata.json` should match store version

## 🔄 Alternative: Fully Automated Publishing

**Note:** The KDE Store doesn't provide an official API for automated publishing. However, there are experimental approaches:

### Web Scraping Approach (Advanced)

```yaml
# This is experimental and not recommended for production
- name: Auto-upload to KDE Store (EXPERIMENTAL)
  run: |
    # Would require:
    # - Storing KDE credentials securely
    # - Web scraping/automation tools
    # - Handling CSRF tokens and cookies
    # - High maintenance due to website changes
    echo "⚠️ Fully automated upload not implemented"
    echo "Manual upload to KDE Store still required"
```

### Why We Don't Recommend Full Automation

1. **No official API:** KDE Store lacks automation-friendly APIs
2. **Security concerns:** Storing credentials for web scraping
3. **Fragility:** Website changes break automation
4. **Terms of service:** May violate automated access policies

The semi-automated approach (package creation + manual upload) provides the best balance of automation and reliability.

## 📞 Support

If you encounter issues:

1. Check the GitHub Actions logs in your repository
2. Validate your plasmoid structure locally with `./package.sh`
3. Refer to [KDE Store documentation](https://store.kde.org)
4. Check [KDE Community resources](https://community.kde.org)
