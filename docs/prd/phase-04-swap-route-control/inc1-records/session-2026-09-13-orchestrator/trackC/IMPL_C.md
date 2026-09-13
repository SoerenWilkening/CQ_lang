# IMPL — Track C, bd `test_C_libtooling-21mg`: `cq_measure` of a value that never became quantum lowers to the CLASSICAL VALUE, no gate

**Implementation record.** Branch `classical-measure`, worktree
`/Users/sorenwilkening/Desktop/CQ_21mg`, from `main` **01c89b5**. **Not
committed, not pushed.** ORACLE = `/Users/sorenwilkening/Desktop/CQ_lang/build`
(`cq-opt` `fbbe0820…`, `libCQPass.so` `40e9c7a5…`, built from e96f89c) —
re-hashed before first use, matched PROTOCOL.md, never rebuilt. SUBJECT =
`cq-opt` `c662bd0c…`, ONE build (no pass source touched after it).

> **Bottom line.** (a) **The owner's 2026-09-11 22:18 file compiles**: `opt`
> exit 0, empty stderr, STRICT 2b clean, and its 15-line trace is **BYTE
> IDENTICAL** to the `cq_measure(b1)`-less twin's — whose golden the ORACLE
> reproduces byte-for-byte, so the identity is measured against the previous
> compiler's stream, not one this change invented. (b) The change is **one
> predicate in one function**, gated on TAINT and nothing else. (c) **Verdict (d)
> — the round-2 rail measure — is discharged by ORDER, not by a new predicate,
> and the shape's lowered IR is md5-identical on both binaries.** (d) **Verdict
> (i) of the brief could not be written as a fixture, and the reason is a
> measured fact about the pass, not a shortcut**: the first `DS_Error` calls
> `exit(1)`, and every route to a tainted non-`i32` measure operand already
> exits earlier — §2 (i). (e) The injection matrix found **6 real holes in my own
> first-draft fixtures** (an injected `cqrt_measure_i1`, an injected
> `cqrt_alloc_f64`, a dropped `cqrt_alloc`, and stray `cqrt_x`/`cqrt_free`),
> every one of which is now caught; final **29 mutations, 0 MISSED, 0 DIRTY**.

---

## §0 MEASURED FIRST — the ORACLE on every probe, before a line was written

Probes are in `probes/` (this directory). Pipeline per PROTOCOL.md §"Per-probe
pipeline", `-g` on so a diagnostic is source-located where the site attaches one.

| probe | shape | ORACLE | SUBJECT |
|---|---|---|---|
| `owner_2026-09-11_2218.c` | **THE CUSTOMER** — the owner's file, second region commented out, `bool b1 = 0;` never assigned and measured | exit 1, `cq_measure_<sfx> operand not recognized; expected a tainted i32 handle` | **exit 0**, 15 trace lines, STRICT 2b `5 rail mint(s) of which 4 left allocated, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven` |
| `owner_twin_no_b1.c` | **THE WITNESS** — the same file with `cq_measure(b1)` deleted | exit 0, 15 trace lines, same 2b line | exit 0, **trace byte-identical to the ORACLE's** |
| `c1_const_bool.c` | `bool b = 0; return cq_measure(b);` (no theta in the module) | exit 1, same string | exit 0 |
| `c2_const_i32.c` | constant `i32` | exit 1, same string | exit 0 |
| `c3_classical_ssa.c` | `n + 3` of a runtime argument | exit 1, same string | exit 0 |
| `c4_classical_double.c` | `x * 2.0`, f64 width | exit 1, same string | exit 0 |
| `c5_classical_phi.c` | an if/else `-O1` folded to a **`select`** (see §7 O-1) | exit 1, same string | exit 0 |
| `c6_undef_bool.c` | `bool b; return cq_measure(b);` — operand is literally `i1 noundef zeroext undef` | exit 1, same string | **exit 1**, `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value`, at `c6_undef_bool.c:3:33` |
| `c6b` (`i32 poison`, scratch) | the poison spelling | — | exit 1, the same new string |
| `c7_measure_in_arm.c` | a CLASSICAL measure inside a tainted VALUE arm | exit 1, `cq controlled lowering: value-arm swap-route under quantum control`, `CQ_CTRL_DBG` names the offending instruction as the `cq_measure_si32(i32 noundef 3)` call | **identical, unchanged** |
| `c8_theta_and_classical.c` | a quantum measure and a classical measure in one function | exit 1, the measure string | exit 0 |

Two facts established in §0 that shaped everything after:

**F-1. `LLVMContext::diagnose` exits the process at the FIRST `DS_Error`.** Not
an inference — measured: `t_vec.ll` (a tainted value into `insertelement`)
declines at `declineTaintEscapes` and **writes no output file at all**, though
`declineTaintEscapes` has no early return and `lowerMeasures` runs ~300 lines
later. This is why (c) is unchanged by ORDER rather than by a predicate, and why
(i) has no fixture.

**F-2. `cq_measure_<sfx>` is type-preserving, and it is ENFORCED, not just
declared.** `include/CQ.h:77-112` declares all 14 as `T (T)`;
`TaintPropagation.cpp` `declMatchesPrototype` + `resolveSources` REFUSE to
collect any reserved-name decl whose `FunctionType` is not exactly that. So no
`zext`/`trunc` is owed by the classical path (the brief's conditional), and
`Measure->getType() == getArgOperand(0)->getType()` holds for every collected
call in any IR LLVM will parse.

---

## §1 THE CHANGE — one predicate, one function

**`ir-pass/src/MeasureLowering.cpp`, the per-call body of `lowerMeasures`.** The
only pass file with a code change; `ir-pass/include/MeasureLowering.h` is
comment-only (its contract paragraph described a lowering that no longer exists —
leaving it would be exactly the L7 hazard).

BEFORE — one predicate, three meanings collapsed into one decline:

```cpp
    Value *Handle = Measure->getArgOperand(0);
    if (!(Handle->getType() == I32 && taint.Tainted.count(Handle))) {
      … "cq_measure_<sfx> operand not recognized; expected a tainted i32 handle"
      continue;
    }
```

AFTER — the split is on TAINT and nothing else (Rule 3), asked FIRST:

```cpp
    Value *Handle = Measure->getArgOperand(0);
    if (!taint.Tainted.count(Handle)) {          // (1) CLASSICAL
      if (valueCarriesUndef(Handle))  → kMsgUndefOperand, loud, continue
      if (Handle->getType() != Measure->getType()) → kMsgOperand, loud, continue
      Measure->replaceAllUsesWith(Handle); ToErase.push_back(Measure); continue;
    }
    … suffix → abiWidthFor → measureRtFn  (unchanged, and now INSIDE (2))
    if (Handle->getType() != I32)                // (2) TAINTED, unlowerable
      → kMsgOperand, loud, continue;             //     string UNCHANGED
    … CreateCall(cqrt_measure_<W>, {Handle}) …   //     the quantum measure
```

Three deliberate structural points:

* **The runtime-symbol resolution MOVED inside branch (2).** It is not cosmetic:
  `wd.measureRtFn(W)` **lazily declares `@cqrt_measure_<W>` in the module**, so
  resolving it for a classical measure would leave an unused runtime declaration
  in a module with no quantum content. Pinned by
  `lowering_measure_classical_accept.ll`'s `NOALLOC` prefix and by
  `e2e-slice-measure-classical-only`'s EMPTY golden. The `!MeasureRT` branch is
  unreachable for collected calls either way (every collected measure resolved
  through the 14-name surface), so nothing reachable changed order.
* **`valueCarriesUndef` is CALLED, not re-derived** (Rule 14) — the one spelling
  `LiteralIntegrity` owns, already the fp-select arm fence's and `PredMuxFlatten`'s.
* **The RAUW is dominance-safe by construction**: `Handle` is already an operand
  of `Measure`, so it dominates `Measure`, which dominates every use rewritten.
  Order-independent too — see the `f_measure_of_measure` argument in
  `lowering_measure_classical_mixed_accept.ll`'s header.

---

## §2 THE (a)–(e) VERDICTS

### (a) `undef` / `poison` operand → **LOUD DECLINE**, new string

`cq_measure_<sfx> operand is an undef/poison literal; a classical measurement
needs a defined value`, with `!dbg` (Rule 1 — see §7 O-2 on the retained string,
which has none). Three grounds, in order of weight:

1. An `undef` is **not a value**. At the `-O0` stage 3 one `undef` token may be
   materialized differently at each use — the exact reasoning
   `declineUnpairedUndefLiterals` ships for gate slots — so the outcome this
   "measurement" reports is not reproducible and the golden byte-diff contract
   (Rule 2) has nothing to pin.
2. The frontend already says so: every `cq_measure_<sfx>` parameter carries
   `noundef`, so an `undef` there is a contract violation.
3. Reaching one means the source read an uninitialized object — UB in C. There is
   no circuit, trivial or otherwise. Over-declining is safe; a silently arbitrary
   measurement outcome is the unforgivable direction.

It is a **real C customer, not hand IR**: `bool b; return cq_measure(b);`
(`c6_undef_bool.c`). `poison` is the same predicate (`PoisonValue` derives from
`UndefValue`, and `valueCarriesUndef` also descends into `ConstantExpr`
/aggregates); it is measured as probe `c6b` rather than given a second function
in the fixture, because F-1 means a second function's diagnostic would never be
reported and would pin nothing.

### (b) a classical `phi` / `select` operand → **lowers to the value**

It is classical: no quantum lineage reaches it, so nothing quantum is touched and
the measurement is the identity. `f_phi` and `f_select` in
`lowering_measure_classical_accept.ll`; `f_select` is the one that matters in
practice because `-O1` folds the source if/else of `c5_classical_phi.c` into a
`select` (§7 O-1). No interaction with `declineClassicalMuxes`, which
adjudicates a live select/phi over **tainted** data only.

### (c) a classical measure INSIDE a tainted region's arm → **KEEP the ORACLE's verdict**

**Measured, both binaries, identical**: `cq controlled lowering: value-arm
swap-route under quantum control`, from `classifyArms`; `CQ_CTRL_DBG=1` names the
offending instruction as the `cq_measure_si32` call itself. It is NOT `operand
not recognized`, so the brief's rule applies verbatim: keep it. It is unchanged
**by ORDER** (F-1): the decline fires inside `detectControlRegions`, and the
process exits there. Pinned as a boundary by
`control_reject_measure_classical_in_arm.ll`.

Why it is not a defect this increment must fix, and why it may be one later: for
a measure of a TAINTED handle the refusal is a Rule-5 unitary hazard (the value
arm's emitter HOISTS the arm's chain into the pred, so the measurement would fire
on the inactive branch). For a CLASSICAL one the hoist is **inert** under this
change — it emits no gate, no rail, no trace line. So it is a candidate
over-decline; filed in §7 (F-3) rather than fixed, because admitting it means
teaching the ARM classifier a disposition `lowerMeasures` has not computed yet,
which is the L1 round-2 hazard in miniature.

### (d) classical at round 1, TAINTED at the round-2 fixpoint → **a MEASURE, discharged by ORDER**

Read, then measured, then pinned.

* **Read**: `CQLoweringPass.cpp` — `repropagateControlMerges` at **:489**,
  `lowerMeasures` at **:647** (`run()`); :948 and :987 (`runOnFunction()`). Both
  entry points, measure after fixpoint. So `taint.Tainted` is FINAL at
  `lowerMeasures` and a round-2 rail takes branch (2).
* **Where such a value comes from**: `ClassicalCallArmEmit.cpp:226` is the **only**
  writer of `taint.UntaintedMergeRails`, i.e. the 6.5 classical-call arm's `%out`.
  That is the round-2 reseed set.
* **Measured**: the shipped two-TU slice
  `tests/e2e/classical_call_under_control_caller.c` *already* measures that rail
  (`int y = q; if (q>5) y = ext_f(7); return cq_measure(y);` → `cqrt_measure_i32(h2)`),
  and the single-module fixture I added for it lowers to an **md5-identical
  module on ORACLE and SUBJECT** (`5d6141cce479445e1e7f4fe57195c24b` both).
* **Pinned**: `lowering_measure_round2_sixfive_handle.ll`, whose header carries the
  RETIREMENT TRIGGER — if `lowerMeasures` is ever hoisted above
  `repropagateControlMerges`, the measure degrades into a classical passthrough
  **of an i32 rail handle**: the user's measurement vanishes, the trace loses a
  line, and `opt -verify` is perfectly clean. The `MCNT` count and the `NOBARE`
  line are what go red. The same trigger is written at the change site.

### (e) other `taint.MeasureCalls` consumers — does any assume a rail?

**No.** Enumerated by `grep -rn MeasureCalls ir-pass/`, every non-`MeasureLowering`
reader, with what it does with an entry:

| site | use | safe for a CLASSICAL entry? |
|---|---|---|
| `CQLoweringPass.cpp:125,757,794` | `MeasureCalls.empty()` passthrough early-out | **required**: a classical-only module must NOT be a passthrough, or `lowerMeasures` never runs. Witnessed by `e2e-slice-measure-classical-only` |
| `CQLoweringPass.cpp:792,838,848,861,872,877,890,895` | `onlyInF(taint.MeasureCalls)` — per-function filtering in `runOnFunction` | yes, filtering by parent function only |
| `TaintPropagation.cpp:649` | `IntrinsicCalls` — exempts intrinsic call sites from `declineTaintEscapes`' unknown-callee rule | yes; the guard only asks about users of TAINTED values, and a classical measure is not one |
| `TaintPropagation.cpp:1564, 1689` | rebuild the `MeasureFns` **callee-Function** set for the shared work-list's sink rule | yes — it reads `CI->getCalledFunction()`, never the operand |
| `ArmClassify.cpp:2207` (`railMeasuredBeforeReadPoint`) | walks users of each RAIL WIRE NAME and asks `Sinks.count(M)` | yes: the walk is seeded from tainted rail names, which a classical measure is not a user of |
| `ArmClassify.cpp:2957` (`condDataUseDisposition`) | walks forward from the tainted `Cond` | same |
| `SwitchClassify.cpp:322, 575` (G10) | walks users of the tainted scrutinee `Q` | same |
| `SelectClassify.cpp:331` | walks `Op`'s tainted lineage | same |
| `SpecializeDetect.cpp:44` (`intrinsicSites`) | the SKIP set — intrinsic call sites are never specialization candidates | yes, and desirable: a `cq_measure(<classical>)` must not be Bennett-lifted as a classical call |
| `SpecializeReject.cpp:71` (`S.Measures`) | "this callee contains a quantum primitive" | unchanged verdict (a pre-existing decline of a lifted callee containing any `cq_*`); noted in §7 F-4 |

Three more readers that recognize a measurement by **runtime symbol name**, not
by `MeasureCalls`, and therefore see nothing at all from a classical measure
(which emits no symbol): `ChainWalk.cpp:617` and the `FreePoint` `Measured` case
(`cqrt_measure_` prefix, and they run AFTER `lowerMeasures`),
`IOSinkLowering.cpp:179` (`cq_measure_` prefix, but only as a "safe co-user" of a
**rail**), and `LoopLowering.cpp:521` `isMeasureCall` (used at :2248 on TAINTED
body instructions and at :2266 on users of RAIL values — a classical measure is
neither). `staleRailRecordRead` does not read `MeasureCalls` at all.

### (i) the RETAINED decline — tainted operand, not an `i32` handle

Kept, string character-for-character. **It has no `.ll` fixture, and that is a
measured finding rather than an omission.** The brief expected "hand IR: a
tainted `i64` that never lowered"; no such input exists at HEAD. Every lowering
that SUCCEEDS on a tainted value yields an `i32` handle (RAUW), and every
lowering that FAILS raises a `DS_Error`, which by F-1 exits the process before
`lowerMeasures` runs. Six shapes probed on the ORACLE, all in `probes/`-adjacent
scratch:

| shape | result |
|---|---|
| `frem double` on a tainted f64, measured `f64` | exit 0 — operand is the `i32` result of `cq_template_frem_f64_hl` |
| `fdiv double` likewise | exit 0, i32 |
| `@llvm.sqrt.f64` on a tainted f64 | exit 0 — `cq_template_sqrt_f64`, i32 |
| `fptrunc`/`fpext` round trip | exit 0, i32 |
| one-register `phi i64` lift, measured `sll` | exit 0, i32 |
| `freeze i64` of a tainted theta | exit 0, i32 |
| `insertelement`/`extractelement` (to force a NON-lowering) | exit 1 at `cq taint escape: tainted value reaches an unsupported instruction` — **and no output file**, i.e. the process was gone before `lowerMeasures` |
| `select i1 %c, i64 %q, i64 %q` | exit 1 at `cq taint escape: tainted value muxed by a classical-condition select` |

So the branch is a **postcondition check**, and it is recorded as one at the site,
with the backstop named (`declineSurvivingIntrinsicCalls`, Rule 1's checked
postcondition, catches the surviving call anyway). The predicate's real Rule-12
obligation — *a TAINTED operand must not take the classical branch* — IS pinned,
by every quantum accept in the tree and specifically by
`lowering_measure_classical_mixed_accept.ll` (`MCNT-COUNT-2`) and
`lowering_measure_round2_sixfive_handle.ll` (`MCNT-COUNT-1` + `NOBARE`).

The same argument covers the third guard I added, `Handle->getType() !=
Measure->getType()` on the classical path: unreachable by F-2, kept LOUD on the
**retained** string rather than given a new one (a new string with no reachable
input would be a Rule-12 fixture that pins nothing), and kept at all because the
alternative in a **Release** build — where `replaceAllUsesWith`'s type assert is
compiled out and Release is what every gate here runs — is a RAUW of a mistyped
value.

---

## §3 RED-GREEN LOG

Declines first, each RED on the ORACLE for the right reason before the code
existed; accepts second. Every line ran as
`cd build && lit -v ir-pass/test --filter '<name>'`; the ORACLE column was run by
hand (`"$ORACLE/build/ir-pass/cq-opt" … | FileCheck <fixture>`) because the
ORACLE `build/` is read-only and lit writes `%t` files into its tree.

| # | fixture | ORACLE | SUBJECT |
|---|---|---|---|
| D1 | `lowering_reject_measure_undef_operand.ll` | declines on the **wrong string** (`operand not recognized`) → FileCheck rc=1, **RED** | PASS — declines on the undef string |
| D2 | `control_reject_measure_classical_in_arm.ll` | declines `value-arm swap-route under quantum control` | PASS — **same string**, the boundary pin |
| A1 | `lowering_measure_classical_accept.ll` (7 functions: const i1, const i32, `add`, `fmul` f64, `phi`, `select`, argument) | exit 1, `operand not recognized` → **RED** | PASS |
| A2 | `lowering_measure_classical_mixed_accept.ll` (quantum + classical in one function; measure-of-measure) | exit 1 → **RED** | PASS |
| A3 | `lowering_measure_round2_sixfive_handle.ll` (the (d) pin) | exit 0, **GREEN, all prefixes** — and the module is **md5-identical** on both binaries | PASS |
| A4 | `control_measure_classical_bool_owner.ll` (the owner's `-O1` `main`) | exit 1, `operand not recognized` → **RED** | PASS |

Count prefixes, per Rule 12 (a) — counts in their OWN whole-file prefix,
negatives pure: `MOD` / `NOMEAS` / `NOALLOC` / `NOINTR` / `ACC` (A1);
`MCNT` / `ACNT` / `NOINTR` / `ACC` (A2); `MCNT` / `NOBARE` / `XCNT` / `FCNT` /
`ACNT` / `ACC` (A3); `ACNT` / `MCNT` / `XCNT` / `FCNT` / `ACC` (A4);
`NOCLASSICAL` (D1); `NOGATE` (D2). Rule 12 (b) is written into both decline
fixtures: a `DS_Error` writes 0 bytes to stdout, so the property is pinned by the
`not` inversion on the RUN line and the `-NOT`s only NAME a regression.

---

## §4 INJECTION MATRIX — `probes/inject_C.py`

Adapted from `session-l4x4/probes/impl/inject.py` (Rule 14). Nine mutations on
the LOWERED stream of each of the four accepts, re-running every prefix the
fixture declares; `ACC` is excluded because it is checked against a second run's
combined output, not against the mutated text.

Mutations: `extra_measure_i32`, `extra_measure_i1`, `extra_alloc_i32`,
`extra_alloc_f64`, `classical_becomes_quantum` (the classical `zext i1 false`
replaced by a fresh rail + a measure of it — the exact stream a taint-blind
predicate emits), `drop_measure`, `drop_alloc`, `extra_x`, `extra_free`.

**First run: 6 MISSED, all of them holes in MY fixtures, and each is now a
comment in the fixture that names the mutation it failed to catch.**

| fixture | mutation | why it escaped | fix |
|---|---|---|---|
| A2 | `extra_measure_i1` | `MCNT` counted `call i32 @cqrt_measure_i32(` — the **i32 spelling only** | widened to `call {{.*}}@cqrt_measure_` (the `call ` anchor keeps lazy `declare`s out) |
| A2 | `extra_alloc_f64` | `ACNT` counted `cqrt_alloc_i32` only — and **f64 is the miscompile family this change is most exposed to** | widened to `call i32 @cqrt_alloc_` |
| A2 | `extra_x`, `extra_free` | the module emits neither, so nothing named them | two `-NOT`s added to the pure-negative `NOINTR` prefix |
| A3 | `drop_alloc` | only the `|0>` out rail's alloc was pinned, not the scrutinee's | added the scrutinee `alloc`+`ry` CHECK pair |
| A3 | `extra_x`, `extra_free`, `extra_alloc_*` | the fixture deliberately asserted only the measure disposition | added `XCNT-COUNT-2`, `FCNT-COUNT-1`, `ACNT-COUNT-3` — an extra bracket or a free of the scrutinee is a hidden measurement (Rule 6), not cosmetic |

**Final: `fixtures=4 mutations=29 MISSED=0 DIRTY=0 n/a=7`.** The 7 n/a are
argued, not swept: 5 on A1 (a purely-classical module has no rail and no measure
to drop, bracket or free) and 2 more `classical_becomes_quantum` (the mutation
rewrites a `zext i1 false to i32` line, which only A4 has).

---

## §5 e2e — 3 slices + 1 `compare_files` gate, all STRICT stage 2b

Registered in `tests/e2e/CMakeLists.txt` after the last `slice_control_*` group.

| entry | what it is | result |
|---|---|---|
| `e2e-slice-measure-classical-bool` | **the owner's 22:18 file** (body moved into `slice()`, the house convention, since the harness runs the binary under `set -euo pipefail`) | Passed 2.17 s — 15 trace lines, STRICT 2b `10 rail mint(s) of which 8 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven` (10/2 rather than 5/1 because `-O1` keeps both `@slice` and its inlined copy in `@main`; the RUN executes one of them, hence 15 lines) |
| `e2e-slice-measure-classical-bool-twin` | the same file with `cq_measure(b1)` **deleted** | Passed 1.36 s — 15 lines |
| `e2e-measure-classical-bool-twin-identical` | `compare_files` of the two goldens | Passed 0.03 s — **15 = 15, byte identical** |
| `e2e-slice-measure-classical-only` | purely classical: four measures (constant / derived i32 / f64 `fmul` / `select`), **no `cq_theta` anywhere** | Passed 1.21 s — **EMPTY golden**, 0 trace lines, 2b `0 rail mint(s)` |

**The two traces** (the subject's is line-for-line the twin's):

```
cqrt_alloc_i1(0) -> h0            cqrt_alloc_i32(5) -> h4
cqrt_ry_i1(h0, 0x1p-1)            cqrt_copy_i32_controlled(h1, h4, h2)
cqrt_alloc_i1(0) -> h1            cqrt_x(h1)
cqrt_cnot(h0, h1)                 cqrt_cnot(h0, h1)
cqrt_alloc_i32(0) -> h2           cqrt_free(h1)
cqrt_alloc_i32(2) -> h3           cqrt_measure_i1(h0) -> 0
cqrt_copy_i32_controlled(h1,h3,h2) cqrt_measure_i32(h2) -> 0
cqrt_x(h1)
```

**Why the twin gate and not the golden alone.** A rail minted for `b1` (the
f64/angle miscompile family) or a stray `cqrt_measure_i1` on a fresh `|0⟩` rail
would leave a trace that is still self-consistent, still verify-clean and still
STRICT-2b clean — `free_pairing_check.py` witnesses rail **pairing**, and an extra
left-allocated rail is not a pairing violation. The only instrument in the tree
that can see it is this diff. And the twin golden is not a claim of this
compiler's: the ORACLE binary reproduces it **byte-for-byte** (lowered IR md5
`96c41a7d0818aaed1a425e7ce972d81f` on both), so the identity is measured against
the *previous* compiler's stream.

`e2e-slice-measure-classical-only`'s empty golden is the other half: zero trace
lines means zero `cqrt_*` emitted, **and** the program links both archives while
referencing nothing in either — the layer-2 proof that the classical path needs no
new runtime symbol (no YAML, no `runtime/` change, Rule 15 untouched).

---

## §6 CORPUS SWEEP — ORACLE vs SUBJECT

`probes/corpusC.sh`, PROTOCOL.md's `corpus.sh` with three noted deltas (the
SUBJECT path; the corpus widened to the 1893 **pre-existing** `ir-pass/test/*.ll`
taken from the ORACLE checkout — so the 6 fixtures this increment ADDS cannot be
silently counted as movers — plus every session probe dir PROTOCOL names,
including the 2026-09-13 ones; and a decline tag that falls back to the full
first `error:` line, because the upstream `grep -oE 'cq [a-z0-9 ]+: '` matches
NOTHING in the measure sink's dialect and would have rendered every string this
increment moves as a bare `D:`). A row is
`path|ORACLE(A:md5-8 or D:string)|SUBJECT(same)`.

**Result — `probes/corpus_c662bd0ca0e7d8a4.txt`, 3021 rows:**

| class | count |
|---|---|
| rows | **3021** (1948 `ir-pass/test/**.ll` from the ORACLE checkout + 1073 probe rows across 18 session probe dirs) |
| **MOVERS (ORACLE ≠ SUBJECT)** | **1** |
| ACCEPT → DECLINE | **0** |
| DECLINE → ACCEPT | **1** |
| decline STRING changed | **0** |
| **both accept, lowered-IR md5 DIFFERS** | **0** |
| `CLANGERR` on both (pre-existing, stage-1) | 1 (`session-2026-09-11-orchestrator/review_integration_probes/U0_uncommented.c`) |

The **zero** in the "both accept, md5 differs" row is the load-bearing one: over
3021 inputs, not one program that compiled on the ORACLE lowers to a different
module here. The change cannot move a circuit; it can only move a decline.

**The one mover, in full:**

```
session-2026-09-13-orchestrator/trackL/probes/t_loop_phase.c
  ORACLE   D:cq_measure_<sfx> operand not recognized; expected a tainted i32 handle
  SUBJECT  A:400b3682
```

It is Track L's own scoping probe, and its header — written this morning, before
this increment existed — says why: *"declines `cq_measure_<sfx> operand not
recognized…` — a PROBE ARTEFACT (`cq_measure(a)` on a never-written classical
`a`), the pre-existing classical-measure over-decline filed 2026-09-11. Use w2
instead."* An independent track had to route around exactly this defect, in this
session, and the row is that workaround becoming unnecessary. (Track L's `w2`
substitute is unaffected: it is a both-accept row with an unchanged md5.)

---

## §GATES

Verbatim copy of `GATES.md` in this directory. Every line keys to
`c662bd0ca0e7d8a4` — ONE build, no pass source touched after it.

---

`<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`

Binaries in play:

| role | `cq-opt` sha256 | `libCQPass.so` sha256 | from |
|---|---|---|---|
| ORACLE (read-only) | `fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661` | `40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93` | `/Users/sorenwilkening/Desktop/CQ_lang/build`, e96f89c, both hashes re-verified at session start 2026-09-13, never rebuilt |
| SUBJECT | `c662bd0ca0e7d8a4db70bc8b410521e1ea946098ccce702d0c2c0ed2b2a1761b` | `52d1136c3c7d9049bf0d6de95b84cfe2c3f353a54457b9c30b5c655feb60a510` | `/Users/sorenwilkening/Desktop/CQ_21mg/build`, branch `classical-measure` |

ONE build of the SUBJECT: no pass source was touched after it, so every line below
keys to the same `c662bd0c`.

```
build (cmake --build build -j8, BOTH targets)      | c662bd0ca0e7d8a4 | rc=0, no new warnings (4 pre-existing -Wunused in RegionTreeDetect/TaintPropagation) | impl | 2026-09-13 12:05
lit --filter lowering_reject_measure_undef_operand | c662bd0ca0e7d8a4 | PASS 1/1                                                       | impl | 2026-09-13 12:11
lit --filter lowering_measure_classical_accept     | c662bd0ca0e7d8a4 | PASS 1/1                                                       | impl | 2026-09-13 12:13
lit --filter lowering_measure_classical_mixed_accept | c662bd0ca0e7d8a4 | PASS 1/1                                                     | impl | 2026-09-13 12:16
lit --filter lowering_measure_round2_sixfive_handle | c662bd0ca0e7d8a4 | PASS 1/1                                                      | impl | 2026-09-13 12:18
lit --filter control_measure_classical_bool_owner  | c662bd0ca0e7d8a4 | PASS 1/1                                                       | impl | 2026-09-13 12:20
lit --filter 'measure_classical|measure_round2|measure_undef' | c662bd0ca0e7d8a4 | PASS 6/6 (of 1899 discovered)                       | impl | 2026-09-13 12:28
ctest -R '^e2e-(slice-measure-classical|measure-classical)' | c662bd0ca0e7d8a4 | 4/4 passed, 4.80 s (bool 2.17 / bool-twin 1.36 / twin-identical 0.03 / only 1.21) | impl | 2026-09-13 12:24
injection matrix (probes/inject_C.py, 4 accepts)   | c662bd0ca0e7d8a4 | fixtures=4 mutations=29 MISSED=0 DIRTY=0 n/a=7                  | impl | 2026-09-13 12:28
ctest -R ir-pass-lit                               | c662bd0ca0e7d8a4 | 1/1 Passed, 45.80 s; `lit ir-pass/test` breakdown: 1899 discovered, 1898 Passed, 1 Expectedly Failed, 0 unexpected | impl | 2026-09-13 12:34
corpus sweep ORACLE-vs-SUBJECT (probes/corpusC.sh) | c662bd0ca0e7d8a4 | 3021 rows, 1 MOVER (trackL/probes/t_loop_phase.c, DECLINE->ACCEPT on the 21mg string), 0 ACCEPT->DECLINE, 0 decline-string changes, 0 both-accept md5 differences, 1 pre-existing CLANGERR on both | impl | 2026-09-13 12:33
```

NOT RUN by this row (PROTOCOL.md: they are not the implementer's): full `ctest -j6`,
`ctest -j6 -R '^e2e-'`, `cq-opt-equivalence-full`, the twin matrices, the
duplicate-body fixture scan. The merge-and-gate agent owns the full run;
`cq-opt-equivalence-full` is owed by whoever lands this, because a NEW decline
string was added (`cq_measure_<sfx> operand is an undef/poison literal; a
classical measurement needs a defined value`) — PROTOCOL's "iff a decline string /
analysis site changed" row.

---

## §7 OPEN QUESTIONS AND FOUND-IN-PASSING

**O-1 (observation, no action).** `-O1` folds `c5_classical_phi.c`'s if/else into
a `select`, so the "classical `phi`" case the brief names is reached from C only
via a shape `-O1` will not fold (a loop, or two calls). Both spellings are
covered in `lowering_measure_classical_accept.ll` (`f_phi` **and** `f_select`) —
the fixture the brief asked for would have pinned only the rarer one.

**O-2 (found in passing — a Rule-1 gap in a RETAINED diagnostic; NOT fixed).**
Neither pre-existing diagnostic in `MeasureLowering.cpp` attaches the offending
instruction's `!dbg`: both render `<unknown>:0:0` even with `clang -g` (measured
on every `c*` probe). Rule 1 says diagnostics carry `!dbg` "so they are
source-located". The NEW string does (`c6_undef_bool.c:3:33`). I did **not**
change the retained one: the brief pins it character-for-character and adding a
location changes the rendered line every corpus row and every future fixture would
see. **Worth a bd issue** — one-line fix (`Measure->getDebugLoc()`), and it should
be landed together with whatever re-baselines the diagnostic surface.

**F-3 (over-decline, filed — verdict (c)'s follow-on).** A CLASSICAL `cq_measure`
inside a tainted value arm declines `cq controlled lowering: value-arm swap-route
under quantum control`. Under 21mg the hoist that fence protects is **inert** for
a classical measure (no gate, no rail, no trace line), so this is a candidate
over-decline in the owner's "do not decline code that leads to a valid quantum
circuit" sense. Measured string above; repro
`probes/c7_measure_in_arm.c` and `control_reject_measure_classical_in_arm.ll`
(whose header carries the retirement trigger). **NOT fixed here**: it lives in
`ArmClassify`, outside 21mg's stated scope, and admitting it means teaching the
ARM classifier a disposition `lowerMeasures` has not yet computed — the L1
round-2 hazard in miniature, which is a Rule-13 conversation, not a one-liner.

**F-4 (observation, no action).** `SpecializeReject.cpp:71` puts every
`MeasureCalls` entry in `S.Measures`, so a callee containing a **classical**
`cq_measure` is still refused for Bennett lifting as "contains a quantum
primitive". Unchanged by this increment (the classification runs before
`lowerMeasures`) and arguably still right; recorded because it is the one
consumer whose verdict a reader might expect 21mg to have moved.

**F-5 (a fact worth carrying forward, not a defect).** `LLVMContext::diagnose`
**exits the process at the first `DS_Error`** — measured (§0 F-1). Several
in-tree comments are written as if the pass continues past a decline ("for an
in-process host that continues past the DS_Error…"), which is true of a *host*
and false of `opt`/`cq-opt`. Two consequences this session had to design around:
a fixture can only ever assert the FIRST diagnostic, and a "second, later" fence
can never be shown to fire on an input an earlier one already claims. Anyone
planning a multi-diagnostic fixture should read this first.

**Q-1 (for the owner / the next increment).** `cq_measure` of a classical value
now produces **no trace line at all**. That is right for the gate stream (a
classical read is not a gate) and it is what makes the twin identity provable —
but it does mean the trace no longer records that the user asked for a
measurement there. If the 7.6 I/O output-tape ABI ever wants "every measurement
the user wrote appears on the tape", this is the site that would have to change,
and the twin gate is the test that would have to be re-derived.
