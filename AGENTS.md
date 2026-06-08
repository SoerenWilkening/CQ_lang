# Agent Instructions — CQ_lang

**The full agent guide is [`CLAUDE.md`](CLAUDE.md) — read it first.** It is the
canonical operating manual for this taint-driven quantum-C compiler: the
non-negotiable rules, the pipeline architecture, the tainted-control-flow
correctness risks, the build/test commands, conventions, prohibitions, and the
file/docs map. This file carries only the runtime-agnostic operational notes plus
the Beads workflow; everything else lives in `CLAUDE.md`.

## Prime Directive (the one rule never to break)

This is a quantum **reversible** compiler: a wrong lowering that passes
`opt -verify` is a **silent miscompile** — the dominant failure mode. **When any
detection or lowering precondition is unproven or off-pattern, DECLINE** — emit
the loud `DiagnosticInfoUnsupported` (`"… under quantum control"`, `opt` exits
non-zero) and lower nothing. Over-declining is always safe; over-accepting is the
only unforgivable bug. See `CLAUDE.md` → "The Prime Directive" and the full rule
list.

## Non-Interactive Shell Commands

Always use force/batch flags so an aliased interactive (`-i`) mode cannot hang the
agent on a y/n prompt: `cp -f` · `mv -f` · `rm -f` · `rm -rf` ·
`ssh`/`scp -o BatchMode=yes` · `apt-get -y` · `HOMEBREW_NO_AUTO_UPDATE=1`.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:7510c1e2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
