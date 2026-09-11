# Fix brief — l4x4.b, after round-1 Rule-13 review `review_l4x4b_r1.md` (verdict CLEAR-WITH-ITEMS)

Worktree `/Users/sorenwilkening/Desktop/CQ_l4x4`, branch `l4x4b-bool-ry-arm` (checkpoint 267937d). Read
`review_l4x4b_r1.md` in full (F-1..F-5, ITEM 1 the spine, ITEM 2 the gate order), then `IMPL_l4x4b.md`,
`BRIEF_l4x4b.md`, `SCOPE_l4x4.md` §2.3, and the reviewer's `review_l4x4b_r1_probes/` (3 runners, README).
You are the FIX agent (opus). Do NOT commit/push; never write under `/Users/sorenwilkening/Desktop/CQ_lang/`
or the other worktrees; ORACLE `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`, F2-BASE
`/Users/sorenwilkening/Desktop/CQ_f2/build/ir-pass/cq-opt` (both read-only). Report only what you ran.

## F-1 — OVER-ACCEPT-ARGUED: a NON-FINITE angle on the NEGATED form (fix before landing)

`if (!b) r = cq_theta(r, __builtin_inf());` emits `ry(h1,+inf); ry_controlled(h,h1,-inf)`, so on the `b=1`
branch — where the source is the IDENTITY — the register gets `Ry(−∞)Ry(+∞)` = NaN; same for NaN. The
sibling emitter that duplicates an angle, `angleSelectArmsAdmissible`, already refuses non-finite
`ConstantFP` arms; l4x4.b's value clause (`ArmClassify.cpp:2976`) asks `valueCarriesUndef` only.

Decision (orchestrator): (a) CONSTANT non-finite angle on the negated form → DECLINE, one conjunct
(`isFinite()` on the `ConstantFP`, reuse `angleSelectArmsAdmissible`'s spelling or its helper — one
spelling), string mirrored from the angle-select family's non-finite decline if it fits, else a new one
`negated rotation arm with a non-finite angle`; decline fixture (RED on 267937d) for `inf` and `NaN`, plus
the `-inf` and `−0.0`/`0.0` ACCEPT controls (zero is finite: `Ry(0)Ry(−0) = I` exactly). (b) RUN-TIME
angle → keep ACCEPTING with additivity. Argument to write at the clause and in IMPL §7: `fneg` cannot
manufacture a non-finite value from a finite one (unlike Inc-2b's `fsub`, which overflows from two FINITE
arms — the F-11 structure does NOT transfer), so the only failing input is a NON-FINITE angle, which is an
ill-formed CQ program in EVERY spelling (`Ry(NaN)` on the taken branch of the compare twin too); the
negated form additionally corrupts the untaken branch of an already-ill-formed program. Record as a
RESIDUAL with the alternative that removes it entirely (the `CopyRailRoot` ancilla + `cqrt_x` bracket on
the ANCILLA, SCOPE §2.3's option, 4 extra gates + 1 ancilla, exact for every angle) as an OWNER OPTION — do
not build it.

## F-2 — l4x4.c filed by the orchestrator (grep `bd list` for "l4x4.c"); no code. Add the reviewer's
sentence ("compiles in no spelling on any binary") to the `:2940` fence comment and IMPL §7.

## F-3 — pre-existing, already filed by the orchestrator (grep `bd list` for "hcrg precedence graph");
no code; a README line in `probes/`.

## F-4 — DOC: `probes/impl/p5` accepts on subject AND `main` (`-O1` folds it to r9e5's rail data-select),
`p6` is a plain `cq_phi` kickback — IMPL §1 cites both as the measurement for two §2.6 rows; replace the
citations with the hand-IR fixtures that actually pin those rows (name them) and correct the README.

## F-5 — DOC: the VALUE class on a rail can decline `value-arm swap-route` (clauses above `:3971`), not only
`bare i1 register condition`; fix SCOPE §2.6's table (an ERRATA line) and the IMPL partition text; make
sure the fixture for that row mirrors the string that actually fires.

## H-9 — DOC (from ITEM 1): write at the `isTerminalHandle` / `preservesBasisUnderRecord` site that a rail
leaf's register ALWAYS carries an uncontrolled `cqrt_ry_i1`, which `preservesBasisUnderRecord` refuses
independently of the `_controlled` list — the second, stronger reason the spine never claims `b`.

## Gates, in order

`lit --filter` → `ctest -R ir-pass-lit` → `ctest -j6 -R '^e2e-'` + `git status --porcelain tests/` →
three-way corpus diff (F2-base vs subject: the same 2 movers, no others) → both probe corpora re-run →
full `ctest -j6` ONCE (a predicate changed; never relink under a measurement, never `pkill` by pattern) →
`cq-opt-equivalence-full` if a string was added. Write `FIX_l4x4b_R1.md`: per item → change (file:line)
→ fixtures → measurements; open questions.

Final message ≤20 lines: per item one line, gate lines verbatim, movers, open questions.
