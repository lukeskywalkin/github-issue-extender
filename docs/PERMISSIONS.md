# Required Permissions

The GitHub Issue Extender workflow requires the following permissions to function:

## Permissions Breakdown

The workflow declares these permissions in the reusable workflow file:

```yaml
permissions:
  contents: write    # Required to commit context file updates
  issues: write      # Required to post comments on issues
  pull-requests: read # Required to read pull request information
```

### contents: write

**Why it's needed:**
- The workflow commits the context file (`.github/issue-extender-context.json`) back to the repository
- This file stores the repository overview and is updated periodically

**What it allows:**
- Write access to repository contents
- Ability to create commits and push to the repository

### issues: write

**Why it's needed:**
- The workflow posts comments on issues with AI-generated elaborations
- This is the core functionality of the tool

**What it allows:**
- Create, update, and comment on issues
- Read issue details and comments

### pull-requests: read

**Why it's needed:**
- The workflow reads pull request information linked to issues
- Extracts changed files, descriptions, and metadata from PRs

**What it allows:**
- Read pull request details
- Read pull request files and changes
- Does NOT allow modifying PRs (read-only)

## How Permissions Work in Reusable Workflows

When you call this workflow as a reusable workflow, the permissions are automatically inherited. You don't need to explicitly grant them - the `GITHUB_TOKEN` will automatically have these permissions when the workflow runs.

The permissions are declared in the reusable workflow file itself, so GitHub Actions automatically grants them when the workflow is called.

## Security Considerations

These permissions follow the **principle of least privilege**:
- Only `contents: write` is granted (not full repo access)
- Only `issues: write` is granted (can comment, but limited to issues)
- Only `pull-requests: read` is granted (read-only, cannot modify PRs)

The workflow cannot:
- Delete files or branches
- Modify pull requests
- Access other repositories
- Perform administrative actions

## Verifying Permissions

If you encounter permission errors, check:

1. **Repository Settings**: Ensure GitHub Actions is enabled
2. **Workflow File**: Make sure the reusable workflow call is correct
3. **GITHUB_TOKEN**: Should be automatically available (no setup needed)

## Custom Permissions (Advanced)

If you want to override the permissions (not recommended), you can specify them in the calling workflow:

```yaml
jobs:
  extend-issues:
    permissions:
      contents: write
      issues: write
      pull-requests: read
    uses: lukeskywalkin/github-issue-extender/.github/workflows/issue-extender.yml@main
    # ... rest of config
```

However, this is usually unnecessary as the reusable workflow already declares the correct permissions.

