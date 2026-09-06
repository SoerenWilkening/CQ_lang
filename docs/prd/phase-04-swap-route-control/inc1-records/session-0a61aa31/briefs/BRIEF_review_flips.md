# BRIEF_review_flips — the 12 DECLINE→ACCEPT flips the fixture migration exposed (Rule-13 narrow lens)
Read `$SP/briefs/BRIEF_common.md`, `$SP/progress/prep_a2.md`, and the migration report on the migration
branch: `$SP/wt/prep-a/docs/prd/phase-04-swap-route-control/inc1-records/MIGRATION_REPORT.md` §14 (the 12
flips), §16 (the 21 kickback-witness mismatches incl. the 4 where the SUBJECT discharges rails the ORACLE
leaked), §12.1, §13.3. Then `$SP/progress/fix_r1.md`, `$SP/progress/impl_inc1a.md`, `$SP/progress/impl_inc1b.md`.
Agent name: `review_flips`. READ-ONLY (never write into any worktree).

## Subject
`$SP/wt/prep-a` at its tip (branch `3qlq-inc1-migration` = merged Inc-1 tip c4bd888 + the migration; its
`build/` is current — verify mtime vs sources). ORACLE `$SP/wt/pre-3qlq` (52d7764). ROUND-1 SUBJECT
`$SP/wt/r1-subject` (fa96336).

## The question, per flip
Each of the 12 fixtures pinned a DECLINE at 52d7764 (old surface) and now ACCEPTS on the subject after a
mechanical migration to the void surface. For EACH: (1) what property did the old decline protect (read the
fixture header + the pass source of the string it pinned)? (2) does that property still exist under the
register-free kickback (e.g. 2b's `fl(A−B)` rounding fence has no object when nothing is subtracted; the §5
const-fold re-anchor has no arg-0 on the phase stem), or does it (e.g. an "impure phase arm" — a phase call
beside a value op — is STILL a mixed arm and must still decline; "nested control flow"/"control flow" on
multi-register or two-phi nests — is the accept a genuine P3/P4 capability or an over-accept)? (3) run the
migrated module on the subject, read the emitted stream and argue the UNITARY per basis branch; STRICT stage 2b;
(4) VERDICT per fixture: `LEGITIMATE-ACCEPT` (rewrite as an accept fixture with derived CHECKs — say exactly
what it must pin) or `OVER-ACCEPT` (a CONFIRMED finding: reproducer, trace, the wrong unitary, the fence that
should fire, proposed fix file:line) or `RETIRE` (the property is unrepresentable — say why).
Then the 4 "subject discharges rails the oracle leaked" traces (§16): confirm each extra `_unc`/`free` pairs a
mint and lands on a provably-|0> rail (argue it), and that the discharge does not remove a rail the program
still reads.
Also §13.3: `diagonalAliasHit`/`walkPhaseSpine` unreachable — confirm by grep that no accept path depends on
them and that their vacuity is in the NARROWING direction.

Write `$SP/progress/review_flips.md`: a 12-row table (fixture | old string | property | verdict | argument),
the 4 discharge rows, and a verdict line; return it.
