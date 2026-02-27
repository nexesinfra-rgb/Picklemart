# 🔧 Supabase MCP (Model Context Protocol) Setup

## Overview

MCP (Model Context Protocol) allows AI assistants to interact with your Supabase database directly, enabling schema queries, data operations, and database management through natural language.

## ✅ Configuration Complete

The Supabase MCP server has been configured with the following:

- **Project URL**: `https://okjuhvgavbcbbnzvvyxc.supabase.co`
- **Anon Key**: Configured in `.cursor/mcp.json`
- **Status**: ✅ Enabled

## 📁 Configuration Files

### 1. `.cursor/mcp.json`

This file configures the MCP server for Cursor IDE:

```json
{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-supabase",
        "--url",
        "https://okjuhvgavbcbbnzvvyxc.supabase.co",
        "--anon-key",
        "[your-anon-key]"
      ]
    }
  }
}
```

### 2. `.cursor/mcp_settings.json`

Additional MCP settings and metadata.

### 3. `.cursorrules`

Project-specific rules and Supabase configuration details.

## 🚀 Enabling MCP in Cursor

1. **Restart Cursor IDE** to load the MCP configuration
2. **Check MCP Status**:

   - Open Cursor Settings
   - Navigate to MCP/Extensions section
   - Verify "supabase" server is listed and enabled

3. **Test MCP Connection**:
   - Ask the AI assistant: "What tables exist in my Supabase database?"
   - The assistant should be able to query your Supabase schema

## 🎯 MCP Capabilities

Once enabled, the AI assistant can:

- ✅ Query database schema (tables, columns, indexes)
- ✅ Execute SQL queries (read-only with anon key)
- ✅ Suggest database optimizations
- ✅ Help with RLS policy creation
- ✅ Generate migration scripts
- ✅ Analyze query performance

## 🔒 Security Notes

- The MCP server uses the **anon key** which is safe for client-side use
- RLS policies will still enforce data access rules
- The MCP server has read-only access by default
- For write operations, you'll need to use the service role key (server-side only)

## 🧪 Testing MCP

Try these commands with the AI assistant:

1. **Schema Query**: "Show me all tables in my Supabase database"
2. **Table Structure**: "What columns does the profiles table have?"
3. **RLS Policies**: "What RLS policies are set on the orders table?"
4. **Indexes**: "Show me all indexes in my database"

## 📚 Resources

- MCP Documentation: https://modelcontextprotocol.io
- Supabase MCP Server: https://github.com/modelcontextprotocol/servers/tree/main/src/supabase
- Supabase Docs: https://supabase.com/docs

## 🔄 Troubleshooting

### MCP Not Working?

1. **Check Configuration**:

   - Verify `.cursor/mcp.json` exists and is valid JSON
   - Ensure project URL and anon key are correct

2. **Restart Cursor**:

   - Close and reopen Cursor IDE
   - MCP servers load on startup

3. **Check Logs**:

   - Open Cursor Developer Tools (Help > Toggle Developer Tools)
   - Check console for MCP-related errors

4. **Verify Network**:
   - Ensure you can access `https://okjuhvgavbcbbnzvvyxc.supabase.co`
   - Check firewall/proxy settings

### Common Issues

**Issue**: "MCP server not found"

- **Solution**: Ensure `npx` is available in your PATH
- **Solution**: Try running `npx @modelcontextprotocol/server-supabase --help` manually

**Issue**: "Connection refused"

- **Solution**: Check Supabase project URL is correct
- **Solution**: Verify anon key is valid

**Issue**: "Permission denied"

- **Solution**: Check RLS policies allow anon access
- **Solution**: Verify anon key has necessary permissions

---

**Status**: ✅ Configured
**Last Updated**: 2025-01-10















