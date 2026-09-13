# Merge-and-gate brief — landing 1: Track C (bd `21mg`, branch `classical-measure`) + Track L's L-0 H-10 pins

Instance of `../MERGE_BRIEF_TEMPLATE.md` (read it first; every step applies). Model: opus. Worktree
`/Users/sorenwilkening/Desktop/CQ_21mg`, branch `classical-measure`, review r1 verdict **CLEAR-WITH-ITEMS**
(`review_C_r1.md`), merging `main` at `git -C /Users/sorenwilkening/Desktop/CQ_lang log -1 --format=%h`
(docs-only commits since the branch base 01c89b5 — expect ZERO source conflicts; if `git merge main` reports
any under `ir-pass/`, `tests/`, `include/`, STOP and report). You are the ONLY full-`ctest` runner right now.

## Landing-specific items (step 8 of the template), BEFORE step 3

A. **Apply the review's comment-only items** (no string changes, no predicate changes — if an item needs
   more than a comment, do NOT do it; list it):
   1. `ir-pass/src/MeasureLowering.cpp` ~`:158-160`: the type-mismatch guard's comment must say it REUSES the
      retained string for a case about neither taint nor `i32`, and why (claimed unreachable at HEAD;
      Release-build RAUW type-assert compiled out) — review item 1.
   2. the `kMsgUndefOperand` comment: `valueCarriesUndef` is CONSTANT-ONLY (`LiteralIntegrity.cpp:113-119`);
      the "uninitialized object" ground is broader than the predicate (a φ with an `undef` incoming compiles —
      `review_C_r1_probes/r12_measure_undef_phi.c`); say so, cite the probe — item 2.
   3. `ir-pass/include/MeasureLowering.h` contract: an externally-linked `int api_measure(int x){return
      cq_measure(x);}` now compiles to `ret i32 %x` with zero `cqrt_*` (new public surface; item 3,
      `r27_measure_external_arg.c`); and `cq_measure(cq_measure(q))` emits ONE measurement for both reads
      (idempotent projection — item 5, `r09_measure_of_measure.c`). Two sentences each.
   These are source edits ⇒ the rebuild in step 2 covers them; record the new hash.
B. **Install Track L's L-0 pins** from `$SES/trackL/ready/` (in the MAIN checkout at
   `/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/.../trackL/ready/` — read its `README.md` §"What the landing
   agent still owes"): copy the two `.ll` into `ir-pass/test/`, the two `.c` + `.expected.log` into
   `tests/e2e/`, append `CMakeLists.lines.txt` after `e2e-phase-bool-loop-twin-identical` in
   `tests/e2e/CMakeLists.txt`; re-run `cmake -S . -B build` (new ctest entries need a reconfigure), then
   `lit --filter 'carried_theta_first'` (2 fixtures — they were NEVER lit-validated: fix any FileCheck
   syntax slip WITHOUT changing what is pinned, and say what you changed), the three new ctest entries by
   name, and the injection matrix `ready/README.md` names (report MISSED; a MISSED mutant is a finding to
   fix in the fixture, not to skip). Record the K-independence line by re-measuring it once (lowered IR
   line count at K=3 and K=1000, no `-g`).
C. `cq-opt-equivalence-full`: **OWED** (a new decline string was added).

## Customers (step 7)

* `$SES/trackC/probes/owner_2026-09-11_2218.c`: expected exit 0, stderr 0 bytes, **15 lines byte-identical**
  to `tests/e2e/slice_measure_classical_bool_twin.expected.log`.
* `$SES/probes/va.c`: 19 lines byte-identical to `$SES/probes/va.trace`.
* `$SES/probes/owner_file_2026-09-13.c`: expected DECLINE `control flow` (Track M not landed) — record.
* `$SES/probes/vd.c`: expected DECLINE F2's string — record.

## Corpus (step 5)

The implementer's sweep at `c662bd0ca0e7d8a4` (3021 rows, 1 mover) is a fact about THAT binary; the merged
binary has a new hash (item A) ⇒ run the sweep ONCE on the merged binary, all corpora the template names
PLUS `$SES/trackC/review_C_r1_probes` and `$SES/trackL/probes`. Expected: movers = DECLINE→ACCEPT on
`operand not recognized` only; 0 ACCEPT→DECLINE; 0 both-accept circuit changes.

Record: `$SES/trackC/MERGE_C_1.md` in the worktree + `GATES.md` lines. Final message per the template.
