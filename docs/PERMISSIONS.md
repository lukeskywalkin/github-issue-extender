# Required Permissions

The GitHub Issue Extender workflow requires the following permissions to function:

## Permissions Breakdown

The workflow declares these permissions in the reusable workflow file:

```yaml
permissions:
  issues: write      # Required to post comments on issues and store context
  pull-requests: read # Required to read pull request information
```

### issues: write

**Why it's needed:**
- The workflow posts comments on issues with AI-generated elaborations
- The workflow stores repository context in a special issue (labeled `issue-extender-context`)
- This is the core functionality of the tool

**What it allows:**
- Create, update, and comment on issues
- Read issue details and comments
- Store the repository overview in an issue body (instead of committing files)

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
- Only `issues: write` is granted (can comment and update issues, but limited to issues)
- Only `pull-requests: read` is granted (read-only, cannot modify PRs)
- **No `contents: write`** - The workflow does not need to commit files to the repository!

The workflow cannot:
- Delete files or branches
- Modify pull requests
- Commit or push code
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
      issues: write
      pull-requests: read
    uses: lukeskywalkin/github-issue-extender/.github/workflows/issue-extender.yml@main
    # ... rest of config
```

However, this is usually unnecessary as the reusable workflow already declares the correct permissions.

## Context Storage

The workflow stores repository context in a special GitHub issue instead of committing a file. This issue:
- Has the label `issue-extender-context`
- Title: "Issue Extender Context"
- Stores the JSON context in the issue body (in a code block)
- Is automatically created on first run
- Is automatically updated when the repository overview changes

This approach eliminates the need for `contents: write` permission, making the workflow more secure!

