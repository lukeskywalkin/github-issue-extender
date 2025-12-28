# GitHub Issue Extender

A **reusable** GitHub Actions workflow that uses AI to analyze and elaborate on issues by examining code, pull requests, and repository context. The workflow automatically comments on issues with detailed elaborations to help developers better understand and address them.

**Use it in any repository** by calling it as a reusable workflow - no need to copy files!

## Features

- 🤖 **AI-Powered Analysis**: Uses configurable AI providers (OpenAI, Anthropic) to analyze issues
- 📝 **Non-AI Mode**: Optional mode that formats existing issue/PR information without AI (no API keys needed!)
- 🔍 **Smart Context Gathering**: Analyzes issues, linked PRs, and relevant code files
- 💾 **Context Persistence**: Maintains repository overview between runs to avoid re-analyzing everything
- 🎯 **Duplicate Prevention**: Only processes issues that haven't been commented on by the bot
- 🔧 **Configurable**: Supports multiple AI providers and models, or run without AI
- 📊 **Size Management**: Enforces size limits on context files to prevent bloat

## How It Works

1. The workflow runs on a schedule (daily by default) or can be triggered manually
2. It fetches all open issues in the repository
3. For each issue that hasn't been processed yet:
   - Gathers issue details, linked pull requests, and relevant code files
   - Uses AI to generate a detailed elaboration based on repository context
   - Posts the elaboration as a comment on the issue
4. Maintains a context file with repository overview for efficient analysis

## Setup

### Option 1: Use as Reusable Workflow (Recommended)

This is the easiest way - just call the workflow from your repository!

1. **Create a workflow file** in your repository:

```yaml
# .github/workflows/issue-extender.yml
name: Issue Extender

on:
  schedule:
    # Run daily at midnight UTC
    - cron: '0 0 * * *'
  workflow_dispatch:  # Allow manual triggers

jobs:
  extend-issues:
    # Required permissions (automatically inherited from reusable workflow):
    # - contents: write  (to commit context file updates)
    # - issues: write    (to post comments on issues)
    # - pull-requests: read (to read PR information)
    uses: lukeskywalkin/github-issue-extender/.github/workflows/issue-extender.yml@main
    with:
      ai_provider: 'groq'  # or 'openai', 'anthropic'
      use_ai: 'true'       # or 'false' for non-AI mode
    secrets:
      ai_api_key: ${{ secrets.AI_API_KEY }}  # Only needed if use_ai=true
```

**Note on Permissions:** The reusable workflow automatically requests the necessary permissions:
- `contents: write` - to commit the context file back to the repository
- `issues: write` - to post comments on issues
- `pull-requests: read` - to read pull request information

No additional permission configuration is needed! The `GITHUB_TOKEN` will automatically have these permissions.

2. **Add the AI API key secret** (if using AI mode):
   - Go to your repository → Settings → Secrets and variables → Actions
   - Add secret: `AI_API_KEY` with your API key

That's it! The workflow will automatically use the scripts from this repository.

### Option 2: Copy Files Locally (Alternative)

If you prefer to have the scripts in your repository:

```bash
# From your repository root
mkdir -p .github/workflows
cp github-issue-extender/.github/workflows/issue-extender.yml .github/workflows/
cp -r github-issue-extender/scripts ./
```

**Important**: The scripts should be placed in the `scripts/` directory at the root of your repository.

### 2. Configure GitHub Secrets (Optional - only needed for AI mode)

**For AI Mode:** Add the following secret to your repository:

- **`AI_API_KEY`** (required for AI mode): Your API key for the AI provider (OpenAI or Anthropic)

**For Non-AI Mode:** No secrets needed! Just set `use_ai: false` when triggering the workflow.

You can add secrets in your repository settings: `Settings > Secrets and variables > Actions > New repository secret`

### 3. Configure Workflow (Optional)

Edit `.github/workflows/issue-extender.yml` to customize:

- **Schedule**: Change the cron expression in the `schedule` section (default: daily at midnight UTC)
- **AI Provider**: Set default provider in workflow inputs (default: `openai`)
- **AI Model**: Set default model (uses provider defaults if not specified)
- **Use AI Mode**: Set `use_ai: false` to use non-AI summary mode (no API keys needed)

### 4. Update Script Paths

If you copied the scripts to a different location, update the script paths in `analyze-issues.sh` and the workflow file.

## Configuration Options

### Environment Variables

- `AI_API_KEY` (required for AI mode): API key for AI provider
- `USE_AI` (optional, default: `true`): Set to `false` to use non-AI summary mode (no API keys needed)
- `AI_PROVIDER` (optional, default: `openai`): AI provider (`openai` or `anthropic`) - only used when `USE_AI=true`
- `AI_MODEL` (optional): Model name (uses provider defaults if not specified) - only used when `USE_AI=true`
- `CONTEXT_FILE` (optional, default: `.github/issue-extender-context.json`): Path to context file
- `CONTEXT_SIZE_LIMIT` (optional, default: `51200`): Maximum context file size in bytes (50KB)

### Workflow Inputs (Manual Trigger)

When triggering the workflow manually, you can specify:

- `ai_provider`: AI provider to use (`openai` or `anthropic`) - only used when `use_ai=true`
- `ai_model`: Specific model to use (optional) - only used when `use_ai=true`
- `use_ai`: Set to `false` to use non-AI summary mode (default: `true`)

## Supported AI Providers

### OpenAI

- Default model: `gpt-4o-mini`
- API endpoint: `https://api.openai.com/v1/chat/completions`
- Required secret: `AI_API_KEY` (OpenAI API key)
- Pricing: Pay-per-use

### Anthropic (Claude)

- Default model: `claude-3-5-sonnet-20241022`
- API endpoint: `https://api.anthropic.com/v1/messages`
- Required secret: `AI_API_KEY` (Anthropic API key)
- Pricing: Pay-per-use

### Groq (Fast Inference - Free Tier Available!)

- Default model: `llama-3.1-70b-versatile`
- API endpoint: `https://api.groq.com/openai/v1/chat/completions`
- Required secret: `AI_API_KEY` (Groq API key)
- **Free tier available!** Get API key at [console.groq.com](https://console.groq.com/)
- Pricing: Free tier with generous limits, pay-per-use after
- Note: Groq is very fast! Uses OpenAI-compatible API format

## Context File

The workflow maintains a context file (`.github/issue-extender-context.json`) that stores:

- **Repository Overview**: High-level summary of what the repository does
- **Important Files**: List of important files/functions with brief descriptions
- **Last Updated**: Timestamp of last update

This file is:
- Automatically committed back to the repository after updates
- Limited in size (default: 50KB) to prevent bloat
- Generated on first run and updated incrementally

### Example Context File

See `.github/issue-extender-context.json.example` for the structure.

## How to Use

### Automatic (Scheduled)

The workflow runs automatically on the schedule defined in the workflow file (default: daily at midnight UTC).

### Manual Trigger

1. Go to your repository on GitHub
2. Click on the "Actions" tab
3. Select "Issue Extender" workflow
4. Click "Run workflow"
5. Configure options:
   - Set `use_ai` to `false` for non-AI mode (no API keys needed!)
   - Or set `use_ai` to `true` and select AI provider/model (requires `AI_API_KEY` secret)
6. Click "Run workflow" button

### Non-AI Mode (No API Keys Needed!)

To use the tool without any AI/API keys:

1. When manually triggering: Set `use_ai` input to `false`
2. Or set the `USE_AI` environment variable to `false` in your workflow

Non-AI mode will:
- Extract and format information from linked PRs
- List relevant files and changes
- Summarize issue labels and metadata
- Provide structured context without AI analysis

This is perfect for testing or if you don't have API keys!

## How It Identifies Processed Issues

The workflow checks if the bot user (typically `github-actions[bot]` or `GITHUB_ACTOR`) has already commented on an issue. If a comment exists from the bot user, the issue is skipped.

## Requirements

- GitHub Actions enabled on your repository
- GitHub CLI (`gh`) available in the workflow environment (automatically installed)
- `jq` for JSON processing (available in GitHub Actions Ubuntu runner)
- Valid AI API key stored as a GitHub secret (only if using AI mode)

## Security

This reusable workflow uses `GITHUB_TOKEN` from the **calling repository**, which is secure because:

- **Automatically scoped**: Only has access to the repository where the workflow is called
- **Short-lived**: Expires immediately after the workflow completes
- **No secrets to manage**: Automatically available, no setup needed
- **Explicit permissions**: The workflow declares exactly what it needs (`contents: write`, `issues: write`, `pull-requests: read`)

**Important for Reusable Workflows:**
- The `GITHUB_TOKEN` used is from the **calling repository**, not the workflow repository
- This means the workflow can only access the repository that calls it
- This is the recommended approach for reusable workflows

For more details, see [SECURITY.md](docs/SECURITY.md).

**Note**: For production services or more complex scenarios, consider using GitHub Apps for enhanced security and audit trails.

## Troubleshooting

### Workflow fails with "Authentication failed"

- Check that `AI_API_KEY` secret is set correctly
- Verify the API key is valid for the selected provider

### Workflow fails with "Rate limit exceeded"

- The AI provider has rate limits. Wait and try again later
- Consider reducing the frequency of scheduled runs

### No comments are posted

- Check that the workflow has `issues: write` permission (configured in workflow file)
- Verify issues are open (not closed or in draft state)
- Check workflow logs for errors

### Context file grows too large

- The default limit is 50KB. Adjust `CONTEXT_SIZE_LIMIT` if needed
- The workflow automatically trims oldest entries if limit is exceeded

## Contributing

This is a standalone tool. To contribute:

1. Fork the repository
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## License

MIT License - see LICENSE file for details

## Example Output

When the workflow runs, it will post comments like this on issues:

```markdown
## 🤖 AI-Generated Issue Elaboration

Based on the repository context and the linked pull request #123, this issue is asking to bump dependency versions in the requirements file. The PR shows that dependencies in `requirements.txt` are being updated, including:
- Flask: 2.0.1 → 2.3.0
- Requests: 2.28.0 → 2.31.0
- SQLAlchemy: 1.4.0 → 2.0.0

This update addresses security vulnerabilities and brings in new features from these dependencies. The changes are backward compatible based on the version jumps.

---
*This elaboration was automatically generated by the Issue Extender workflow.*
```

