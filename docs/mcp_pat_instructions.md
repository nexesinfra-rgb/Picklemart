# Supabase MCP Configuration - Personal Access Token Setup

## Current Configuration

I've updated `.cursor/mcp.json` to use Supabase's **hosted MCP server** which uses OAuth authentication (no PAT needed). This is the recommended approach.

## Option 1: Hosted MCP Server (Current - Recommended) ✅

The configuration now uses:

```json
{
  "mcpServers": {
    "supabase": {
      "type": "http",
      "url": "https://mcp.supabase.com/mcp?project_ref=okjuhvgavbcbbnzvvyxc"
    }
  }
}
```

### Setup Steps:

1. **Restart Cursor** completely
2. **Authenticate**: When Cursor connects to the MCP server, it will:
   - Open a browser window
   - Prompt you to log in to your Supabase account
   - Ask you to grant access
   - Select the organization containing your project
3. **Verify**: Test by asking: "What tables exist in my Supabase database?"

## Option 2: Use Personal Access Token (Alternative)

If you prefer to use the npm package with a PAT instead:

### Step 1: Generate Personal Access Token

1. Go to **Supabase Dashboard**: https://supabase.com/dashboard
2. Click on your **Account Settings** (top right profile icon)
3. Navigate to **Access Tokens** section
4. Click **Generate New Token**
5. Give it a name (e.g., "Cursor MCP")
6. Copy the generated token (you'll only see it once!)

### Step 2: Update Configuration

Update `.cursor/mcp.json` to:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server-supabase@latest"],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "<your-personal-access-token-here>"
      }
    }
  }
}
```

Replace `<your-personal-access-token-here>` with the token you generated.

### Step 3: Restart Cursor

Close and reopen Cursor to load the new configuration.

## Which Option to Use?

- **Option 1 (Hosted)**: Easier setup, OAuth-based, no manual token management
- **Option 2 (PAT)**: More control, works offline, requires manual token generation

## Verification

After setup, test MCP access:

- "What tables exist in my Supabase database?"
- "Show me the structure of the profiles table"
- "Run the SQL migration for profiles table"

## Troubleshooting

### If Hosted MCP Doesn't Work:

- Check that you're logged into Supabase in your browser
- Ensure you select the correct organization during OAuth
- Try clearing browser cache and re-authenticating

### If PAT Doesn't Work:

- Verify the token is correct (no extra spaces)
- Check token hasn't expired
- Ensure you have proper permissions on the project

## Security Notes

- **PAT Tokens**: Store securely, never commit to git
- **Hosted MCP**: Uses OAuth, more secure, tokens managed by Supabase
- **Read-Only Mode**: Consider enabling read-only mode for production data











