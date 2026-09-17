# MERGE FILINGS — session 2026-09-18

Findings that fall between tracks, or that a track raised about the session rather than its own
subject. Appended as they arrive; each written so it can be `bd`-filed verbatim.

## F-1 — a landed fix that the copied PROTOCOL still described as unfixed (L7-with-a-twist, on the protocol itself)
`$PREV/PROTOCOL.md` §S3 named `trackM/probes/impl/vacuity.py` and said *"That script is itself bd jdec …
Track J is fixing it."* The fix landed 2026-09-15 (`tools/negative_vacuity_check.py`); the protocol was
copied forward on 2026-09-17 and again at this session's open with the sentence intact, so every track
briefed from it would have run a script that dies with `FileNotFoundError`. Found by Wave 0-A while
closing `jdec`; **corrected in `$SES/PROTOCOL.md` §S3 at 2026-09-17 12:05** by the orchestrator. Direction:
safe (a dead instrument cannot report a false pass), but it is the third copied-forward staleness in
three sessions (oracle block ×2, now S3). Recommended for the next PROTOCOL: a `## Copied-forward
checklist` at the top naming every line that carries a measurement or a file path.

## F-2 — `gzgs`'s correction landed in a new COPY, not where the citations point (P3, doc)
`$PREV/../session-2026-09-14-orchestrator/MERGE_FILINGS.md` §2 and `MERGE_REPORT.md` §5b cite `fp_m28.c`
as the F×P VALUE witness; that file and `trackM/probes/m28.c` carry no `gzgs` / `vacuous` marker. Only
the third copy `j_gzgs_m28_VACUOUS_merge.c` carries the vacuity header. A reader following the citation
finds a witness that its own bead says is vacuous, unmarked. Also: no `fp_x5b`-derived witness exists in
`ir-pass/test/` or `tests/e2e/` — refused in writing because the F×P composition has no Rule-13 opinion
(bd `hlhh`). Owner: whoever next touches the 2026-09-14 records; fileable as a doc bead.

## F-3 — `CLAUDE.md`'s measured lines are stale in a way that will read as a MISMATCH (doc, close-of-session)
Wave 0-A re-measured: ctest **457** (CLAUDE.md says 442), `^e2e-` **447**, `^e2e-slice-` **390**,
`twin-identical` **43**, fixtures **2082** (says 2047), goldens **392**, twin cells **359** (says 338).
And §4c quotes the `three_bools` STRICT-2b line byte-for-byte; every number is still exact but the
checker now prints an extra segment `2 template rail mint(s) of which 1 left dirty` (bd `19vy`/`1739`
landed) — a capability gain that reads as a golden mismatch. **Routed to the closing docs pass.**

## F-4 — `1739` hole 2 did not reproduce as filed (record correction, applied to the bead)
The bead claimed the checker "never compares the LITERAL operands"; Wave 0-A built the module and both
the pre-fix and HEAD checkers refuse it (`UNPROVEN T1-no-reversal`). What `7448fa29` closes is the
narrower statement in its own header: a textual match is not a value match when the text is `undef`.
No `hg8s` probe file survives in the tree. Recorded on the bead by `--append-notes`; the bead is closed
on the corrected claim, not the filed one.

## F-5 — two source comments claim bd `58tc` CLOSED; the measurement says it is not (record correction, P3)
`RotationLowering.cpp:1868` says "`8h7d.5` (closing bd 58tc)" and clause 3 at `:1951-1953` repeats it,
but Wave 0-B's probe observing every record in-body still WARNS (445 B stderr), so the exemption the bead
asks for does not happen. The bead's own quoted witness is now VACUOUS (`clang -O1` fully unrolls it at
K=3, so it never tested the back edge). And the class is a WARNING by owner ruling bd `lyyf`, so
**CLAUDE.md §5 lists `58tc` under "Over-declines" with the wrong word.** Not root-caused. Recorded on the
bead by `--append-notes`; the two source sentences are owed a correction in the same change that
next touches that file (L7-with-a-twist: a record correction not applied to the source is not one).

## F-6 — CLAUDE.md's stage-2b paragraph and the `free_pairing_check.py` Where-Things-Live row are stale for the CENSUS
Both still say the checker "is structurally blind to a leaked TEMPLATE-minted rail". True of the
VIOLATION layer, false of the CENSUS since `95949550` (bd `8h7d.6`/`19vy`/`1739` hole 1: it now prints
`N template rail mint(s) of which M left dirty`). Routed to the closing docs pass with F-3.

## F-7 — one defect carried under three bead ids
`8h7d.6`, `19vy` and `1739` hole 1 are the same template-rail census blindness; the source credits the
latter two. All three are now closed (0-A: `19vy`, `1739`; 0-B: `8h7d.6`) on the same landing. Noted so
the closing count is not read as three fixes.

## F-8 — a module was EDITED while a run importing it was in flight (protocol, self-disclosed by Track V)
Track V made three edits to `tools/loop_twin_matrix.py` while the 382-cell `--regenerate` was running —
the Python analogue of relinking a binary under a measurement, which `CLAUDE.md` Rule 19 forbids by
name for binaries. Disclosed in `trackV/GATES.md`; the semantic edit is a proven no-op (derived
`INDEXED_REGION` set EQUAL to the prefix form; `source_identity` 0 MOVED), the spawn pool's workers all
predated it, and the green `e2e-loop-twin-matrix` gate on the FINAL file is what settles it rather than
the argument. Direction: safe, and the disclosure is the behaviour we want. **Recommended for the next
PROTOCOL:** extend "never relink under a running measurement" to "never edit a script a running
measurement imports" — the failure mode is identical and the rule is currently binary-only.

## F-9 — the nested-loop axis found 8 divergences on `main`'s own compiler (instrument finding, beads filed)
Classes D (6 cells, bd `3n29` P1: the rolled OUTER loop never discharges its own per-trip rail when an
inner loop is present — needs both loops, three single-loop isolations identical) and E (2 cells, P2: the
hoisted (ii-c) read minted once rolled, once-per-repetition flat, undischarged on both sides). Both are
faces of bd `s82e`; class D is a population its own reproducer cannot reach. Routed to Group 1's
merge-and-gate agent: re-run the matrix on the combined binary and report which of the 8 move.

## F-10 — Track D's review F-1: a P1 POPULATION widening of bd `s82e`'s class, invisible to every gate the track ran
Recorded here because it is a between-tracks fact: D's accept-direction widening of P4 is sound on its own
terms (14 movers re-derived, 0 A→D), yet one of its newly reachable programs (`dD1`) is the hoisted-template
dephasing leak that Group 1 is building the discharge for. Neither track's gates could see it: D's lit /
corpus / injection matrix have no rolled-vs-unrolled instrument, and the twin matrix's row-W cells carry no
trailing non-diagonal gate. `declineDephasingUnmarkedLoopRails`' own retirement trigger ("any NEW member of
the class … re-derive it") fired unhonoured. Disposition: R20 (land behind Group 1; composition measured and
reviewed). Lesson for PROTOCOL: an accept-direction widening of a CONDITION fence owes one rolled-vs-unrolled
probe with a trailing non-diagonal gate on every register the condition reads.

## F-11 — the session SCRATCHPAD ROOT IS SHARED between agents; one agent's harness overwrote another's (protocol, P3)
`review_r13_group1` F-4: another agent's `probe.sh` overwrote the reviewer's at 14:44 and one batch ran on a
THIRD binary (`96d74fe6…`), producing a well-formed void row. Caught by a format mismatch, not by a check;
everything re-measured on a private harness. Two agents writing the same scratchpad path is the L10 failure
mode arriving through the environment. **Recommended for PROTOCOL:** every agent works under
`<scratchpad>/<track>/` (never the root), and every harness prints the cq-opt hash it is running on in
every result row, so a foreign binary is visible in the data rather than in a format accident.

## F-12 — bd `6n1s` half-closed: the review's own fix was itself one shape short
The `t5j` shape (a re-joining classical `if` in a marked body) is fixed on the Group-1 branch; the `g8`
shape (the ARM mints the interior rail) is not, and neither part's gates can see it (unmoved on both
binaries, stage 2b exits 0 with `2 left dirty`). Third consecutive session in which a Rule-13 round found
a P1 on round 1 of a loop change. Routed: fix in flight on the same branch; the gate's second pass
measures it plus a blast-radius sweep (`gate/BLAST_RADIUS_g8.md`).

## F-13 — the gate's own instrument findings G-8 / G-9 / G-10 (self-caught; recorded as PROTOCOL items)
`gate/FILINGS.md`: G-8 a pre-merge guard printed `[empty = safe]` from an unconditional `echo`; G-9 the
gate's matrix parser dropped the second of two lines the matrix prints per cell (`QUARANTINED SIGNATURE
CHANGED`) and would have authored six duplicate blocks; G-10 a retirement trigger keyed on a digest from
ONE renderer misfired against the matrix's own digest — never comparable (PROTOCOL S3 one layer up).
Plus the blast detector's first run reporting CLEAN because `-q` suppressed the census line. Four L10
instances from one agent, all caught by validating against a known positive or by reading the raw
report. **For the next PROTOCOL:** a digest-keyed trigger must name its renderer or key on
renderer-independent facts; a summariser of a report must be validated against a report it is known to
mis-summarise; a guard's pass message must be computed from its own measurement.

## F-14 — the composition round's record-scoping item (review_r13_composition F-3): G-2's sentence is true of `dD1` and false of its neighbourhood
`x6` = `dD1` + one line goes DECLINE (ORACLE, G1-alone) → ACCEPT with `1 template rail left dirty` on D-alone AND COMBINED, md5-identical. NOT a miscompile: the compiler takes the leak (safe) direction and `recordIsExemptAt` clause 3 exempts it because the rail is the user's live observed value (bd `lyyf`). One sentence owed on bd `s82e` / `drbq.12` at close, not a fence.

## F-15 — the composition round's item 7 corrects the zujr brief in two places
Both of the owner's program's first two walls are the SAME construct (the in-loop `_Bool` VALUE arm: bd `ej5w` L-4 / `x5fp` L-2) — deleting line 94 alone makes the file compile at exit 0 on both binaries; and the rail-array wall `SCOPE_loop` recorded (bd `xdu2`, the taint-escape store) is GONE since `79bd7af9` — the peel lowers a rolled body with `cqrt_alloc_i1`/`cqrt_ry_i1` and a 12-byte handle alloca. Wall 2's decline carries NO `!dbg` (`<unknown>:0:0`, bd `91di`/`f8ov` family). ⚠ Site discrepancy to resolve next session: the gate reports wall 1 at `ArmClassify.cpp:5478` (as on 2026-09-17), the composition reviewer at `ControlDetect.cpp:642/:689` — same string, two sites; verify with `CQ_CTRL_DBG=1` before briefing.

## F-16 — G-13, the session's composition result, carried here so it is not lost in `gate/FILINGS.md`
Track D ALONE over-accepts: on `5ee9d144` the rolled half of every der/rder/range/rrange cell is `1 left dirty`
(the hoisted which-path chain never discharged across the trailing `cqrt_ry`); on the combined binary it is
`0 dirty` because Group 1's P2 discharges it at the loop exit. R20's sequencing was load-bearing for
correctness. Trigger in the class-H quarantine header (bd `z0cv`); bd memory
`composition-d-alone-overaccept-g13-2026-09-17`. This is the first session in which the composition round
ran BEFORE the landing.
