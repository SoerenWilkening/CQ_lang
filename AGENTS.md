# Agent Instructions — CQ_lang

**Read [`NORTHSTAR.md`](NORTHSTAR.md) (the three goals and ten design principles), then
[`CLAUDE.md`](CLAUDE.md) (the operating rules, build/test commands and file map).** This file
carries only the runtime-agnostic operational notes plus the Beads workflow.

## The one posture to remember

A decline is valid only if physics forbids the program (`NORTHSTAR.md`, goal 1); everything
else must compile. A construct the compiler does not lower yet is a compiler bug, not a
valid decline: it fails loudly, is filed in bd, and is then built. A wrong lowering that passes
`opt -verify` is a **silent miscompile**, the dominant failure mode. Never accept a lowering
you cannot argue is correct, and never buy safety by declining a valid program. See
`CLAUDE.md` R1/R2.

## Non-Interactive Shell Commands

Always use force/batch flags so an aliased interactive (`-i`) mode cannot hang the
agent on a y/n prompt: `cp -f` · `mv -f` · `rm -f` · `rm -rf` ·
`ssh`/`scp -o BatchMode=yes` · `apt-get -y` · `HOMEBREW_NO_AUTO_UPDATE=1`.

## Test budget (hard limit)

Testing is hard-limited (owner ruling 2026-10-01; full text in `CLAUDE.md` R15). Each bd
issue gets at most **three** lit/ctest invocations, all scoped by name: **red** (new fixtures,
once), **green** (new plus plausibly affected fixtures, once), **final** (once, only if code
changed since green). Mutation validation runs a no-op mutant plus at most **three** real
mutants, each against only its killing fixture. Between checkpoints: one `cq-opt` run on
one probe, then read the IR. Never re-run a passing set; never run `ir-pass-lit`, a label
tier or the full suite while iterating. Reviewers re-run none of the implementer's tests
and use at most six targeted probes per round. Report the invocation
count. Exceeding the budget needs the owner's approval.

## Code map and file-size budget

Before using `rg`, `grep`, `find`, or another source search to locate a
function, consult [`CODE_MAP.md`](CODE_MAP.md) first. It gives each named
function's file and line. After adding, moving, renaming, or deleting a
function, regenerate it in the same change:

```bash
python3 tools/update_code_map.py
python3 tools/update_code_map.py --check
```

Maintained code files should stay at or below **400 physical lines**. If a
change would cross that boundary, separate the cohesive concern into another
file and update its build/source registration plus `CODE_MAP.md`. Generated
artifacts, fixtures, tests, and tooling are still inventoried by the map, but
their decomposition must be handled as explicit follow-up work when a split
would alter generation or test semantics.

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
