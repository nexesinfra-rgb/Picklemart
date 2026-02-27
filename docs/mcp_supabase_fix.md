# Fix Supabase MCP Configuration

## Problem

The MCP server was failing with errors:

1. First: `@modelcontextprotocol/server-supabase` doesn't exist
2. Second: `Unknown option '--url'` - the package doesn't accept command-line arguments

## Solution Applied

Updated the MCP configuration to:

1. Use the correct package: `@supabase/mcp-server-supabase@latest`
2. Use environment variables instead of command-line arguments

## Current Configuration

The `.cursor/mcp.json` file has been updated:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server-supabase@latest"],
      "env": {
        "SUPABASE_URL": "https://okjuhvgavbcbbnzvvyxc.supabase.co",
        "SUPABASE_ANON_KEY": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ranVodmdhdmJjYmJuenZ2eXhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4NTI1MzksImV4cCI6MjA3ODQyODUzOX0.9a90bBvLM7k8pIt9x6lch3ZpQIrQxCntjkP3CEUEXSI"
      }
    }
  }
}
```

## Verification Steps

1. **Restart Cursor Completely**

   - Close Cursor completely (not just reload)
   - Reopen Cursor to reload MCP configuration

2. **Check MCP Status**

   - Open Cursor Settings
   - Navigate to MCP/Extensions section
   - Verify "supabase" server is listed and shows as connected
   - Check for any error messages

3. **Test MCP Access**
   - Try asking: "What tables exist in my Supabase database?"
   - The AI should be able to query your Supabase schema
   - Try: "Show me the structure of the profiles table"

## Alternative Configuration Options

### Option 1: Use Personal Access Token (If Environment Variables Don't Work)

If the environment variable approach doesn't work, you may need a Personal Access Token:

1. Generate PAT in Supabase Dashboard → Account Settings → Access Tokens
2. Update configuration:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": ["-y", "@supabase/mcp-server-supabase@latest"],
      "env": {
        "SUPABASE_ACCESS_TOKEN": "<your-personal-access-token>"
      }
    }
  }
}
```

### Option 2: Use Hosted MCP Server

Use Supabase's hosted MCP service instead:

```json
{
  "mcpServers": {
    "supabase": {
      "url": "https://mcp.supabase.com/mcp?project_ref=okjuhvgavbcbbnzvvyxc"
    }
  }
}
```

Note: This requires authentication through your Supabase account.

### Option 3: Global Installation

If npx approach has issues, install globally:

```bash
npm install -g @supabase/mcp-server-supabase
```

Then update mcp.json:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "mcp-server-supabase",
      "env": {
        "SUPABASE_URL": "https://okjuhvgavbcbbnzvvyxc.supabase.co",
        "SUPABASE_ANON_KEY": "..."
      }
    }
  }
}
```

## Troubleshooting

### If MCP Still Doesn't Work:

1. **Check Package Installation**:

   ```bash
   npm view @supabase/mcp-server-supabase
   ```

2. **Clear npm Cache**:

   ```bash
   npm cache clean --force
   ```

3. **Check Cursor Logs**:

   - Help → Toggle Developer Tools
   - Check Console for MCP-related errors
   - Look for connection or authentication errors

4. **Verify Environment Variables**:

   - Ensure no extra spaces or quotes in values
   - Check that SUPABASE_URL and SUPABASE_ANON_KEY are correct

5. **Test Package Manually**:
   ```bash
   npx -y @supabase/mcp-server-supabase@latest
   ```
   (This should start the server - you can Ctrl+C to stop)

## Notes

- The MCP server allows AI assistants to query and interact with your Supabase database
- This is useful for schema introspection and running queries
- The anon key is safe to use in MCP configuration as it's already public in your app
- RLS policies will still enforce data access rules
