# MCP Configuration Fix

## Problem

The Supabase MCP server was failing with `Unknown option '--url'` error because the package doesn't accept command-line arguments.

## Solution Applied

Updated `.cursor/mcp.json` to use environment variables instead of command-line arguments.

## Current Configuration

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

## Alternative Configuration (If Above Doesn't Work)

If the environment variable approach doesn't work, you may need to use a Personal Access Token (PAT) instead:

1. **Generate a Personal Access Token**:

   - Go to Supabase Dashboard → Account Settings → Access Tokens
   - Create a new Personal Access Token
   - Copy the token

2. **Update Configuration**:
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

## Alternative: Use Hosted MCP Server

If the npm package approach doesn't work, you can use Supabase's hosted MCP server:

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

## Verification Steps

1. **Restart Cursor** completely (close and reopen)
2. **Check MCP Status**:
   - Open Cursor Settings
   - Navigate to MCP/Extensions
   - Verify "supabase" server shows as connected
3. **Test MCP Access**:
   - Try asking: "What tables exist in my Supabase database?"
   - The AI should be able to query your database schema

## Troubleshooting

### If MCP Still Doesn't Work:

1. **Check Package Installation**:

   ```bash
   npm list -g @supabase/mcp-server-supabase
   ```

2. **Try Global Installation**:

   ```bash
   npm install -g @supabase/mcp-server-supabase
   ```

   Then update mcp.json to use the global command:

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

3. **Check Cursor Logs**:

   - Help → Toggle Developer Tools
   - Check Console for MCP-related errors

4. **Verify Environment Variables**:
   - Ensure SUPABASE_URL and SUPABASE_ANON_KEY are correctly set
   - No extra spaces or quotes in the values

## Next Steps

After fixing MCP configuration:

1. Restart Cursor
2. Verify MCP connection
3. Run the SQL migration using MCP or directly in Supabase Dashboard
4. Test profile management features












