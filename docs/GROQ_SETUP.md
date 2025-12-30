# Setting Up Groq Free Tier

Groq offers a fast inference API with a generous free tier, perfect for testing the GitHub Issue Extender!

## Step 1: Create a Groq Account

1. Visit [console.groq.com](https://console.groq.com/)
2. Sign up for a free account using:
   - Your email address, or
   - Sign in with Google/GitHub
3. Verify your email if required

## Step 2: Generate an API Key

1. After logging in, you'll see the Groq Console dashboard
2. Navigate to **API Keys** section (usually in the left sidebar or top menu)
3. Click **"Create API Key"** or **"Generate New Key"**
4. Give it a name (e.g., "GitHub Issue Extender")
5. Copy the API key immediately - **you won't be able to see it again!**

## Step 3: Add API Key to GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Name: `AI_API_KEY`
5. Value: Paste your Groq API key
6. Click **"Add secret"**

## Step 4: Configure the Workflow

When running the workflow, set the provider to `groq`:

**Option 1: Manual Trigger**
- Go to **Actions** → **Issue Extender** → **Run workflow**
- Set `ai_provider` to `groq`
- Set `ai_model` (optional) - defaults to `llama-3.1-70b-versatile`
- Click **Run workflow**

**Option 2: Edit Workflow File**
- Edit `.github/workflows/issue-extender.yml`
- Change the default `ai_provider` from `openai` to `groq`
- Or set it via environment variable: `AI_PROVIDER: groq`

## Available Models

Groq supports various models. You can set `ai_model` to:

- `llama-3.1-70b-versatile` (default) - Best overall performance
- `llama-3.1-8b-instant` - Faster, smaller model
- `mixtral-8x7b-32768` - Alternative high-quality model
- `gemma-7b-it` - Google's Gemma model

Check [Groq's documentation](https://console.groq.com/docs/models) for the latest available models.

## Free Tier Limits

Groq's free tier typically includes:
- Generous rate limits (check current limits in your dashboard)
- Fast inference speeds
- Access to multiple models

Limits may vary, so check your dashboard at [console.groq.com](https://console.groq.com/) for current details.

## Testing

To test your setup:

1. Make sure `AI_API_KEY` secret is set in your repository
2. Trigger the workflow manually with `ai_provider: groq`
3. Check the workflow logs to see if it's working
4. The bot should comment on issues with AI-generated elaborations

## Troubleshooting

**Error: Authentication failed**
- Double-check your API key is correct in GitHub Secrets
- Make sure the secret name is exactly `AI_API_KEY`

**Error: Rate limit exceeded**
- You've hit the free tier limits
- Wait a bit and try again, or check your dashboard for limit details

**Error: Model not found**
- The model name might be incorrect
- Try using the default model: `llama-3.1-70b-versatile`
- Check [Groq's model documentation](https://console.groq.com/docs/models) for current models

## Advantages of Groq

- ✅ **Free tier available** - Great for testing
- ✅ **Very fast** - One of the fastest inference APIs
- ✅ **OpenAI-compatible** - Uses the same API format as OpenAI
- ✅ **Multiple models** - Access to various open-source models

Enjoy using Groq with your GitHub Issue Extender!


