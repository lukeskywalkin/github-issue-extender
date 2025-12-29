# Using a Personal Access Token (PAT)

By default, the workflow uses the automatically provided `GITHUB_TOKEN`. However, you can optionally use a fine-grained Personal Access Token (PAT) instead for more control over permissions.

## When to Use a PAT

Consider using a PAT if:
- You want more granular control over permissions
- You need specific permissions not available in `GITHUB_TOKEN`
- You want to use a token with custom expiration and scoping
- You're using the workflow in an organization with restricted `GITHUB_TOKEN` permissions

## Creating a Fine-Grained PAT

1. **Go to GitHub Settings:**
   - Visit https://github.com/settings/tokens
   - Click "Fine-grained tokens" → "Generate new token"

2. **Configure the Token:**
   - **Token name**: Something like "GitHub Issue Extender"
   - **Expiration**: Choose your preferred expiration (or no expiration)
   - **Repository access**: 
     - Select "Only select repositories" and choose the repository where you'll use the workflow
     - Or "All repositories" if you want to use it across multiple repos

3. **Set Permissions:**
   
   Required permissions:
   - **Repository permissions:**
     - **Issues**: Read and write (to post comments and manage context issue)
     - **Pull requests**: Read (to read PR information)
   
   Optional permissions (not needed for this workflow):
   - **Contents**: Not needed (workflow uses issues for context storage)
   - **Metadata**: Read (automatically granted)

4. **Generate and Copy:**
   - Click "Generate token"
   - **Copy the token immediately** - you won't be able to see it again!

## Adding PAT to Repository Secrets

### For Direct Use (In This Repository)

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Name: `GH_PAT` (or any name you prefer - **cannot start with GITHUB_**)
5. Value: Paste your PAT
6. Click **"Add secret"**

Then update the workflow file to use it:
```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GH_PAT }}
```

**Important:** Secret names cannot start with `GITHUB_`. Use names like `GH_PAT`, `PAT_TOKEN`, or `GH_TOKEN` instead.

### For Reusable Workflow (Calling from Other Repositories)

If you're calling this workflow from another repository:

1. **Add PAT as a secret in the calling repository:**
   - Go to the repository where you'll call the workflow
   - Settings → Secrets and variables → Actions
   - Add secret: `GH_PAT` (or any name - **cannot start with GITHUB_**)

2. **Pass it to the reusable workflow:**
```yaml
jobs:
  extend-issues:
    uses: lukeskywalkin/github-issue-extender/.github/workflows/issue-extender.yml@main
    with:
      ai_provider: 'groq'
      use_ai: 'true'
    secrets:
      ai_api_key: ${{ secrets.AI_API_KEY }}
      github_token: ${{ secrets.GH_PAT }}  # Optional: Use PAT instead of GITHUB_TOKEN
```

**Note:** GitHub doesn't allow secret names starting with `GITHUB_`. Use names like `GH_PAT`, `PAT_TOKEN`, or `GH_TOKEN`.

**Note:** If you don't provide `github_token`, the workflow will use the default `GITHUB_TOKEN` automatically.

## Security Best Practices

1. **Use Fine-Grained Tokens**: More secure than classic tokens
2. **Minimal Permissions**: Only grant what's needed (Issues: read/write, Pull requests: read)
3. **Repository Scoping**: Limit to specific repositories when possible
4. **Expiration**: Set reasonable expiration dates
5. **Rotate Regularly**: Update tokens periodically
6. **Don't Commit Tokens**: Never commit tokens to code - always use secrets

## Permissions Summary

The workflow needs these permissions:
- ✅ **Issues**: Read and Write
- ✅ **Pull requests**: Read
- ❌ **Contents**: Not needed (context is stored in an issue)
- ❌ **Metadata**: Automatically granted (read-only)

## Troubleshooting

**"Resource not accessible by integration" error:**
- Check that your PAT has the correct permissions
- Ensure the token hasn't expired
- Verify the token has access to the repository

**"Bad credentials" error:**
- Verify the secret name is correct
- Check that the token hasn't been revoked
- Ensure you're using a fine-grained token (not classic)

**Token works in direct use but not in reusable workflow:**
- Make sure you're passing the token via the `secrets.github_token` parameter
- Verify the secret exists in the calling repository
- Check that the reusable workflow is configured to accept the `github_token` secret

