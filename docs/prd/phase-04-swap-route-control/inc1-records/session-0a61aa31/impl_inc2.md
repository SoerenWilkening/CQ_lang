# impl_inc2 — bd test_C_libtooling-3qlq.3 (Inc 2: value arms by controlled-copy merge)

Agent: impl_inc2. Worktree: $SP/wt/inc2, branch 3qlq-inc2 (from main dfb8e83).
Oracle binary: $SP/wt/pre-3qlq/build/ir-pass/cq-opt (+ libCQPass.so, runtime archives).

## 2026-09-05 — step -1: setup
- Launched background configure+build of $SP/wt/inc2 -> $SP/progress/inc2_build.log.
- Next: read PRD §3/§5/§7/§10.3-8/§11, then Step 0 (compile the ?: twin on the ORACLE).

## 2026-09-05 — step 0: compile the twin FIRST (bd drbq-inc3-compile-the-twin-first)
Build: `$SP/progress/inc2_build.log` -> BUILD_OK (CQPass + cq-opt both built).
Probes in `$SP/progress/inc2_work/step0/`, all compiled with
`/usr/local/opt/llvm@19/bin/clang -I$SP/wt/pre-3qlq/include -include CQ.h -O1 -emit-llvm -S`
and lowered with the ORACLE `$SP/wt/pre-3qlq/build/ir-pass/cq-opt`.

### FINDING S0-1 (contradicts the brief's witness plan) — the `?:` twin is NOT a select
MEASURED -O1 shapes:

| source | -O1 shape |
|---|---|
| `if (q>5) {6 ops on p}`            (`t_six_diamond.c`, = shipped slice) | **diamond** + merge phi |
| `p = (q>5) ? R(p) : p;` 6-op inline R (`t_six_twin.c`) | **diamond** + merge phi |
| `if (q>5) {p=p+3;}`                (`t_oneop_diamond.c`) | **select** |
| `p = (q>5) ? R(p) : p;` 1-op R     (`t_oneop_twin.c`)    | **select** |
| if/else, 6 ops each                (`t_ifelse_diamond.c`)| **diamond** |
| `p = (q>5) ? R1(p) : R2(p);` 6 ops (`t_ifelse_twin.c`)   | **diamond** |

`diff` of the two `.s1.ll` (mod `; ModuleID`/`source_filename`): the one-op pair and the
if/else pair are **IDENTICAL**; the six-op pair differs only in a `; preds = %4, %0` vs
`; preds = %0, %4` COMMENT. So `-O1` erases the `if` / `?:` spelling distinction entirely:
SimplifyCFG's speculation cost threshold, not the source spelling, decides select-vs-diamond.
**The brief's "`?:` twin" witness therefore does not exist for the 6-op or if/else shapes.**

### FINDING S0-2 — the witness that DOES exist: the PRE-HOISTED select twin
`int t = R(p); p = (q>5) ? t : p;` (`t_six_hoisted_twin.c`) arrives at -O1 as exactly the
post-hoist shape — straight-line chain on `p` in the entry block, then
`select i1 %9, i32 %8, i32 %2` — and lowers through the Rule-13-cleared `SelectMergeEmit`.
This is a BETTER witness than the `?:` twin: the hoist IS the transformation
diamond -> (straight-line chain + select), so the twin is the *manual* spelling of the
increment's own transformation, exactly as drbq Inc 2b used the by-difference twin.

ORACLE trace, `t_six_hoisted_twin` (23 lines) = the PRD §7.1 target stream verbatim:
```
cqrt_alloc_i32(3) -> h0 ; cqrt_ry_i32(h0,0x1p-1) ; cqrt_alloc_i32(7) -> h1 ; cqrt_ry_i32(h1,0x1p-2)
cq_template_mul_i32_hl(h1, 5) -> h2      <- chain on the ORIGINAL p, out of place (h1 has a later reader)
cqrt_addc_i32(h2, 15) ; cqrt_xorc_i32(h2, 9)          <- M-C IN-PLACE on the FRESH rail h2
cq_template_mul_i32_hl(h2, 7) -> h3
cqrt_xorc_i32(h2, 9) ; cqrt_addc_i32(h2, -15) ; cq_template_mul_i32_hl_unc(h2, h1, 5) ; cqrt_free(h2)
cqrt_addc_i32(h3, 7) ; cqrt_xorc_i32(h3, 2)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h4  ; cqrt_alloc_i32(0) -> h5
cqrt_copy_i32_controlled(h4, h3, h5) ; cqrt_x(h4) ; cqrt_copy_i32_controlled(h4, h1, h5) ; cqrt_x(h4)
cq_template_icmp_sgt_i32_hl_unc(h4, h0, 5) ; cqrt_free(h4) ; cqrt_measure_i32(h5) -> 0
```
vs the shipped ORACLE diamond (28 lines): `icmp; alloc w; cswap; 6 out-of-place ops on w;
cswap; alloc out; copy(p,out); cswap; 6 _unc; cswap; free w; strip; free f`.
free_pairing_check.py STRICT = clean (rc 0) on ALL 8 probes.

### FINDING S0-3 — the hoisted chain is lowered by M-C IN PLACE, on the FRESH rails only
The brief says "pin the hoisted chain OUT-OF-PLACE only". MEASURED: the twin's chain is
NOT all out of place — `lowerOps`' M-C converts `add`/`xor` to `cqrt_addc`/`cqrt_xorc`
**in place on the fresh intermediate rails** (h2, h3), never on `p`'s rail h1, because
M-C's G6/G7 pair refuses an in-place conversion when a later read of that rail exists —
and `p` always has one here (the second `copy_controlled(f, p, out)` and, when the
condition reads `p`, the compare strip). So the "out of place" requirement is already
enforced *for the source register* by machinery that is Rule-13-cleared, and forcing the
whole chain out of place would BREAK byte identity with the twin. See §DESIGN below.

### if/else (54 -> 33 lines) and one-op
`t_ifelse_hoisted_twin.c` (`int t1=R1(p), t2=R2(p); p=(q>5)?t1:t2;`) -> both chains
straight-line + one select; oracle trace 33 lines, same two-controlled-copy merge.
`t_oneop_diamond` ALREADY takes the select path at HEAD (14 lines) and already emits the
target stream — i.e. the tree is inconsistent exactly as PRD §7.1 says.

## 2026-09-05 — step 1: V1 + V2 lower by the controlled-copy merge (commit 1a8cae0)
### DESIGN (chosen over writing a new gate emitter — Rule 14)
`emitValueRegion` (SwapRouteEmit.cpp:193) is now a **REWRITE, not a gate stream**:
1. plan validation (unchanged) + TWO new pre-mutation fences (below);
2. HOIST each arm's chain into the pred (`moveBefore(BI)`), forward order — the links stay
   ORDINARY tainted LLVM instructions, lowered LATER by `lowerOps` and reversed by the
   whole-DAG spine (this is what makes the stream identical to the twin's, M-C in-place
   conversions included);
3. `SelectInst::Create(Cond, TrueVal, FalseVal)` with Rule-9 polarity (`ArmNegated` /
   if-else S0-S1); built with `SelectInst::Create`, NOT `IRBuilder::CreateSelect`, because
   the builder constant-FOLDS and a folded merge would silently erase the controlled copy;
4. RAUW the merge phi -> select, erase it;
5. `flattenRegion(R, taint)`;
6. `emitSelectRegion(S, wd, csyms, taint)` on a locally-built `SelectRegion` view.
NOTHING is emitted by this function: every gate comes from `lowerOps` (the hoisted chain)
or from the Rule-13-cleared 4.4 `SelectMergeEmit`. No new symbol; `cqrt_copy_<W>_controlled`
is minted by `ControlledSymbols::copyControlledFn` exactly as for 4.4/6.5.

**ORDER IS LOAD-BEARING — flatten BEFORE emit.** `flattenRegion` reads `R.Condition` and
erases it when use-empty; `emitSelectRegion` erases the compare itself in its step 6.
Emit-then-flatten hands `flattenRegion` a DANGLING `R.Condition` — a use-after-free on
valid input (the block-lifetime hazard's value-identity twin). With flatten first the
compare is still live (the new select uses it), so flatten leaves it and the select emitter
owns the erase. Written into the function's header comment.

### The two new pre-mutation fences
- **F-TOTALITY** (PRD §10.3 lens 8): every chain link must be
  `llvm::isSafeToSpeculativelyExecute` — LLVM's OWN predicate, the same one SimplifyCFG
  consults, rather than a hand-rolled per-opcode table (Rule 14). String:
  `cq controlled lowering: value arm op that cannot run unconditionally under quantum control`.
  Covers `sdiv/udiv/srem/urem` with a possibly-zero or `INT_MIN/-1` divisor. Shifts by
  >= bitwidth are POISON not UB, `isSafeToSpeculativelyExecute` admits them, and the poison
  never materializes (`lowerOps` replaces every link with a runtime call and erases the
  original). ⚠ MEASURED: this hazard is NOT created by the hoist — the pre-3qlq route also
  ran the chain UNCONTROLLED (on a `|0>` rail, i.e. `0 sdiv n`), so a possibly-zero
  classical divisor was equally unguarded there. The fence NARROWS the accept class vs HEAD;
  that direction is always safe. `p / 3` still accepts.
- **F-QQCOND**: a Q+Q condition compare declines (`control flow`). `emitSelectRegion` mints
  through `lowerCompareToFlag` with the 4.4 `qqSelectLeafWidth`, which SUPPORTS two handles,
  while the pre-3qlq value path passed an empty width and declined. Without this fence the
  mechanism change would have WIDENED the accept class as a side effect. MEASURED oracle
  disposition for `if (q > r) {6-op chain on p}`: rc=1,
  `no template for opcode 'icmp i1' in tainted context` (a `diagnoseNoTemplate`, not a
  control-dialect string) — see OWNER QUESTION 1.

### MEASURED WITNESS — byte identity with the pre-hoisted select twin (3 pairs)
| pair | NEW `$SP/wt/inc2/build/ir-pass/cq-opt` | ORACLE `$SP/wt/pre-3qlq/build/ir-pass/cq-opt` | `cmp` |
|---|---|---|---|
| V1 six-op diamond | `t_six_diamond` 23 lines | `t_six_hoisted_twin` 23 lines | **BYTE-IDENTICAL** |
| V2 if/else | `t_ifelse_diamond` 33 lines | `t_ifelse_hoisted_twin` 33 lines | **BYTE-IDENTICAL** |
| one-op diamond | `t_oneop_diamond` 14 lines | `t_oneop_diamond` (oracle; already the select path) 14 lines | **BYTE-IDENTICAL** |
`free_pairing_check.py` STRICT rc=0 on all three NEW lowerings.
Trace lines went 28 -> 23 (V1), 54 -> 33 (V2); ZERO `cqrt_cswap`, ZERO work rails.

## 2026-09-05 — step 2: red partition after step 1
`ctest --test-dir build -R ir-pass-lit` (log `$SP/progress/inc2_lit1.log`, 83.8 s):
**1582 discovered · 1575 passed · 1 expectedly failed · 6 FAILED.**
The 6 are exactly the V1/V2 ACCEPT fixtures whose CHECKs pin the retired cswap route:
`control_swap_value_accept_nonclobber.ll`, `control_swap_value_diamond.ll`,
`control_swap_value_diamond_derived.ll`, `control_swap_value_diamond_polarity.ll`,
`control_swap_value_ifelse.ll`, `lowering_uncompute_interior_leak_region_valuearm_chain.ll`.
**ZERO decline fixtures went red** — so the decline partition is unchanged and the two new
fences (F-TOTALITY, F-QQCOND) are pinned by NOTHING yet (Rule 12 debt, step 4).

## 2026-09-05 — step 3: V3 (switch homogeneous value) by preload + XOR-delta (commit 77b4a8c)
`emitSwitchValueRegion` (SwitchValueEmit.cpp) rewritten on the 4.5 data-mux precedent
(`SwitchDataMuxEmit`, Rule 14) with the default LITERAL replaced by the quantum register:
```
alloc out(0); cqrt_copy_<W>(p, out)                       <- the ONE uncontrolled preload
per case i:  hoist R_i's chain onto the ORIGINAL p
             d_i = R_i(p) XOR p        (a Q+Q `xor`; fwd_qq/unc_qq ship at every width)
             f_i = icmp_eq(q, c_i)
             cqrt_copy_<W>_controlled(f_i, d_i, out)       <- out ^= f_i . d_i
strip + free every f_i;  RAUW merge phi -> out;  flattenSwitchRegion
```
The chains and the deltas are ORDINARY tainted LLVM instructions, lowered by `lowerOps`
and reversed by the whole-DAG spine (MEASURED: each chain intermediate gets its `_unc` +
`cqrt_free`). No new symbol; no route; no `cqrt_x` anywhere (eq-flags are mutually
exclusive). TWO ASSERTS added, per the brief: `Arm.Values.size() != 1` (a grouped case
label would gate on ONE literal and silently drop the rest) and a pairwise-distinct scan
over the content cases (the mutual exclusion the whole preload+delta argument rests on).
Both are Rule-1 defensive bails on shapes `SwitchClassify` already proves absent.
`slice_control_switch_value`: 29 -> 23 trace lines, free_pairing STRICT rc=0.

WHY LEAVING d_i ALLOCATED IS SOUND (analytic, written down because nothing measures it):
`d_i = R_i(p) ^ p` is a deterministic function of `p`, and `p` is kept live and entangled
with `out` (keep-source-live, exactly as the route left it). A register that is a function
of an already-retained register records no which-path information that register does not
already record, so the reduced state on (q, out) is unchanged. Same argument covers the
chain finals left allocated in V1/V2.

## 2026-09-05 — step 4/5: fixtures (commits 1a8cae0..)
- The 7 red accepts REWRITTEN with CHECKs **re-derived from the pass output**, handle names
  taken from the output, whole-file PURE-NEGATIVE `NOROUTE` prefix and counts in their own
  `FCNT`/`CCNT`/`PCNT` prefixes (the bd drbq Inc-4 windowing lesson: a positive COUNT inside
  a prefix windows every negative after it).
- FOUR NEW fixtures (corpus 1582 -> 1586): `control_swap_value_reject_speculation.ll`,
  `control_swap_switch_value_reject_speculation.ll` (the switch half — the diamond fixture
  cannot reach it), `control_swap_value_reject_qq_cond.ll`, and the ACCEPT DISCRIMINATOR
  `control_swap_value_accept_div_const.ll` (`udiv` by a non-zero CONSTANT still lowers, so
  the fence is not "decline every div in a value arm").
- RED-GREEN, MEASURED oracle vs new on the four probe modules
  (`$SP/progress/inc2_work/newfix/`):

| probe | ORACLE (52d7764) | NEW |
|---|---|---|
| `sdiv` by a run-time classical divisor, diamond | **rc=0 ACCEPTS** | rc=1 `value arm op that cannot run unconditionally` |
| `udiv` by the constant 3, diamond | rc=0 | rc=0 (unchanged) |
| Q+Q condition, value diamond | rc=1 `no template for opcode 'icmp i1' in tainted context` | rc=1 `control flow` |
| `sdiv` by a run-time classical divisor, switch | **rc=0 ACCEPTS** | rc=1 `value arm op that cannot run unconditionally` |

- INJECTION VALIDATION of all 8 accept fixtures (a `cqrt_cswap` + an extra `cqrt_free`
  spliced before the final `ret`, then FileCheck re-run per prefix): baseline red = 0 for
  every file, and EVERY file has >= 1 prefix that CATCHES the injection (2 prefixes for six
  of them, 1 for `control_swap_value_accept_div_const` and the leak fixture). Script +
  artifacts in `$SP/progress/inc2_work/inject/`.

## 2026-09-05 — step 6: e2e (commit af16a36)
SIX new slices + THREE `cmp` twin gates; the two route goldens regenerated and audited.

### The three twin pairs — BYTE IDENTICAL (`ctest -R 'e2e-value-.*-twin-identical'` green)
| pair | subject | twin (pre-hoisted select) | lines |
|---|---|---|---|
| V1 6-op | `slice_control_value_diamond` | `slice_control_value_diamond_twin` | 23 = 23 |
| V2 if/else | `slice_control_value_ifelse` | `slice_control_value_ifelse_twin` | 33 = 33 |
| V1 mixed stems | `slice_control_value_mixedops` | `slice_control_value_mixedops_twin` | 24 = 24 |
`cmp` output: silent (identical) for all three; `ctest` 11/11 pass on the value+switch
subset (log `$SP/progress/inc2_e2e1.log`).
The mixed-stem pair uses `sub`/`and`/`or`/`shl`/`xor`/`mul` deliberately: `sub` is
non-commutative and `and`/`or`/`shl`/`sub` are NOT M-C in-place-convertible, so it is the
pair that would catch a hoist that changed operand order or the in-place disposition.

### FINDING S6-1 — the DERIVED-base pair has NO twin, and that is PRE-EXISTING
`slice_control_value_derived` (a pre-region `cq_phi` on the value register) lowers (24
lines) but its pre-hoisted select twin **DECLINES `cq controlled lowering: control flow
under quantum control` on BOTH binaries** — `SelectClassify` conservatively refuses a
coherent Rz-lineage select OPERAND, while the `br`-value classifier deliberately ACCEPTS a
derived base (the 9hh discipline). Inc 2 reuses `emitSelectRegion` (the EMITTER) and keeps
the `br` path's own separately-cleared classification, so the two dispositions differ BY
DESIGN. The slice ships WITHOUT a `compare_files` gate and its header says why — a gate
there would assert something false (the drbq Inc-4 "no `cmp` twin gate, deliberately"
precedent). The third pair is `mixedops` instead of the `oneop` pair the brief asked for
(see FINDING S0-1: the one-op diamond and its `?:` twin are the SAME -O1 module, so that
gate would compare a program to itself).

### AUDIT of the two regenerated goldens (line by line, `diff` in full above in the log)
1. `slice_control_value_diamond.expected.log` 28 -> 23. The whole diff is: the retired
   quintuple-plus (`icmp mint; alloc(0) rail; cswap; 6 out-of-place HL chain ops; cswap;
   alloc out; copy_i32(p,out); cswap; 6 `_unc`; cswap; free rail; strip`) REPLACED by
   (`6 chain ops on p with M-C in-place on the fresh rails + their spine `_unc`/free;
   icmp mint; alloc out; copy_controlled; x; copy_controlled; x; strip`). Handle
   renumbering aside, NOTHING ELSE MOVED — the two `cqrt_alloc_i32(3/7)` + `cqrt_ry`
   prologue lines and the final `cqrt_measure_i32` are unchanged.
2. `slice_control_switch_value.expected.log` 29 -> 23. Same substitution per case, plus
   the preload `alloc out(0); copy_i32(p,out)` moving to the TOP of the region and the two
   `xor` delta lines appearing. No line survives that mentions `cqrt_cswap`; the
   `icmp_eq` mints and strips are unchanged in count, order and arguments.

## 2026-09-05 — step 7: totality per opcode, and adversarial probes

### The totality decision, PER OPCODE (the brief's lens-8 item)
FIRST, THE HONEST PART: **the shipped runtime cannot answer this question.**
`runtime/cq_templates.c` is generated and TRACE-ONLY — `cq_template_sdiv_i32_hl` and
`cq_template_shl_i32_hl` both read `h = cqrt_alloc_handle(); printf(...); return h;` and
perform NO arithmetic (measured, `runtime/cq_templates.c:10592` / `:11471`). So every
template is trivially "total" at run time because it computes nothing, and totality is a
statement about the ABI's intended semantics for a Phase-9 backend, NOT a runtime
property. The fence therefore has to be a COMPILE-TIME proof about the LLVM opcode, which
is what `isSafeToSpeculativelyExecute` is.

| stem | unconditional execution at LLVM level | disposition |
|---|---|---|
| `add`/`sub`/`mul` (incl. `nsw`/`nuw`) | overflow yields **POISON, not UB** | ACCEPT. The poison never materializes: `lowerOps` replaces the op with a runtime call and erases the original, so no poison value survives into the emitted module. The gate is a modular adder/multiplier — total. |
| `and`/`or`/`xor` | total for all inputs | ACCEPT |
| `shl`/`lshr`/`ashr` | shift amount >= bitwidth yields **POISON, not UB** | ACCEPT (`isSafeToSpeculativelyExecute` admits them). ⚠ See OWNER QUESTION 2: the CLASSICAL shift amount is passed through to the gate unchanged, and that exposure is IDENTICAL on both mechanisms (measured: `p << n` accepts on the oracle AND on this binary, 19 trace lines each) because the hoist changes the DATA operand, never the shift amount. Not fenced — fencing it would narrow a shape for a reason unrelated to this increment. |
| `sdiv`/`udiv`/`srem`/`urem` | divisor 0 is **immediate UB**; `sdiv`/`srem` `INT_MIN / -1` is UB | **FENCED** unless the divisor is a proven-non-zero constant. |
| `fadd`/`fsub`/`fmul`/`fdiv`/`frem` | IEEE: inf/NaN are VALUES, no UB — a NaN is a label and a permutation template is still total | UNREACHABLE: `ArmClassify` declines an FP-typed merge as an ANGLE before the chain base is read, so no fp value arm reaches either emitter. Stated, not fenced. |

`isSafeToSpeculativelyExecute` is called with NO context instruction, so it is CONSERVATIVE
by construction — it can only over-decline, never over-accept. A `load` (which it also
refuses without context) can never appear in a chain: `walkValueChain` records only
`BinaryOperator` links and `valueArmIsPureChain` refuses any stray instruction in the arm.

### Adversarial probes, ORACLE vs NEW (`$SP/progress/inc2_work/probe/`, plain C at -O1)
| probe | ORACLE (52d7764) | NEW | verdict |
|---|---|---|---|
| SEQUENTIAL value regions (`if(q>5){R1} if(q<2){R2}`) | accepts, 51 lines | accepts, **41 lines** | region 2's chain correctly reads region 1's `%out`; fpc STRICT rc=0; ZERO cswap |
| IN-LOOP value arm | declines `condition predates a non-diagonal gate` | IDENTICAL | unchanged |
| §3c CLOBBER (`if(q>5){q=q+3;…}`) | declines `arm rewrites a condition operand` | IDENTICAL | unchanged |
| ShareCondFlag (`int f=(q>5); if(q>5){…}`) | declines `condition used outside the branch` | IDENTICAL | unchanged |
| run-time SHIFT amount in the arm | accepts, 19 lines | accepts, 19 lines | unchanged (OWNER QUESTION 2) |

### `cqrt_cswap` census (`grep -rn "cswapFn()\|emitRoute" ir-pass/src`)
ONE minter (`ControlledSymbols::cswapFn`, SwapRouteEmit.cpp:1194 inside `emitRoute`) and
FOUR call sites after Inc 2:
- `AbortParkEmit.cpp:381` — the 7.2 abort-park graveyard (the epic's intended sole survivor)
- `NestedRouteEmit.cpp:162` — the 4.3 depth-2 **PHASE** nest
- `SwitchRouteEmit.cpp:159` and `:172` — the 4.5 switch **PHASE** route
**ZERO value-path call sites remain** — that half of the epic's goal is DONE. The brief's
"AbortParkEmit only" is reached only after **Inc 1** retires the two PHASE routes (PRD §6.2
P4/P5); stating it as achieved now would be false, so it is stated as measured instead.

## 2026-09-05 — step 8: width sweep + the retired-mechanism decline string

### Width sweep of the value diamond (hand IR, `$SP/progress/inc2_work/probe/w_*.ll`)
| width | ORACLE | NEW |
|---|---|---|
| i8 | accepts | accepts |
| i16 | accepts | accepts |
| i64 | accepts | accepts |
| i128 | declines `value-arm swap-route` | declines `value-arm swap-route` (unchanged) |
No width narrowing: the pre-flight now asks `csyms.copyControlledFn(Abi)` instead of
`wd.copyFn(Abi)` and the two agree on every width a value arm can reach (i128 declines
EARLIER, at classification, on both binaries).

### The decline string `value-arm swap-route` now names a RETIRED mechanism
6 source sites (`ArmClassify.cpp:3210,3254`, `ArmHomogeneity.cpp:185`,
`SwitchArmProve.cpp:199,280,289`) and **28 lit fixtures** pin it character-for-character.
DELIBERATELY NOT RENAMED in this increment: it is a pure diagnostic-text change with zero
behaviour, it would churn 28 fixtures and 3 shared source files (`ArmClassify.cpp` is also
Inc 1's file), and the PHASE routes it also covers are still live until Inc 1. Filed as
OWNER QUESTION 3 / a follow-on best done as its own commit once the whole epic lands.

## OWNER QUESTION 1 — Q+Q condition for value arms: keep the fence, or take the capability?
`emitValueRegion` now hands the region to `emitSelectRegion`, whose leaf mint goes through
`lowerCompareToFlag` with the 4.4 `qqSelectLeafWidth` — which SUPPORTS a two-handle
compare. The pre-3qlq value path passed an EMPTY qqWidth and therefore declined. I added
F-QQCOND to keep the old disposition, because widening an accept class as a SIDE EFFECT of
a mechanism change is exactly what the Prime Directive refuses to ship unreviewed, and PRD
§9 lists "Q+Q compare condition mint" as deferred, "pre-existing; unchanged by this epic".
**Taking the capability is the DELETION of one 4-line `if` in `emitValueRegion`** (and its
switch twin does not exist — `emitEqFlag` is eq-only). Reproducer:
`$SP/progress/inc2_work/newfix/qq_cond.ll` (`if (q > r) {6-op chain on p}`; oracle rc=1
`no template for opcode 'icmp i1' in tainted context`, new rc=1 `control flow`).
NOT MY DECISION — it is a widening, and PRD §9 says deferred.

## OWNER QUESTION 2 — a run-time classical SHIFT AMOUNT is passed through to the gate
`if (q>5) { … p = p << n; … }` with `n` a run-time classical `int` ACCEPTS on BOTH binaries
(19 trace lines each; `$SP/progress/inc2_work/probe/p_shift_rt.c`) and emits
`cq_template_shl_i32_hl(h, n)`. At LLVM level a shift by >= bitwidth is POISON (not UB), so
`isSafeToSpeculativelyExecute` admits it and the Inc-2 fence does not fire. But the ABI
hands the classical `n` straight to a Phase-9 backend, which has no defined answer for
`shl` by n >= W. **The exposure is IDENTICAL on both mechanisms** — the hoist changes the
DATA operand, never the shift amount — so this is pre-existing and I did NOT fence it:
fencing it here would narrow a shape for a reason unrelated to this increment, and doing
so silently would hide a pre-existing question behind an Inc-2 commit. Filed, not fixed.

## OWNER QUESTION 3 — the decline string `value-arm swap-route` names a RETIRED mechanism
6 source sites and 28 lit fixtures pin it character-for-character (counts measured:
`grep -rn '"value-arm swap-route"' ir-pass/src/`, `grep -rl 'value-arm swap-route'
ir-pass/test/ | wc -l`). Renaming is a pure diagnostic-text change with ZERO behaviour, but
it churns 28 fixtures and 3 source files — one of which (`ArmClassify.cpp`) is also Inc 1's
— and the string still covers the PHASE routes, which are live until Inc 1 lands. My
disposition: DO NOT rename in Inc 2; do it as its own commit once the epic's phase half
lands and no route remains. Confirm or override.

## REVIEWER FLAG (not an owner question — a Rule-13 lens for round 1)
**Inc 2 makes `emitSelectRegion` reachable with inputs `classifySelectRegion` would
REFUSE.** The `br`-value path keeps its OWN classifier (`ArmClassify`) and borrows only the
select EMITTER. I audited the gate-by-gate difference:
- gate 2c stale-condition wire guard — the `br` path has its mirror (`condWireDisposition`,
  named as such in CLAUDE.md). COVERED.
- fp / vector / i128 / width fences — the `br` path has its own positive integer fence
  (`classifyArms` + `abiWidthFromType`); MEASURED equal at i8/i16/i64 (accept both) and
  i128 (decline both, EARLIER).
- Q+Q condition — closed explicitly by F-QQCOND (OWNER QUESTION 1).
- `compareFlagMintable` / i1-operand leaf — the pre-3qlq value path called the SAME
  `lowerCompareToFlag` on the SAME compare, so the exposure is unchanged, not new.
- **coherent Rz-lineage OPERANDS — GENUINELY DIFFERENT.** `SelectClassify` conservatively
  refuses them; the `br`-value classifier deliberately ACCEPTS a derived base (the 9hh
  discipline, `control_swap_value_diamond_derived.ll`). So after Inc 2 the select emitter
  runs on derived bases it would not be handed through its own front door. My argument that
  this is sound: `emitSelectRegion`'s correctness (§16.3) is that two controlled copies into
  a fresh |0> rail write `out` and NEVER the condition lineage, so the `icmp_inv` strip is
  valid — an argument that does not mention the operands' rotation lineage anywhere. The
  4.4 refusal is documented as CONSERVATIVE, not as a proven miscompile. **This is the
  single most load-bearing new assumption in the increment and should get a lens of its
  own.** Witness in the tree: `slice_control_value_derived` (24 lines, STRICT stage 2b
  clean) + `control_swap_value_diamond_derived.ll`.

## 2026-09-05 — step 9: full e2e + docs
- `ctest -j6 -R '^e2e-'`: **100% tests passed, 0 failed out of 326** (901.6 s wall — NOT a
  clean-box figure: another agent's `loop_twin_matrix` ran concurrently against the oracle
  for most of it, and `e2e-loop-twin-matrix` was the last entry to finish). Log
  `$SP/progress/inc2_e2e_all.log`. `e2e-loop-twin-matrix` (273 cells + 15 quarantined) is
  GREEN — the value path declines in loops, so Inc 2 does not touch it, and this is the
  measurement that says so.
- `ctest -R ir-pass-lit`: PASSED, 69.6 s. `lit ir-pass/test`: **1586 discovered, 1585
  passed, 1 expectedly failed** (the standing `lowering_invert_add_i32.ll` XFAIL).
- Stale swap-route prose retired from the value path's OWN headers: `SwapRouteEmit.h`
  (the VALUE-class paragraph + the `cqrt_copy_<W>` ABI note, which is now emitted by the
  4.5 switch PRELOAD and no longer by a diamond copy-out), `SwapRouteEmit.cpp`'s file
  header, and `ControlPlan.h`'s `Shadow` comment (the emit order changed; forward /
  base-first order is still what the HOIST needs). No behaviour.

## HAND-BACK (bd test_C_libtooling-3qlq.3 — Inc 2, value arms by controlled-copy merge)

### 1. What shipped — branch `3qlq-inc2` in `$SP/wt/inc2`, 7 commits, 30 files
| commit | what |
|---|---|
| `1a8cae0` | `emitValueRegion` (SwapRouteEmit.cpp) rewritten: V1 diamond + V2 if/else lower by HOIST + `select` + the 4.4 `emitSelectRegion`. Two new pre-mutation fences (F-TOTALITY, F-QQCOND). |
| `77b4a8c` | `emitSwitchValueRegion` (SwitchValueEmit.cpp) rewritten: V3 by PRELOAD + XOR-DELTA controlled copy + the grouped-case and mutual-exclusion asserts. |
| `5b1d723` | the 7 red accept fixtures re-derived from the pass output. |
| `f2558c7` | 4 NEW fixtures (2 declines + the accept discriminator + the switch decline). |
| `af16a36` | 6 new e2e slices + 3 `cmp` twin gates; the 2 route goldens regenerated + audited. |
| `858cf42` | V3's eq-flag mintability asked PRE-MUTATION (whole decline partition now precedes the hoist). |
| `8c526d9` | stale swap-route prose retired from the value path's own headers. |

**NO new runtime symbol** (`tools/opcode_table.yaml` and `runtime/` untouched — `git diff
--stat main..HEAD` lists neither). The merge primitive `cqrt_copy_<W>_controlled` is minted
by the existing `ControlledSymbols::copyControlledFn` (4.4/6.5); V3's preload uses the
existing uncontrolled `cqrt_copy_<W>`.

### 2. What I ran (only what I ran)
- `lit ir-pass/test` (full): **1586 discovered · 1585 passed · 1 expectedly failed** (the
  standing `lowering_invert_add_i32.ll` XFAIL). Corpus 1582 -> 1586.
- `ctest -R ir-pass-lit`: PASSED (69.6 s, then 43.2 s on the final binary).
- `ctest -j6 -R '^e2e-'`: **100% passed, 0 failed out of 326** (901.6 s under concurrent
  agent load; `e2e-loop-twin-matrix` green).
- `ctest -R 'runtime|frontend-lit|e2e-free-pairing-selftest|e2e-loop-twin-matrix'` on the
  FINAL binary — 7 runtime entries + frontend-lit + the free-pairing selftest all PASSED
  — **11/11 PASSED, 0 failed** (`$SP/progress/inc2_final.log`), `e2e-loop-twin-matrix`
  PASSED in 284.6 s on the FINAL binary (re-run deliberately: the earlier 326-entry run
  had the plugin rebuilt underneath it).
- `free_pairing_check.py` **STRICT** (no `--allow-unproven`) rc=0 on every slice and every
  probe I lowered.
- I did NOT run the full `ctest` in one invocation (BRIEF_common anti-stall rule 4); the
  union of what I ran is ir-pass-lit + frontend-lit + runtime + all 326 e2e.

### 3. The witness — 3 twin pairs, BYTE IDENTICAL
`slice_control_value_{diamond,ifelse,mixedops}` vs their `_twin`s (23/33/24 lines);
`cmp` silent on all three; `e2e-value-{diamond,ifelse,mixedops}-twin-identical` green.
Plus: `t_six_diamond` lowered by the NEW binary is byte-identical to `t_six_hoisted_twin`
lowered by the ORACLE binary — the transformation is exactly the manual hoist.

### 4. cswap census
ZERO value-path `cqrt_cswap` call sites remain. The 4 surviving `emitRoute` calls are
`AbortParkEmit.cpp:381` (7.2) and the two PHASE routes `NestedRouteEmit.cpp:162`,
`SwitchRouteEmit.cpp:159,172` — retired by **Inc 1**, not by me. "AbortParkEmit only" is
therefore NOT yet true and I did not claim it.

### 5. What is left
- Inc 1 must land before the epic's `cqrt_cswap`-census goal is met.
- OWNER QUESTIONS 1-3 above (Q+Q condition capability; the run-time shift amount; the
  `value-arm swap-route` string).
- The REVIEWER FLAG above (the Rz-lineage operand asymmetry) wants its own Rule-13 lens.
- PRD §9 follow-ons untouched: freeing the value-arm SOURCE; in-loop value arms.
- REBASE onto Inc 1's branch is still to do; the overlap is `SwapRouteEmit.cpp` (I touched
  only `emitValueRegion` and the file header) and `ControlPlan.h` (one comment).
