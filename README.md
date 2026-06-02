# Decepticon MCP

A local [MCP (Model Context Protocol)](https://modelcontextprotocol.io) server that exposes [Decepticon](https://github.com/PurpleAILAB/Decepticon)'s security tools natively inside Claude Code — plus a full set of specialist agents and the `/decepticon` orchestrator skill.

## What This Does

Bridges Decepticon's 73 standalone security tools into Claude Code as native MCP tools, with specialist agents for each attack domain and a combined Soundwave + Orchestrator skill to run full red team engagements end-to-end.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/decepticon-mcp/main/install.sh | bash
```

Then restart Claude Code.

### Prerequisites

- [uv](https://astral.sh/uv) — Python package manager
- [git](https://git-scm.com)
- [jq](https://jqlang.github.io/jq)
- Python 3.13 (installed automatically via uv)
- Claude Code

## What Gets Installed

### MCP Server — 73 Tools

The server exposes Decepticon's standalone tools (no Docker required) as native MCP tools:

| Domain | Tools |
|--------|-------|
| **Web** | `jwt_parse`, `jwt_forge`, `jwt_crack`, `graphql_plan`, `oauth_audit`, `cookie_audit` |
| **Cloud** | `iam_policy_audit`, `k8s_audit`, `tfstate_audit`, `s3_buckets_from_text`, `metadata_endpoints` |
| **Active Directory** | `bh_ingest_json`, `bh_ingest_zip`, `kerberos_classify`, `adcs_audit`, `dcsync_check`, `shadow_creds_audit`, `delegation_audit`, `gpo_audit` |
| **Binary** | `bin_identify`, `bin_strings`, `bin_packer`, `bin_rop`, `bin_symbols_report` |
| **Contracts** | `solidity_scan`, `foundry_reentrancy_test`, `foundry_access_test`, `foundry_flashloan_test` |
| **Knowledge Graph** | `kg_add_node`, `kg_add_edge`, `kg_query`, `kg_neighbors`, `plan_attack_chains`, `validate_finding` |
| **Research** | `cve_lookup`, `cve_enrich_dependencies`, `fuzz_classify`, `fuzz_harness`, `patch_propose` |

### Agents

Specialist subagents with focused tool sets and Decepticon's original system prompts:

| Agent | Purpose |
|-------|---------|
| `recon` | Target investigation — subdomain enum, port scan, service fingerprinting |
| `analyst` | Vuln research — CVE sweep, source audit, fuzzing, attack chain planning |
| `exploit` | Initial access — skill-first exploitation with vector lock mechanics |
| `postexploit` | Post-compromise — cred dumping, privesc, lateral movement |
| `web-exploiter` | JWT/OAuth/GraphQL/cookie attacks |
| `ad-operator` | BloodHound, Kerberoast, ADCS ESC1-15, DCSync, delegation |
| `cloud-hunter` | IAM privesc, Terraform secrets, K8s audit, SSRF→metadata |
| `contract-auditor` | Solidity/EVM audit with Foundry PoC generation |
| `reverser` | Binary analysis — strings, ROP gadgets, packer detection |

### Skill — `/decepticon`

A combined Soundwave + Orchestrator skill that runs the full engagement lifecycle:

1. **Soundwave phase** — Socratic interview → writes 8-document engagement bundle (RoE, CONOPS, Threat Profile, Deconfliction, Contact, Data Handling, Abort, Cleanup)
2. **Orchestrator phase** — builds OPPLAN, dispatches specialist agents in kill-chain order (recon → analyst → exploit → postexploit), tracks objectives, produces final report

## Usage

### Start an engagement
```
/decepticon
```
Claude Code will interview you about the target and engagement type, then run the full kill chain.

### Use tools directly
```
Parse this JWT: <token>
Audit this IAM policy: <json>
Scan this Solidity contract: <source>
```
The `decepticon__*` MCP tools are available in all conversations automatically.

### Spawn a specialist agent
Ask Claude Code to use a specific agent:
```
Use the recon agent to enumerate example.com
Use the ad-operator agent to analyse this BloodHound data
```

## Architecture

```
Claude Code (main session)
  └── /decepticon skill (Soundwave + Orchestrator)
        ├── decepticon__* MCP tools (73 tools, always available)
        └── Spawns subagents as needed:
              recon → analyst → exploit → postexploit
              web-exploiter / ad-operator / cloud-hunter
              contract-auditor / reverser
```

## Requirements

The 73 tools exposed by the MCP server run without Docker. For the full Decepticon stack (bash sandbox, Ghidra, browser automation, proxy tools), follow [Decepticon's setup guide](https://github.com/PurpleAILAB/Decepticon/blob/main/docs/setup-guide.md).

## Credits

Built on top of [Decepticon](https://github.com/PurpleAILAB/Decepticon) by [PurpleAILAB](https://github.com/PurpleAILAB). All security tools, agent prompts, and skill content are from the Decepticon project. This repo provides only the MCP bridge, Claude Code agents, and installer.
