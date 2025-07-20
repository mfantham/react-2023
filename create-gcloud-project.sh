#!/bin/bash

set -e  # Exit on any error

echo "🚀 Setting up GCP project from package.json..."

# Read project ID from package.json
PROJECT_ID=$(node -p "require('./package.json').gcp.projectId" 2>/dev/null || {
  echo "❌ Error: Could not read gcp.projectId from package.json"
  echo "Make sure package.json exists and has a gcp.projectId field"
  exit 1
})

# Validate project ID is not the default placeholder
if [ "$PROJECT_ID" = "your-project-id" ]; then
  echo "❌ Error: Please update the projectId in package.json"
  echo "Current value: $PROJECT_ID"
  echo "Change 'your-project-id' to your actual GCP project ID"
  exit 1
fi

echo "✅ Using project ID: $PROJECT_ID"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
  echo "❌ Error: gcloud CLI is not installed"
  echo "Install it from: https://cloud.google.com/sdk/docs/install"
  exit 1
fi

# Check if gh is installed
if ! command -v gh &> /dev/null; then
  echo "❌ Error: GitHub CLI is not installed"
  echo "Install it from: https://cli.github.com/"
  exit 1
fi

echo "🔑 Authenticating Google Cloud CLI"
echo "This will open a browser window to authenticate..."
gcloud auth login

echo "🔑 Authenticating GitHub CLI"
echo "This will authenticate with GitHub for managing secrets..."
gh auth login

echo "📦 Creating GCP project: $PROJECT_ID"
if gcloud projects describe $PROJECT_ID &>/dev/null; then
    echo "✅ Project $PROJECT_ID already exists, skipping creation"
else
    gcloud projects create $PROJECT_ID
    echo "✅ Project $PROJECT_ID created successfully"
fi

echo "🔧 Setting active project"
gcloud config set project $PROJECT_ID

echo "⚠️  IMPORTANT: App Engine requires billing to be enabled"
echo "📋 Please follow these steps:"
echo "   1. Go to: https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
echo "   2. Link a billing account to your project"
echo "   3. Note: You can stay within the free tier limits to avoid charges"
echo "   4. Press Enter when billing is enabled to continue..."
read -p "Press Enter to continue after enabling billing..."

echo "🔌 Enabling required APIs"
gcloud services enable appengine.googleapis.com
echo "✅ App Engine API enabled"

echo "🏗️  Creating App Engine app"
echo "You'll be prompted to choose a region. Choose one close to your users."
if gcloud app describe &>/dev/null; then
    echo "✅ App Engine app already exists, skipping creation"
else
    gcloud app create
    echo "✅ App Engine app created successfully"
fi

echo "👤 Creating service account"
SERVICE_ACCOUNT_NAME="github-actions"
SERVICE_ACCOUNT_EMAIL="$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"

if gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL &>/dev/null; then
    echo "✅ Service account already exists, skipping creation"
else
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --display-name="GitHub Actions Service Account" \
        --description="Service account for GitHub Actions deployments"
    echo "✅ Service account created"
fi

echo "🔐 Assigning IAM roles"
for ROLE in \
  roles/appengine.deployer \
  roles/appengine.serviceAdmin \
  roles/cloudbuild.builds.editor \
  roles/storage.objectAdmin \
  roles/iam.serviceAccountUser \
  roles/iam.serviceAccountTokenCreator; do
    gcloud projects add-iam-policy-binding $PROJECT_ID \
      --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
      --role="$ROLE"
done
echo "✅ IAM roles assigned"

echo "🔑 Creating service account key"
KEY_FILE="gcp-key.json"
if [ -f "$KEY_FILE" ]; then
    echo "⚠️  Key file already exists, removing old key..."
    rm "$KEY_FILE"
fi

gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$SERVICE_ACCOUNT_EMAIL

echo "📤 Adding key to GitHub secrets"
# Get the repository name from git remote
REPO_URL=$(git remote get-url origin)
if [[ $REPO_URL == *"github.com"* ]]; then
    # Extract owner/repo from GitHub URL
    REPO_PATH=$(echo $REPO_URL | sed 's/.*github.com[:/]\([^/]*\/[^/]*\)\.git.*/\1/')
    
    # Add the secret to GitHub
    gh secret set GCP_SA_KEY --body="$(cat $KEY_FILE)" --repo="$REPO_PATH"
    echo "✅ GCP_SA_KEY secret added to GitHub repository"
else
    echo "⚠️  Could not detect GitHub repository. Please manually add the following as GCP_SA_KEY secret:"
    echo "$(cat $KEY_FILE)"
fi

echo "🧹 Cleaning up key file"
rm "$KEY_FILE"

echo ""
echo "🎉 Setup complete!"
echo "📋 Summary:"
echo "   • Project: $PROJECT_ID"
echo "   • App Engine: Enabled (requires billing)"
echo "   • Service Account: $SERVICE_ACCOUNT_EMAIL"
echo "   • GitHub Secret: GCP_SA_KEY (added)"
echo ""
echo "🚀 You can now deploy using: git push origin main"
echo ""
echo "💡 Free tier limits:"
echo "   • 28 hours/day of F1 instances (frontend)"
echo "   • 9 hours/day of B1 instances (backend)"  
echo "   • 1 GB/day outbound data transfer"
echo "   • More info: https://cloud.google.com/appengine/pricing" 