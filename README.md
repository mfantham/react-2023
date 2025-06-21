# react-2023

> A template for building deployable React projects
> Updated 2025

This template includes:

- TypeScript
- React
- Parcel (bundler)
- Prettier (formatting)
- Jest (testing)
- GitHub Actions (CI/CD)

Uses Yarn for package management.

## Getting Started

**Option 1: GitHub UI**

1. Click "Use this template" → "Create a new repository"
2. Choose your repository name and settings
3. Clone your new repository

**Option 2: GitHub CLI**

```bash
gh repo create my-new-project --template mfantham/react-2023 --clone
cd my-new-project
```

## IDE support

If you're using a VSCode-based editor, eg Cursor, install the
[esbenp.prettier-vscode](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
extension to have `prettier` run on save.

## Tests

A Github Action will automatically run any tests on pull requests or merges to main. Run `yarn test` to develop tests locally.

## Deploy

A GitHub Action is included to build and deploy the repository as a Google
Cloud App Engine site.

### Setup:

1. Create a gCloud project
2. Update the project name in `package.json` → `gcp.projectId`
3. Create a service account and add the key as a repository secret named `GCP_SA_KEY`:
   ```bash
   gh secret set GCP_SA_KEY --body "$(cat path/to/your-service-account-key.json)"
   ```

### Deploy:

Go to Actions → Deploy → Run workflow (manual trigger)
