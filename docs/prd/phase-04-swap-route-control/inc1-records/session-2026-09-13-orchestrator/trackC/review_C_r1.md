# Rule-13 review, round 1 — Track C, bd `21mg` (classical `cq_measure`)

Independent reviewer, 2026-09-13. Worktree `/Users/sorenwilkening/Desktop/CQ_21mg`, branch
`classical-measure`. **NO build, NO suite run** (PROTOCOL "review" row). 36 probes, both binaries,
`review_C_r1_probes/run_r1.sh` → `review_C_r1_probes/results_r1_c662bd0ca0e7d8a4.txt`.
One `lit --filter` allowance UNUSED — no fixture claim I doubted survived reading the fixture.

## VERDICT: **CLEAR-WITH-ITEMS** (6 items, none a miscompile, none blocking)

## Build-side obligation (the only gate this row owes)

`ran: shasum -a 256` in the worktree — `cq-opt c662bd0ca0e7d8a4db70bc8b410521e1ea946098ccce702d0c2c0ed2b2a1761b`,
`libCQPass.so 52d1136c3c7d9049bf0d6de95b84cfe2c3f353a54457b9c30b5c655feb60a510`; ORACLE
`fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661` /
`40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93`. **All four match `GATES.md`.**
No finding. Every other line in `GATES.md` is `cited:`, not re-run.

## Item 1 — which RAUWs does the taint set follow? (the silent-miscompile shape)

**Answer: all of them, by three disciplines that hold across the whole window, and no quantum
register reaches `lowerMeasures` under an untainted SSA name in any shape I could build.**

1. **Every Phase-2 lowering RAUW is paired with an insert.** `ArithLowering.cpp:51`,
   `CastLowering.cpp:40`, `CompareLowering.cpp:48`, `IntrinsicLowering.cpp:205`,
   `RotationLowering.cpp:381` (source mint) — and the `Chained` arm needs none, because
   `Handle = Op` is the operand that was already tainted (`RotationLowering.cpp:453`).
2. **Every control / loop / memory emitter RAUWs a merge φ either to a PRE-EXISTING tainted rail
   root or to an `%out` it inserts.** Roots: `SwapRouteEmit.cpp:1295/:1534` (M-α → `Q`),
   `:1105` (M-β → `Gates.back().first`, a HOISTED `@cq_theta` call, which `propagate` seeds),
   `RegionFlatten.cpp:164` (→ the Pred incoming `Q`), `LoopLowering.cpp:1780/:2353/:2747/:2818`
   (→ `Root` / `railRoot[P]`), `TaintPropagation.cpp:1245` (→ `Chains[0].Base`). Minted+inserted:
   `SelectMergeEmit.cpp:255`, `SwitchValueEmit.cpp:293`, `SwitchDataMuxEmit.cpp:144`,
   `ClassicalCallArmEmit.cpp:216`, `IOSinkLowering.cpp:786`, `QramLowering.cpp:1801/:2106`,
   `LoopLowering.cpp:1763`.
3. **`Tainted` is only ever ERASED for a value erased from the IR in the same breath** — every
   `scrubTaint()` site is immediately followed by `eraseFromParent()`, and the one bare erase that
   is not a scrub (`ArithLowering.cpp:1021`) erases the out-of-place rail call it then deletes
   (`:1026`). So no LIVE SSA name loses taint. The residual worry — a condition compare scrubbed by
   `RegionFlatten.cpp:97/:190/:194` while a measure keeps it alive — does not materialise: the
   compare is lowered to a flag handle by `CompareLowering` and measured through it
   (`r13`/`r15`: `%h_cmp = call i32 @cq_template_icmp_eq_i32_hl(...)` then
   `call i1 @cqrt_measure_i1(i32 %h_cmp)`, byte-identical on both binaries).

**Measured.** 25 of 36 probes are BYTE-IDENTICAL ORACLE vs SUBJECT (same exit, same diagnostic, same
lowered-IR md5), including every quantum shape the brief names: 6.5 `%out` (`r01`) and a value
DERIVED from it (`r30`); the 4.4 select merge (`r02`); the value-arm controlled-copy merge (`r03`);
the 4.5 switch merge (`r04`); the in-place controlled-Ry merge, M-β (`r05`); controlled state prep,
M-β (`r06`); a collapsed in-loop rail (`r07`); a depth-2 nest merge, `RegionFlatten` (`r08`); a
phase/value region condition flag (`r13`/`r14`/`r15`); a quantum value through a local array
(`r23`), a tainted-index QRAM read (`r24`) and a guarded shadow store (`r25`). All 11 movers are
DECLINE→ACCEPT on the 21mg string with a genuinely classical operand (below).

## Item 6 — the erase order vs the `MeasureCalls` readers

**Answer: safe, and the exposure is unchanged from HEAD.**

* `taint.MeasureCalls` has exactly ONE producer (`TaintPropagation.cpp:144`) and the whole `TaintSet`
  is REASSIGNED on every re-propagation (`taint = propagate(M, wd)`, 16 sites in
  `CQLoweringPass.cpp`) — so no entry is ever collected twice and `ToErase` cannot double-erase.
* Every reader runs strictly BEFORE `lowerMeasures` (`CQLoweringPass.cpp:647` in `run`, `:987` in the
  `runOnFunction` shim): `ArmClassify.cpp:2207/:2957`, `SelectClassify.cpp:331`,
  `SwitchClassify.cpp:322/:575`, `SpecializeDetect.cpp:44`, `SpecializeReject.cpp:71`,
  `TaintPropagation.cpp:649` (`declineTaintEscapes`), `:1564` (`propagateFromSeeds`), `:1689`
  (`repropagateControlMerges`), and the `onlyInF`/passthrough uses in `CQLoweringPass.cpp:125/757/
  792/838-895`. **`uncompute` (`:677`/`:997`), `lowerBreakReversePlay`, `lowerLateReassignments`,
  `FreePoint` and `ChainWalk` do not read `MeasureCalls` at all** — grep is exhaustive above.
* HEAD already RAUW'd and erased every entry on the quantum path, so the classical path adds no new
  class of dangling entry; it only adds members.
* The pre-existing dangling hazard — a stray `cq_measure` in an arm block `RegionFlatten` erases
  (`ArmClassify.cpp:175-187`) — is fenced by `armBlockIsPureSpine`, and I could not get past it:
  `r33`–`r36` (phase arm unused / phase arm used / 6.5 arm / if-else else-arm), plus `r19` (switch
  case) and `r21` (select operand) ALL decline, identically on both binaries.

## Findings

| # | grade | finding | reproducer |
|---|---|---|---|
| 1 | DOC | The classical type-mismatch guard reuses the retained string `…expected a tainted i32 handle` for a case that is about neither taint nor i32. Claimed unreachable (and the argument is sound), but if it ever fires the message misdirects. | `ir-pass/src/MeasureLowering.cpp:158-160` |
| 2 | DOC | `valueCarriesUndef` is **CONSTANT-ONLY** (`LiteralIntegrity.cpp:113-119`), so verdict (a) catches `cq_measure(undef/poison)` and undef nested in a constant — a `phi`/`select` with an undef arm is an ACCEPT. The fixture header's ground ("reaching one means the source read an uninitialized object — UB in C, no circuit to emit") is broader than the predicate: `int u; if (q==3) u=4; cq_measure(u)` is exactly that UB and compiles (−O1 folded the φ to 4). Bound the claim to the literal shape (L5). | `review_C_r1_probes/r12_measure_undef_phi.c` |
| 3 | DOC | New public-surface behaviour, unrecorded: an externally-linked `int api_measure(int x){return cq_measure(x);}` now compiles to `ret i32 %x`, zero `cqrt_*`. Sound (a handle cannot cross a TU; an in-module quantum caller declines `cq specialization: callee measures under quantum lift`, `r17`), but it should be stated. | `review_C_r1_probes/r27_measure_external_arg.c`, `r17_measure_in_noinline.c` |
| 4 | OVER-DECLINE (confirms §7 F-3, **with a caution**) | The in-arm classical measure declines on two strings by shape — `control flow under quantum control` (`r19`, `r33`, `r36`) and `value-arm swap-route under quantum control` (`r21`, `r34`, `r35`, `c7`) — identical on both binaries. ⚠ F-3's ground ("the hoist is inert under 21mg") is only half of it: `armBlockIsPureSpine`'s other reason is that `RegionFlatten` ERASES the arm block, leaving the stray call's `taint.MeasureCalls` pointer dangling into `lowerMeasures` (`ArmClassify.cpp:175-187`). Admitting the shape owes a scrub of that entry, not only a hoist argument — please carry this into the bd issue. | `review_C_r1_probes/r33..r36,r19,r21` |
| 5 | DOC | `cq_measure(cq_measure(q))` now emits ONE measurement and returns its outcome for both reads (M=1). Right — a projective measurement is idempotent — but it is an unstated semantic ruling; `lowering_measure_classical_mixed_accept.ll`'s `f_measure_of_measure` pins the shape without saying why one line is the right number. | `review_C_r1_probes/r09_measure_of_measure.c` |
| 6 | LEAK (pre-existing, out of scope) | Measuring a tainted compare's flag leaves both `%h` and `%h_cmp` allocated with no `cqrt_free`. Byte-identical on the ORACLE, so not this change's; recorded because this review generated the shape. | `review_C_r1_probes/r13_measure_phase_cond.c`, `r15_measure_cmp_only.c` |

## The other brief items

* **Item 2 (the i32-handle world).** `cq_measure(m+1)` of a measure result, `cq_measure(cq_measure(q))`,
  a `cq_theta` arg-0 seed also measured, a classical `double` angle measured, a classical
  `float`/`long double`, a global, a volatile local, a classical array element — all classical, all
  correct, and **none mints a rail**: `r11` and `r22` emit `cqrt_alloc_i32` only (for `q`), no
  `cqrt_alloc_f32/f64/f80`. That is the Rule-3 property that matters here and it holds.
* **Item 3 (the undef fence).** See finding 2. The new string appears nowhere else in the tree and the
  fixture mirrors it character-for-character; the fixture is RED on the ORACLE for the right reason
  (the old blanket string), and its `NOCLASSICAL-NOT` lines are correctly labelled as Rule-12 (b)
  decoration behind the `not` inversion.
* **Item 5 (the round-2 window, L1).** Discharged by ORDER and verified by reading BOTH entry points:
  `repropagateControlMerges` at `CQLoweringPass.cpp:489` / `:948`, `lowerMeasures` at `:647` / `:987`.
  Constructed through C, not only hand IR: `r01` (the 6.5 `%out` measured) and `r30` (a value derived
  from it) both emit `cqrt_measure_i32` and are byte-identical to the ORACLE. The retirement trigger
  is written into the source header, which is the right place for it (L8).
* **Item 7 (trace/golden contract).** `git diff --stat -- tests/e2e/*.expected.log` is EMPTY — no
  committed golden changed. The two new goldens are byte-identical (15 = 15) and
  `slice_measure_classical_only.expected.log` is 0 bytes. The "DECLINE→ACCEPT only" claim is
  structurally airtight, not lucky: at HEAD `!(i32 && Tainted)` declined UNCONDITIONALLY, so no
  module that accepted could contain an untainted measure operand — which is why the sweep's
  "0 both-accept md5 differences" over 3021 rows is the expected result.
* **Item 8 (F-5).** Confirmed behaviourally, not just by reading: every decline probe here produced
  `exit=1`, exactly one `error:` line and no output file. No fixture in this change asserts two
  diagnostics; the undef fixture explicitly refuses a second function for this reason, which is the
  right call.
* **Item 9 (over-declines in passing).** O-2 confirmed: both retained diagnostics render
  `<unknown>:0:0` even with `-g` (every mover row above), while the new one is source-located
  (`c6_undef_bool.c:3:33`). It is a Rule-1 gap in a RETAINED string, unchanged by this increment, and
  leaving it alone was correct — the brief pins it character-for-character. F-3 → finding 4. F-4
  (`SpecializeReject.cpp:71` still counts a classical measure as a quantum primitive) confirmed by
  reading and correctly graded "no action": the classification runs before `lowerMeasures`, so it
  cannot see the disposition, which is the L1 shape again.

## What I did NOT do

No build, no `ctest`, no `lit`, no corpus re-run; `GATES.md` is cited for all of those. The 11 movers
were re-derived from source here rather than read out of `corpus_c662bd0ca0e7d8a4.txt`, and the one
corpus mover the implementer reported (`trackL/probes/t_loop_phase.c`) was read and confirmed benign:
its `cq_measure(a)` is on `int a = 5`, never written by anything quantum.
