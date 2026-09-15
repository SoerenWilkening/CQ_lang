# Track S′ probes — what is here and how it was attacked

`ps.sh` — the per-probe harness (ORACLE vs SUBJECT, one row per probe). Derived from the
Rule-13 round 1β harness `rb.sh` and **re-attacked before use** (`CLAUDE.md` L10, and the
six measured instrument failures of 2026-09-14): it deletes every derived artifact before a
run so a stale trace cannot make a run that never linked look like an accept, it reports
`BROKEN-EMPTY-OUTPUT` and `A:LINKFAIL` as their own tags rather than as accepts, and it
carries a **vacuity guard** — a stage-1 module with zero `cq_{theta,phi,measure}` calls is
`VACUOUS-NO-QUANTUM`, never ACCEPT. Attacked with `i0_empty.c` (0 bytes) and
`i1_noquantum.c` (a real loop, no intrinsics) **before any real probe**; both caught. Without
the guard both score ACCEPT through the passthrough early-out
(bd memory `empty-module-accepts-vacuity-trap`).

`corpus_S2.sh` — the ORACLE-vs-SUBJECT corpus sweep. Three changes from the shared
`corpus.sh`, each closing an instrument lesson PROTOCOL S3 records:
a row carries the **exit code and a sha-256 of the FULL stderr**, not a regex-extracted tag
(the shared regex renders the whole `cq_measure_<sfx>` family as an empty `D:`, so a
decline→decline string change inside it is invisible — and **this track's change IS a
decline-string move**, so the sweep would have been blind to five of its eight movers);
lowered-IR md5s are compared **within a row only** (the temp `ModuleID` differs across
sweeps), which is why both binaries read the SAME stage-1; and a quantum-free stage-1 is
tagged `VACUOUS`.

`inject_S2.py` — the injection (mutation) matrix. Inherited verbatim from the 14c Track S
harness, with two added mutations aimed at the new in-place accept (`g_unroll_inplace`,
`h_outofplace_inplace`) and a third (`i_add_discharge_inplace`) added **after** the first run
showed the in-place fixture's pure-negative `LEAK` prefix was UNEXERCISED. Its three
inherited L10 guards are intact: no fixture argument ⇒ exit non-zero; every mutation bounded
by the enclosing `define`; `N/A` printed and counted separately, never folded into `MISSED 0`.

## Provenance of the probe `.c` files

| probe | from |
|---|---|
| `b*` | Rule-13 round 1β, branch `r13-r1-beta`, `$PREV/review_r1b/probes/` |
| `s*`, `w2*` | 14c Track S, `$PREV/trackS/probes/` |
| `i0_empty`, `i1_noquantum` | round 1β's harness self-attack mutants |

They are copied rather than re-derived so the numbers in `IMPL_S2.md` are comparable to the
ones in the records that filed the beads (Rule 11: a re-typed probe is a different probe).
