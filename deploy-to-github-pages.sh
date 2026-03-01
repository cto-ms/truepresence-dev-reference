#!/bin/bash
# Deploy TruePresence Developer Reference to GitHub Pages
# Run from: ~/Projects/DailySpotlight/developer-site/
set -e

REPO_NAME="truepresence-dev-reference"

echo "🚀 Deploying TruePresence Developer Reference to GitHub Pages"
echo ""

# Check for gh CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Install with: brew install gh"
    exit 1
fi

# Check auth
if ! gh auth status &> /dev/null 2>&1; then
    echo "🔑 Not logged in to GitHub. Running gh auth login..."
    gh auth login
fi

# Get current directory
SITE_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "📁 Site directory: $SITE_DIR"
echo "📄 Files to deploy: $(ls "$SITE_DIR"/*.html | wc -l | tr -d ' ') HTML pages"
echo ""

# Check if repo already exists
if gh repo view "$REPO_NAME" &> /dev/null 2>&1; then
    echo "✅ Repo '$REPO_NAME' already exists"
else
    echo "📦 Creating GitHub repository: $REPO_NAME"
    gh repo create "$REPO_NAME" --public --description "TruePresence Virtue Dataset — Developer Reference (Divine Mercy University)"
    echo "✅ Repo created"
fi

# Initialize git in the developer-site directory
cd "$SITE_DIR"

if [ ! -d .git ]; then
    git init
    git branch -M main
fi

# Get the repo URL
REPO_URL=$(gh repo view "$REPO_NAME" --json url -q .url)
echo "🔗 Repo: $REPO_URL"

# Set remote
if git remote get-url origin &> /dev/null 2>&1; then
    git remote set-url origin "https://github.com/$(gh api user -q .login)/$REPO_NAME.git"
else
    git remote add origin "https://github.com/$(gh api user -q .login)/$REPO_NAME.git"
fi

# Add all files and commit
git add -A
git commit -m "Deploy TruePresence developer reference site

58 static HTML pages covering 56 Aquinas virtues with:
- Sanity CMS field references and studio links
- Story mappings across 4 genres (223 stories)
- Public domain image-to-story mapping page (551 images)
- Therapeutic approach data
- Perspective content for 6 audience gates"

# Push to main
git push -u origin main

# Enable GitHub Pages via gh CLI
echo ""
echo "🌐 Enabling GitHub Pages on main branch..."
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  "/repos/$(gh api user -q .login)/$REPO_NAME/pages" \
  -f "source[branch]=main" \
  -f "source[path]=/" 2>/dev/null || \
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$(gh api user -q .login)/$REPO_NAME/pages" \
  -f "source[branch]=main" \
  -f "source[path]=/" 2>/dev/null || \
echo "⚠️  Could not auto-enable Pages. Enable manually at: $REPO_URL/settings/pages"

# Get the pages URL
GH_USER=$(gh api user -q .login)
PAGES_URL="https://${GH_USER}.github.io/${REPO_NAME}/"

echo ""
echo "✅ Done! Your site will be live at:"
echo "   $PAGES_URL"
echo ""
echo "   It may take 1-2 minutes for GitHub to build and deploy."
echo "   Check status at: $REPO_URL/actions"
