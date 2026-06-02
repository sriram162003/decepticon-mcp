#!/usr/bin/env python3
"""
Decepticon MCP Server
Exposes Decepticon's standalone security tools as MCP tools for Claude Code.

Standalone tools (no Docker/external services needed):
  - Web:      jwt_parse, jwt_forge, jwt_crack, graphql_plan
  - Cloud:    iam_policy_audit, k8s_audit, tfstate_audit, s3_buckets_from_text
  - AD:       bh_ingest_json, kerberos_classify, adcs_audit
  - Reversing: bin_identify, bin_strings, bin_packer, bin_rop
  - Contracts: solidity_scan
  - Research:  kg_* (JSON-backed graph), cve_enrich_dependencies

Usage:
  python3 mcp_server.py
  (Claude Code connects via stdio - see .claude/settings.json)
"""
from __future__ import annotations

import json
import logging
import sys
from typing import Any

# Silence all non-error logs — stdout must stay clean for JSON-RPC
logging.basicConfig(level=logging.ERROR, stream=sys.stderr)

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import CallToolResult, ListToolsResult, TextContent, Tool

# ---------------------------------------------------------------------------
# Import Decepticon tool groups
# ---------------------------------------------------------------------------
from decepticon.tools.web.tools import WEB_TOOLS
from decepticon.tools.cloud.tools import CLOUD_TOOLS
from decepticon.tools.ad.tools import AD_TOOLS
from decepticon.tools.reversing.tools import REVERSING_TOOLS
from decepticon.tools.contracts.tools import CONTRACT_TOOLS
from decepticon.tools.research.tools import RESEARCH_TOOLS
from decepticon.tools.research.patch import PATCH_TOOLS
from decepticon.tools.research.scanner_tools import SCANNER_TOOLS

# Tools that require Docker/external services — excluded from standalone mode
DOCKER_ONLY = {
    # bash tools need tmux sandbox container
    "bash", "bash_output", "bash_kill", "bash_status",
    # proxy tools need Caido CLI
    "proxy_list_requests", "proxy_view_request", "proxy_send_request",
    "proxy_repeat_request", "proxy_scope_rules", "proxy_list_sitemap",
    "proxy_view_sitemap_entry",
    # browser needs Playwright + Chromium
    "browser_action",
    # Ghidra/radare2 need sandbox image binaries
    "ghidra_analyze", "ghidra_decompile", "ghidra_xrefs", "ghidra_status",
    "bin_ghidra_script", "bin_r2_script",
    # SIEM/EDR need live API credentials
    "sigma_to_splunk", "sigma_to_sentinel", "sigma_to_elastic",
    "yara_to_defender", "edr_push", "list_siem_targets",
}

ALL_TOOL_GROUPS = [
    WEB_TOOLS,
    CLOUD_TOOLS,
    AD_TOOLS,
    REVERSING_TOOLS,
    CONTRACT_TOOLS,
    RESEARCH_TOOLS,
    PATCH_TOOLS,
    SCANNER_TOOLS,
]

# Build registry: all tools except Docker-only ones
_registry: dict[str, Any] = {}
for group in ALL_TOOL_GROUPS:
    for t in group:
        if t.name not in DOCKER_ONLY:
            _registry[t.name] = t


def _lc_tool_to_mcp(lc_tool: Any) -> Tool:
    """Convert a LangChain @tool to an MCP Tool definition."""
    schema = {}
    if hasattr(lc_tool, "args_schema") and lc_tool.args_schema is not None:
        raw = lc_tool.args_schema.model_json_schema()
        # Strip Pydantic title wrapper if present
        schema = {
            "type": "object",
            "properties": raw.get("properties", {}),
            "required": raw.get("required", []),
        }
    else:
        schema = {"type": "object", "properties": {}}

    return Tool(
        name=lc_tool.name,
        description=lc_tool.description or "",
        inputSchema=schema,
    )


# ---------------------------------------------------------------------------
# MCP Server
# ---------------------------------------------------------------------------
server = Server("decepticon")


@server.list_tools()
async def list_tools() -> list[Tool]:
    return [_lc_tool_to_mcp(t) for t in _registry.values()]


@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    tool = _registry.get(name)
    if tool is None:
        return [TextContent(type="text", text=json.dumps({"error": f"Unknown tool: {name}"}))]

    try:
        result = tool.invoke(arguments)
        # Normalise to string
        if isinstance(result, str):
            text = result
        else:
            text = json.dumps(result, indent=2, default=str)
    except Exception as exc:
        text = json.dumps({"error": str(exc)})

    return [TextContent(type="text", text=text)]


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
async def main():
    print(f"[decepticon-mcp] {len(_registry)} tools registered", file=sys.stderr)
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options(),
        )


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
