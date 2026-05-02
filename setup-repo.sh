#!/usr/bin/env bash
set -euo pipefail

# Configuration
REPO_NAME="lobehub-flatpak"
DEFAULT_BRANCH="main"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[-]${NC} $1"; exit 1; }

# 1. Install gh CLI if missing
if ! command -v gh &>/dev/null; then
    log "Installing GitHub CLI (gh)..."
    if command -v brew &>/dev/null; then
        brew install gh
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y gh
    elif command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y gh
    else
        error "No supported package manager found. Install gh manually: https://cli.github.com"
    fi
fi

# 2. Check authentication
if ! gh auth status &>/dev/null; then
    warn "Not authenticated with GitHub."
    log "Running: gh auth login"
    gh auth login --web
fi

USERNAME=$(gh api user -q '.login')
log "Authenticated as: $USERNAME"

# 3. Create the repository
if gh repo view "$USERNAME/$REPO_NAME" &>/dev/null; then
    warn "Repository $USERNAME/$REPO_NAME already exists."
    read -rp "Continue and push to existing repo? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
else
    log "Creating GitHub repository: $REPO_NAME"
    gh repo create "$REPO_NAME" \
        --public \
        --description "Self-hosted Flatpak repo for LobeHub with auto-updates" \
        --source=. \
        --remote=origin \
        --push
    log "Repository created: https://github.com/$USERNAME/$REPO_NAME"
fi

# 4. Ensure remote is set and push
if ! git remote get-url origin &>/dev/null; then
    log "Adding remote origin..."
    git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git"
fi

# Set branch name if needed
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
    git branch -m "$DEFAULT_BRANCH"
fi

log "Pushing to $DEFAULT_BRANCH..."
git push -u origin "$DEFAULT_BRANCH" --force

# 5. Enable GitHub Pages (GitHub Actions source)
log "Enabling GitHub Pages with GitHub Actions source..."
gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/$USERNAME/$REPO_NAME/pages" \
    -f source='{"branch":"main","path":"/"}' \
    --silent 2>/dev/null || warn "Pages API call failed — you may need to enable manually in Settings → Pages"

# Alternative: use Pages API v2 if the above fails
# gh api --method POST "/repos/$USERNAME/$REPO_NAME/pages" -f build_type="workflow" --silent 2>/dev/null || true

# 6. Set repository settings for Actions
log "Configuring repository settings..."
gh repo edit "$USERNAME/$REPO_NAME" \
    --enable-wiki=false \
    --enable-projects=false \
    --enable-discussions=false \
    --enable-issues=true 2>/dev/null || true

# 7. Trigger first workflow run
log "Triggering first workflow run..."
gh workflow run build.yml --repo "$USERNAME/$REPO_NAME" 2>/dev/null || warn "Could not trigger workflow — it may start automatically on push"

# 8. Wait and show Pages URL
PAGES_URL="https://$USERNAME.github.io/$REPO_NAME/repo.flatpakrepo"
REPO_URL="https://github.com/$USERNAME/$REPO_NAME"

echo ""
echo "========================================"
echo "  ✅ Setup complete!"
echo "========================================"
echo ""
echo "Repository:  $REPO_URL"
echo "Pages URL:   $PAGES_URL"
echo ""
echo "Install on your machine:"
echo "  flatpak remote-add lobehub $PAGES_URL"
echo "  flatpak install lobehub com.lobehub.LobeHub"
echo ""
echo "Check Actions status:"
echo "  gh run list --repo $USERNAME/$REPO_NAME"
echo ""
