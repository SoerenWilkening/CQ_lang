# BRIEF_prep_d_matrix — Inc 1 prep (d): the twin-matrix instruments learn the new `cq_phi` surface; PRE tables committed
Read `$SP/briefs/BRIEF_common.md` first. Agent name: `prep_d`. Model: opus.

## Where you work
Worktree `$SP/wt/prep-d`, branch `3qlq-inc1-matrix`. You touch `tools/loop_twin_matrix.py`,
`tools/inplace_twin_matrix.py`, `tools/angle_select_twin_matrix.py` and their committed
expected/quarantine tables ONLY where the brief says, plus
`docs/prd/phase-04-swap-route-control/inc1-records/{loop,inplace,angle_select}_pre1.txt`.
Nothing under `ir-pass/`, `tests/`, `include/`.

## Read first
The header of each of the three instruments (they are long and explain what each can and
cannot witness), `tools/loop_twin_matrix.quarantine.txt`, and how `e2e-loop-twin-matrix` is
registered in `tests/e2e/CMakeLists.txt` (grep `loop-twin-matrix`). Inc-4 precedent:
`docs/prd/phase-04-swap-route-control/inc4-records/inplace_stateprep_{pre4,post4}.txt` —
the PAIR of tables is the witness; the PRE table is committed BEFORE the lowering exists.

## The surface change
The generators write `a = cq_phi(a, PI)` (register form). After Inc 1 the surface is
`cq_phi(PI)` (void; branch phase) and the pass DELETES an uncontrolled call. Add to each
instrument a flag `--phi-surface {register,void}` (default `register` so every existing
invocation and every committed table is byte-identical — verify by re-running the default on
the ORACLE and diffing against the committed expected tables; report the diff, expected
empty apart from timing). Under `void`, the generator emits `cq_phi(θ)` for every Rz arm
cell and for every "uncontrolled Rz" filler gate, and the C source uses a header with
`void cq_phi(double);` — the instruments take `--include-dir`; point it at a COPY of
`include/CQ.h` under `$SP/progress/prep_d_include/CQ.h` with the 15-width family replaced by
the one extern (do NOT commit a CQ.h change).
Think about what each axis MEANS under the new surface and write it in the header:
- loop matrix: the Rz-arm cells become KICKBACK cells (no gate on the register — the
  "record" axis that pins `int mark = a;` reads across an Rz arm is now vacuous for Rz;
  say so). The Ry-arm cells are unchanged.
- inplace matrix: its whole premise is "controlled-Ry EQUALS routed-Rz"; under the void
  surface the Rz side is a kickback, no longer a route, so the reducer's collapse target
  changes: the Rz side's region is `mint; [x]; rz_i1(f,θ); [x]; strip; free` and the Ry
  side's is `mint; [x]; ry_W_controlled(f,r,θ); [x]; strip; free`. The instrument's
  question becomes "same stream except the ONE gate line" — implement that as the `void`
  reducer and keep the register reducer intact.
- angle-select matrix: the Rz stem's twin is no longer by-difference (PRD §3 "Angle
  select": exact two-gate form, run-time arms admitted for Rz). Under `void` the Rz twin
  must be the manual two-region spelling `if (c) cq_phi(A); if (!c) cq_phi(B);`?? — NO:
  `-O1` may fold that into the same select. Define the twin as the flat pair of
  diamonds with the compare recomputed (`if (q==5) cq_phi(A); if (q!=5) cq_phi(B);`) and
  MEASURE whether -O1 keeps them separate; if it folds them, say so in the header and mark
  the Rz stem's twin as "byte-identity NOT available; the audit substitution (d) is the
  witness". The Ry stem's cells are unchanged.

## PRE tables
Run each instrument under `--phi-surface void` against the ORACLE (subject = oracle, oracle
= oracle) and commit the resulting table as `inc1-records/<name>_pre1.txt`. Expect most
Rz cells to be DECLINE on the oracle (it does not know `void cq_phi`) — that is the
pre-increment disposition and it is the point. Record cell counts per verdict in your
hand-back. Do NOT modify the committed default-surface expected tables or the quarantine.
Anything > 2 min runs in the background (the loop matrix has 274 cells).

## Commit
One commit per instrument, then one for the records. Hand back per BRIEF_common.
