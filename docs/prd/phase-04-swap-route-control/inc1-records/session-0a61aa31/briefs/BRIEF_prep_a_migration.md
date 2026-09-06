# BRIEF_prep_a_migration — Inc 1 prep (a): `tools/migrate_phi_fixtures.py` + the 540-fixture migration
Read `$SP/briefs/BRIEF_common.md` first. Agent name: `prep_a`. Model: opus.

## Where you work
Worktree `$SP/wt/prep-a`, branch `3qlq-inc1-migration` (from main dfb8e83). You touch
`tools/migrate_phi_fixtures.py` (new), `ir-pass/test/*.ll` (existing files only — do NOT
create fixtures for the new lowering; the implementer does), and a report
`docs/prd/phase-04-swap-route-control/inc1-records/MIGRATION_REPORT.md`. You run the ORACLE
binary via the env-var lit invocation in BRIEF_common (no build in your worktree).

## The surface change you are migrating to (PRD §4.1, §6.4)
`cq_phi` becomes `void cq_phi(double)`. In the IR the old calls are
`%r = call T @cq_phi_<sfx>(T %x, double θ)` (16 suffixes: i1 c si8 ui8 si16 ui16 si32 ui32
sl ul sll ull f16 f32 f64 f80). Two cases, decided PER CALL by the pass semantics:
- **UNCONTROLLED / classically-controlled** (the call is not inside the arm of a TAINTED
  `br`/`switch`; a `br` whose condition is derived from a `@cq_theta` result is tainted):
  D2 — it is a global phase. Migration: RAUW `%r → %x`, delete the call, delete the now-dead
  `declare` if unused. (A phi node in the CFG that merged `%r` with `%x` becomes a phi of
  identical incomings — leave it; the pass handles it.)
- **INSIDE A TAINTED ARM**: `call void @cq_phi(double θ)`; the merge φ that carried `%r` vs
  `%x` is DISSOLVED — RAUW the φ to the pred incoming (`%x`), erase it. The
  `declare void @cq_phi(double)` is added once.
Detecting "tainted arm" in a .ll file without the pass: a conservative textual/structural
rule is acceptable ONLY if you VERIFY it — the pass's own answer is the oracle: run the
ORACLE cq-opt with `-debug`-style output? No — simpler: taint = transitive data flow from any
`@cq_theta_*` result through instructions to the `br`/`switch` condition. Implement a tiny
SSA walker over the parsed .ll (use `llvmlite`? — NOT installed; use a regex-based SSA graph
over the textual IR: `%name = <opcode> ... operands`, which is adequate for these fixtures;
document the limits). Fixtures with `@cq_phi_*` inside functions reached through
specialization clones etc.: treat as tainted-arm if unsure and LIST them in the report.

## Steps
1. Measure the population: `grep -l 'cq_phi' ir-pass/test/*.ll | wc -l` (expect 540 of
   1582). Classify each: (U) only uncontrolled calls, (A) at least one in-arm call, (M)
   mentioned only in comments/CHECK lines. Write the table to the report.
2. Write `tools/migrate_phi_fixtures.py` (`--dry-run`, `--apply`, `--only <glob>`,
   `--report`). It rewrites the IR body per the two cases and ALSO rewrites CHECK lines
   mechanically ONLY where the rewrite is certain: `cqrt_rz_<W>` uncontrolled lines →
   deleted (a `CHECK:` for a deleted gate must go, a `CHECK-NOT:` may stay);
   `cqrt_rz_<W>_controlled(` → the kickback triple is NOT mechanically derivable (handle
   numbers change) — mark the fixture `NEEDS-REDERIVE` in the report instead of guessing.
   Header comments mentioning the old API get a one-line `; 3qlq: migrated from register
   cq_phi (<case>)` note, not a rewrite.
3. Apply to the (U) class. For every (U) fixture, run the ORACLE via lit on the migrated
   file: because the deleted uncontrolled `cq_phi` was an in-place diagonal gate on the
   SAME handle, the oracle on the migrated IR must produce the SAME output as the oracle on
   the original MINUS exactly the `cqrt_rz_<W>` lines (and the `declare`s). Verify this by
   diffing `cq-opt -S` outputs, not by lit alone. Fixtures whose CHECKs fail after the
   rewrite: re-derive the CHECK from the ORACLE output on the migrated file (handle names
   DERIVED from the output, never hand-typed — the Inc-4 lesson: 9 of 20 accepts named a
   `%h1` that did not exist), keeping the fixture's PURPOSE (read its header). If the
   purpose WAS the per-register Rz lowering (`lowering_phi_*`, the 2a peephole family
   `control_inplace_rz_*`/`control_swap_*phase*`, the 2b Rz stem `control_angle_select_rz_*`)
   the fixture is REWRITTEN to the new semantics only where the new IR is certain; otherwise
   mark `HAND-DECISION` with a proposed disposition (rewrite / delete with reason) in the
   report — the orchestrator decides; do NOT delete files.
4. Apply the IR rewrite to the (A) class (void call + φ dissolved) but leave their CHECK
   lines untouched and list them as `NEEDS-REDERIVE (needs the Inc-1 binary)`. The
   orchestrator will run you (or a successor) again with the implementer's binary.
5. Invariants your report must state with the command: total files touched; per-class
   counts; number of fixtures whose oracle output on the migrated IR differs from the
   original by MORE than deleted `cqrt_rz` lines (must be 0 for class U — any other diff is a
   FINDING, list it); the `declare` count of `@cq_phi_*` remaining in the corpus (must be 0
   after (A)+(U)).
6. Commit on your branch in two commits: the tool, then the migration. Hand back per
   BRIEF_common.
