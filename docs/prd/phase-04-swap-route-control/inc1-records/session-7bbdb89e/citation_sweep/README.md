# `citation_sweep/` — the round-3 doc pass's instrument for lens item **F-E2-2**

bd `test_C_libtooling-eqpx`, session `7bbdb89e`, 2026-09-06. Committed so the numbers in
`RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.16's round-2 subsection are **re-derivable** rather than
asserted — the same complaint the round-2 lens raised about `tu_exth.c` (F-E2-1).

    python3 citation_sweep.py <worktree root> main citation_verdicts.txt

| file | what it is |
|---|---|
| `citation_sweep.py` | every `(LoopLowering\|ArithLowering\|OpcodeLowering)(.cpp)?:<n>` citation **plus the bare `` `:<n>` `` CONTINUATIONS these docs write** (attributed to the last file named on the same line), across the notes, the PRD, `CLAUDE.md`, `ROADMAP.md`, the three edited sources and the 16 new fixtures. Prints the SUBJECT text at line `n`, the `main` text at line `n`, and where `main`'s line `n` MOVED to (a `difflib` line map) |
| `citation_verdicts.txt` | the HAND adjudication, one row per citation: `OK` / `MISS-INTRODUCED` / `MISS-PREEXISTING` / `QUOTED`. The script only COUNTS; it never decides |
| `sweep_BEFORE_beb34e0.txt` | the run on the pre-edit tree (`beb34e0`, edits `git stash`ed): **62 scanned — 43 OK, 10 MISS-INTRODUCED, 9 MISS-PREEXISTING, 0 UNADJUDICATED** |
| `sweep_AFTER.txt` | the run on this commit: **61 scanned — 43 OK, 0 MISS-INTRODUCED, 9 MISS-PREEXISTING, 9 QUOTED, 0 UNADJUDICATED** |

⚠ **TWO LIMITS, stated so nobody over-reads the 0.** (1) The bare-`` `:<n>` `` continuation is
attributed to the last file named **on the same line**, so a continuation that wraps onto the next
source line is NOT scanned. (2) A verdict is keyed by `<citing file>:<citing line> <FILE>:<n>`, so
it goes stale the moment the citing text is re-wrapped — regenerate the `QUOTED` block rather than
trusting a stale one. Neither limit can turn a MISS into an OK: both make the sweep scan LESS.
