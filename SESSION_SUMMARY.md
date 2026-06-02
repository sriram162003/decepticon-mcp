# Session Summary — Decepticon MCP for Claude Code

## What We Built

A complete bridge between [Decepticon](https://github.com/PurpleAILAB/Decepticon) (autonomous red team agent) and Claude Code, published at [github.com/sriram162003/decepticon-mcp](https://github.com/sriram162003/decepticon-mcp).

---

## 1. Cloned Decepticon

```
~/Decepticon/    ← PurpleAILAB/Decepticon (untouched source)
```

Only 2 files added on top — nothing in the original repo was modified.

---

## 2. MCP Server (`~/Decepticon/mcp_server.py`)

- Python MCP server using `mcp.server.Server` (stdio transport)
- Wraps Decepticon's LangChain `@tool` functions as MCP tools
- Auto-bridges LangChain Pydantic schemas → MCP `inputSchema`
- Uses **blocklist approach** — includes everything except known Docker-only tools
- **78 tools registered** across 8 tool groups

### Tool breakdown
| Category | Count | Notes |
|----------|-------|-------|
| Fully standalone | 46 | Pure local, zero deps |
| Knowledge graph (`kg_*`) | 27 | JSON file fallback by default, Neo4j optional |
| Network/external | 5 | `cve_lookup`, `http_request`, `http_history`, `kg_ingest_asrep_hashes`, `kg_ingest_crackmapexec` |
| Docker-only (excluded) | ~20 | bash sandbox, Ghidra, browser, proxy, SIEM |

### Python environment
```
~/Decepticon/.venv-mcp/    ← Python 3.13 venv
  packages: decepticon (dev mode) + mcp
```

### Registered in Claude Code
```json
// ~/.claude/settings.json
{
  "mcpServers": {
    "decepticon": {
      "command": "/Users/testrespireesingapore/Decepticon/.venv-mcp/bin/python",
      "args": ["/Users/testrespireesingapore/Decepticon/mcp_server.py"]
    }
  }
}
```

---

## 3. Claude Code Agents (`~/.claude/agents/`)

9 specialist agents with Decepticon's original system prompts + focused MCP tool sets:

| Agent | File | Role |
|-------|------|------|
| `recon` | `recon.md` | Target investigation — nmap, subfinder, ffuf, raw observations only |
| `analyst` | `analyst.md` | CVE sweep, source audit, fuzzing, attack chain planning, PoC validation |
| `exploit` | `exploit.md` | Initial access — skill-first, vector lock, 4 completion states |
| `postexploit` | `postexploit.md` | Cred dumping, privesc, lateral movement, C2 |
| `web-exploiter` | `web-exploiter.md` | JWT forge/crack, GraphQL IDOR, OAuth abuse, cookie analysis |
| `ad-operator` | `ad-operator.md` | BloodHound, Kerberoast, ADCS ESC1-15, DCSync, delegation, LAPS, GPO |
| `cloud-hunter` | `cloud-hunter.md` | IAM privesc, Terraform secrets, K8s audit, SSRF→metadata |
| `contract-auditor` | `contract-auditor.md` | Solidity audit, Slither, Foundry PoC generation |
| `reverser` | `reverser.md` | Binary analysis — strings, ROP, packer, Ghidra (Docker-conditional) |

Note: `soundwave.md` also exists as a standalone agent but its functionality is merged into the skill.

---

## 4. Decepticon Skill (`~/.claude/skills/decepticon/SKILL.md`)

A single combined skill invoked with `/decepticon` that runs Claude Code itself as:

**Phase 1 — Soundwave (Engagement Planner)**
- Socratic interview across 9 ambiguity dimensions (scope, threat model, kill chain, constraints, success criteria, contacts, data sensitivity, abort triggers, persistence footprint)
- Writes 8-document engagement bundle: RoE → Threat Profile → CONOPS → Deconfliction → Contact → Data Handling → Abort → Cleanup
- Cross-validates documents before handoff
- Calls `complete_engagement_planning` to hand off to Phase 2

**Phase 2 — Decepticon Orchestrator**
- Reads engagement plan, builds OPPLAN with `add_objective`
- Dispatches specialist agents in kill-chain order: recon → analyst → exploit → postexploit + domain specialists
- Enforces mandatory recon→exploit escalation (not advisory)
- Full sub-agent failure handling (infra/crash/wandering)
- Produces final report: executive summary + technical report + promoted findings

---

## 5. Published Repo (`~/decepticon-mcp/`)

```
decepticon-mcp/
├── mcp_server.py
├── install.sh              ← one-line installer
├── README.md
├── SESSION_SUMMARY.md      ← this file
├── agents/                 ← all 9 agent .md files
└── skills/decepticon/
    └── SKILL.md
```

**One-line install:**
```bash
curl -fsSL https://raw.githubusercontent.com/sriram162003/decepticon-mcp/main/install.sh | bash
```

The installer: checks deps (git, uv, jq) → clones both repos → creates Python 3.13 venv → installs packages → copies agents → copies skill → registers MCP in `~/.claude/settings.json`

---

## 6. What Still Needs Doing

- [ ] **Port conflict** — Decepticon web UI defaults to port 3000 (same as OpenOps). Need to set `WEB_PORT=<other>` in `~/Decepticon/.env` before starting Docker stack
- [ ] **Docker stack** — `docker compose up` in `~/Decepticon/` to unlock bash sandbox, Ghidra, browser, proxy tools (~20 more tools)
- [ ] **Decepticon API key** — run `decepticon onboard` to configure LLM provider and API key for the full agent stack
- [ ] **MCP warning** — `/doctor` shows Google Drive/Gmail/Calendar connectors need OAuth (unrelated to Decepticon, can ignore)

---

## Key File Locations

| What | Path |
|------|------|
| MCP server | `~/Decepticon/mcp_server.py` |
| Python venv | `~/Decepticon/.venv-mcp/` |
| Decepticon source | `~/Decepticon/packages/decepticon/` |
| Claude Code agents | `~/.claude/agents/` |
| Decepticon skill | `~/.claude/skills/decepticon/SKILL.md` |
| Claude Code settings | `~/.claude/settings.json` |
| Published repo | `~/decepticon-mcp/` |
| GitHub | https://github.com/sriram162003/decepticon-mcp |

---

## How to Use

```
/decepticon          → start full red team engagement (Soundwave + Orchestrator)
/mcp                 → verify 78 Decepticon tools are loaded
```

Tools are available in every conversation automatically as `decepticon__<tool_name>`.
