# Rule-13 review r1A — bd `test_C_libtooling-nlfd`, commit A (`a6a76840`)

| | |
|---|---|
| Subject (surface A only) | `9a230646..a6a76840` — `DeadValueLiveness.{h,cpp}`, `Specialization.cpp`, `SpecializeDetect.h`, 8 fixtures |
| Final binary (A+B+C) | `build/ir-pass/cq-opt` sha-256 `93c65d0da41df3fc52ddc45eafb7b26d5ed2e92e5242a473ad53b5ea13fb1ea8` (read-only use) |
| Commit A alone | my ONE private build of `a6a76840` (`<scratchpad>/rev_r1A_nlfd`): `cq-opt` `3685d41f7176ec2d47fb2995a836e24012875a4c58ca478ca7b08c003b398057` — **bit-identical to the implementer's recorded A hash** (independent reproduction of that record) |
| Oracle | `<scratchpad>/frozen/cq-opt.main_9a230646`, sha-256 `3f6db37f5cf937b4d70f5736…` (re-hashed) |
| Time | ~90 min, `-j4` |
| Reviewer B | r1B covers commits B (ev3m) and C (m5pn); I touched them only where a composition needed it |

**What I ran, literally.** `probes/run.sh {S,O,A} <probe>.ll <argv>` (lower → `free_pairing_check.py` STRICT + CENSUS → link templates-before-runtime → run; rc taken from `cq-opt` directly) on every probe below, against S (final), O (oracle) and A (commit A alone). `probes/sample.sh` over 14 of the implementer's cells + twins on S/O/A (`probes/cells_sample.txt`). `lit -j4 ir-pass/test --filter 'unread_scalar|phantom_arg_read|dropped_arg'` on my A build: **84 passed** of 2415 discovered (subset, not the suite). One mutant (M1) with the **full** lit suite on my private tree (2415). `opt -passes=verify` over every LLVM-19 parameter attribute on an `i32` definition + call site. `clang -O1` (and `-O2`, `-ffast-math`) on 16 C spellings to see which attributes reach an int/fp parameter. `opt -O2` over two lowered modules.

**Not run.** The implementer's corpus A/B, allocator sweeps, mutation matrix N0–N6/E1/D1 (read, not re-run); any ctest; `cq-opt-equivalence`; a `+Asserts` build; Guard Malloc. No C (two-TU) probe reaches commit A's code at all — see Q3/Q5: its whole surface is IR-only, so every probe here is hand-written IR (with C used only to measure what clang emits).

## Verdict: **CLEAR-WITH-ITEMS** — 0 P1, 2 P2, 3 P3

The core argument holds and I could not break it: `sa1.ll` is fixed (trace-identical to `mtT` at three inputs, 2b STRICT clean), the Argument clause is sound for every LLVM-19 int/fp parameter attribute I could construct, it changes no instruction's liveness (so no deletion set moves), and the Existence/Value split is pinned (my mutant M1 collapsing it crashes 3 fixtures). The items are one false soundness step (the strip does not reach the `_unc` twin), one disclosed IR-only over-decline whose "neither accept is the twin's" justification is false for its theta-source member, and comment/record hygiene.

---

## Findings

### F-r1A-1 — P2 — the value-constraint strip never reaches the inner clone's `_unc` TWIN; the neutralised `0` lands in a `noundef range(…)` / `nofpclass(…)` parameter. CLASS PRE-EXISTING (bd vsfp), customers INTRODUCED. Filed **bd `test_C_libtooling-vaep`**.

The soundness argument's step 4 (TRACK §2: *"Where a `0` now arrives, the two violable constraints are stripped"*; `DeadValueLiveness.h`, `isUnreadScalarSlot`: *"`range`/`nofpclass`: stripped by `stripUnreadSlotValueConstraints` wherever a null can now arrive"*) is false. `ensureTwin(h2clone)` runs in the ENCLOSING clone's inner-call loop (`Specialization.cpp` ~976), i.e. BEFORE that clone's record and strip (~1017/1094), and `synthUncomputeTwin`'s `CloneFunctionInto` copies the forward clone's parameter attributes onto the twin (index +1). The strip then edits the forward clone's parameter and the forward call site only; the Bennett wrap's reverse calls the twin with the same operand.

Measured (`probes/p1_twin_range_nn.ll`: `h(a,k){return h2(a,k);}`, `h2(i32 noundef range(i32 1,100) "cq.probe.opaque" %x, k)` returns the tainted `k+1`, so the twin exists; `results/p1_twin_range_nn.S.s2.ll`):

```
main:            %r = call i32 @__cq_q_h_11(i32 noundef 0, i32 noundef %h1)
__cq_q_h_11:     call void @__cq_q_h2_11_unc(i32 %r, i32 %a, i32 %k)          ; %a == 0 at run time
define internal void @__cq_q_h2_11_unc(i32 %out, i32 noundef range(i32 1, 100) "cq.probe.opaque" %x, …)
```

and the fp flavour `probes/p7_fp_classical_slot_nn.ll` (a CLASSICAL `double noundef nofpclass(zero)` slot beside a quantum one): S/A pass `double noundef 0.000000e+00` at `main` and `__cq_q_h2_001_unc(…, double noundef nofpclass(zero) "cq.probe.opaque" %y, …)` receives it; the ORACLE passed the real `%md` there. `noundef` + a violated `range`/`nofpclass` is immediate UB in LLVM semantics.

- **PRE-EXISTING class**: the null-safe twin `probes/p1_twin_range_ns.ll` on the ORACLE emits `call void @__cq_q_h2_11_unc(i32 %r, i32 0, i32 %k)` into `i32 noundef range(i32 1, 100) %x` (`results/p1_twin_range_ns.O.s2.ll`) — bd vsfp's `rewriteRecordedDeadSlotUse` has the same gap. **INTRODUCED customers**: `p1_twin_range_nn` and `p7` did not violate on the oracle (it passed the live value) and do on A/S. Also present on commit A alone (checked on my A build).
- **Consequence, measured: latent.** Traces are correct (`p1_twin_range_nn.S` ≡ `p1_twin_range_ns.O` byte-for-byte; `p7` S ≡ O); the twin never reads the slot; stage 3 is `-O0`; and `opt -O2` over the lowered modules does not exploit it (same `cqrt_`/`cq_template_` call count, 0 `unreachable`). Graded P2 on the rubric (a stated soundness step measured false), not for an observed miscompile. IR-only: clang-19 does not put `range` or a zero-excluding `nofpclass` on a dead lifted-callee parameter (15 function spellings in `probes/clang_param_attrs_t.c` at -O1 and -O2, plus -ffast-math and a static-callee IPSCCP probe; Q3).
- Call-site-only `range` is fine (`probes/p1b_callsite_range_nn.ll`: stripped in the clone; the twin call is minted fresh with no attributes).
- **Fix suggestion**: strip `range`/`nofpclass` from every recorded-dead parameter of the clone AT ITS OWN RECORD (right after `SpecDeadArgMask[Clone] = DeadSlots`) — before any twin of it exists — so every twin inherits the stripped set; keep the call-site strip. Pin it with a twin-bearing variant of `…_inner_arg_range.ll` (the shipped one has a classical `h2` return, so no twin, which is why it could not see this).
- Repro: `cd probes && ./run.sh S p1_twin_range_nn.ll 5; grep -n 'define internal void @__cq_q_h2_11_unc' $SCRATCH/r1A_nlfd/out/p1_twin_range_nn.S.s2.ll`.

### F-r1A-2 — P2 — the `buildClone` fence declines a program the oracle compiled to the CORRECT unitary: a `cq_theta` SOURCE at the top. INTRODUCED, IR-only, disclosed in the source.

`probes/p2_theta_src_inst_nn.ll`: `q = cq_theta(m&7,.5); r = h(q, m); q = cq_theta(q,.7)`; `h(a,k){ t = a*5; return h2(t,k); }`, `h2`'s slot 0 not null-safe and never read.

- ORACLE: exit 0, 1 warning (the lyyf M-A over-warn), 2b STRICT `1 verified, 0 violation(s), 0 unproven`; the clone does `mul_hl(h0,5)->h1; mul_hl_unc(h1,h0,5); free(h1)` and the trace is the twin's plus that compute/uncompute pair (`results/p2_theta_src_inst_nn.O.trace` vs `results/p2T.S.trace`) — **the same unitary as the twin**.
- S and A: `cq specialization: quantum argument to a parameter the lifted callee never reads` (in `__cq_q_h_01`). Twin `p2T.ll` accepts.

The source comment discloses it (*"OVER-DECLINES, knowingly: a caller operand that is a `cq_theta` SOURCE"*), but TRACK §1/§2 and the comment's lead sentence (*"Neither accept is the twin's"*) are false for this member: here the oracle's accept IS unitary-equivalent (Rule-8-clean, not byte-identical). Every OTHER member I built is a real fix: `p8_derived_only_reader_nn.ll` (a derived `p = q*3` read only by the call) was a wrong unitary on the oracle (`mul_hl(h0,3)` never uncomputed across `ry(h0,.7)`, warned), and declines on S. Reach: IR-only (needs a non-allowlisted attribute, see Q3); retirement = the owner's Q1. Correct the record sentence; no code change needed unless Q1 keeps the policy and the owner wants the member back.

### F-r1A-3 — P3 — L7: *"clang-19 `-O1` puts only allowlisted attributes on an int/fp parameter"* is false as stated

Measured (`probes/clang_param_attrs_t.c`): `int f12(int a,int k){return a;}` → `define noundef i32 @f12(i32 noundef returned %0, …)` — FunctionAttrs infers `returned`, which is outside `nullSafeSlot`'s allowlist. Harmless (a returned parameter is read by the clone's `ret`, so it is never a recorded-dead slot, and clones strip parameter `returned`), but the sentence stands in `Specialization.cpp:1030` and `spec_reject_phantom_arg_read_unread_scalar_inner_inst.ll:13`. Correct spelling: "…on an int/fp parameter that can be recorded dead".

### F-r1A-4 — P3 — Rule 14: the fence's diagnostic-location loop is a second spelling of "Existence ≠ Value"

`Specialization.cpp` ~1044–1050 re-derives "an INSTRUCTION operand in an unread scalar slot that is not rewritable" to find `Where`, independently of the `deadParamMask` pair that decides the decline. It only chooses the `!dbg`, so a divergence costs a location (it can point at an unrelated call, or at none), not a verdict. Either state that in the comment or derive `Where` from the same `FunctionLiveness` pair.

### F-r1A-5 — P3 — PRE-EXISTING, out of scope, recorded so it is not rediscovered: value-domain `range` rides on live integer HANDLE slots

`probes/p5_cache_hit.ll`: `__cq_q_h_01` calls `__cq_q_h2_01(i32 noundef range(i32 1, 100) %a, …)` where `%a` is a live runtime handle id, on the oracle and on S alike. `cloneFor` drops a slot's attributes only when its TYPE changes (fp→i32), so an integer handle slot keeps the user's value `range`, which says nothing about a handle number (h0 violates `range(1,100)`). Same latent class as F-1; not reached from C in what I measured (LLVM-19 IPSCCP did not add a parameter `range` on a `static` helper fed `q & 7`, `cattr/r.c`). No bead filed; the F-1 fix would naturally extend to "strip value constraints from every HANDLE slot of a clone".

---

## The seven questions

**Q1 — "a value in an unread int/fp slot is unobservable except through `range`/`nofpclass`."** Verifier enumeration (`opt -passes=verify`, an `i32` definition + call site): admitted on `i32` are `zeroext signext inreg noundef range nofree returned swiftself swiftasync alignstack allocalign writeonly` (+ string attributes); `nofpclass` on fp. Rejected on `i32`: `byval byref preallocated inalloca sret align noalias nocapture nest nonnull dereferenceable(_or_null) swifterror allocptr readnone readonly writable dead_on_unwind elementtype`; `immarg` "only applies to intrinsics". For each admitted one:
- `noundef` — `0` satisfies it. `range`/`nofpclass` — the two value constraints; stripped (but see F-1 for the twin).
- `zeroext`/`signext`/`inreg`/`alignstack`/`swiftself`/`swiftasync` — ABI placement; the call moves the value into a register/slot and nothing reads it (a `swiftasync` prologue spills the register into the frame record, which no program observes).
- `nofree`/`writeonly` — pointer semantics, vacuous on an integer.
- `allocalign` — describes a returned pointer; a clone never returns one (SpecializeReject's ABI-return clause), so no recorded slot carries a meaningful one.
- `returned` — the one that could bite: it makes the slot the return value. Clone PARAMETER `returned` is stripped (`stripStaleClassicalAttrs`, read). A CALL-SITE `returned` on a dead slot promises "`h2` returns this argument" while `h2`'s clone never reads it — false for any input the source does not already make UB, so not a C-reachable or well-defined input. The in-pass consumer that would read it (`CallBase::getReturnedArgOperand` via ValueTracking's `computeKnownBits`) sees an `Argument`, not the constant, inside the clone. Not constructed further.
- Function-level: `memory(argmem…)` talks about pointer arguments; `allocsize` needs a pointer return in clang. Neither applies to a clone.
- Independent support for the premise (from my reading of LLVM's `DeadArgumentElimination.cpp`, recalled — the LLVM source is not on this box, so this is NOT re-read here): DAE's `surveyUse` treats a value passed into a direct call's argument as live only if that argument turns out live, with no attribute test at the use site — the same rule as the Argument clause (direct forwarding only; any other instruction use is `Live` there, as it is under Existence here). MEASURED, and the stronger evidence: `clang -O1` in one TU writes `poison` into dead slots under `win64cc`/`vectorcall`/`preserve_most`/`swiftcc` alike and drops the callee parameter's `noundef` (`clang_param_attrs_t.c` → `@f3/f4/f10/f11(i32 poison, …)`, `define … @f1(i32 %0, i32 noundef %1)`).
Verdict: the claim holds for every int/fp parameter attribute LLVM 19 admits, modulo F-1 (a constraint the strip misses) — which is a gap in the strip, not in the premise.

**Q2 — the strip's reach.**
- *Cache hit* (`p5_cache_hit.ll`: `h2`'s clone reused from `g` (slot forward-dead) and `h` (slot live)): S TRACE-IDENT with `p5T` (h2 inlined into g and h); oracle TRACE-DIFF. The strip edits `h2clone`'s parameter once (a weakening, harmless to the live caller) and `g`'s call site only.
- *Call-site-only `range`*: clean (`p1b`, F-1).
- *fp ABI slots*: a QUANTUM fp slot is retyped to `i32` and `cloneFor` drops its whole attribute set, string attribute included, so it is null-safe and never in this population (`p6_fp_handle_nn.ll`: S ≡ O ≡ twin, the pre-existing rewrite path). A CLASSICAL fp slot is in it (`p7`): stripped at the forward clone, missed at the twin (F-1). `x86_fp80` is passed `x86_fp80 noundef` direct by clang on x86-64 (`f6`); its stack placement is backend ABI, not an IR read.
- *Unread in one clone, read in another clone of the same function*: records are keyed by clone `Function*`, and the strip only ever touches a callee whose record says dead; the p5 cache-hit pair covers the "same clone, dead for one caller, live for another" variant.
- *The twin*: MISSED — F-1.

**Q3 — the fence.** Condition: `Mask & ~DeadSlots` (a handle parameter live under Existence) whose bit is also set in `deadParamMask(Clone, Value)`. By reading `FunctionLiveness`, the two modes differ only at an INSTRUCTION operand of an unread scalar slot that is not rewritable — so the fence fires exactly when a handle parameter is kept alive only by such an instruction. An instruction ALSO consumed by a clone call or `cq_theta` is a root and live in both modes (no fire, by construction). Is `Existence ≠ Value` pinned? Yes: my M1 below collapses it and 3 fixtures crash.
- *Pre-emption*: the fence can fire only where a slot is not null-safe, i.e. only with a non-allowlisted attribute (or `returned`), so it cannot pre-empt any C-reachable owner (Q5 of my attribute survey). Among IR programs, the only correct-accept → decline I found is F-2's theta source; the derived-operand members (`i_inst_tc_nn_{cd,pd}`, `p8`) were wrong unitaries on the oracle.
- *`x_outer_nn`*: reproduced (S/A decline at `main`, step 1; oracle TRACE-DIFF, warned, 1 dirty; twin accepts). IR-only: of 15 C function spellings (plain, `regcall`, `ms_abi`, `vectorcall`, `preserve_most`, `swiftcall`, `_Bool`/`short`/`signed char`, `long double`, `__int128`, `_Float16`, `float`, `_BitInt(9)`, `annotate` on a parameter, a `static` callee, `-O2`, `-ffast-math`), clang-19 put only `noundef signext zeroext range nofpclass` on a parameter that could be dead, plus `returned` on a returned (live) one (F-3).
- **Commit A's whole surface is IR-only** — worth stating plainly in the record: the Argument clause changes nothing for a null-safe slot (already skipped as rewritable before nlfd), and a not-null-safe int/fp slot needs an attribute clang does not emit on a dead parameter. Consistent with the implementer's `e2e single-TU (0)` movers.

**Q4 — `sa1.ll`.** Re-run from r6's own copy (identical to the implementer's). argv 5, 3, 12: S `sa1` ≡ `mtT` byte-for-byte at all three; `mtT` S ≡ O; 2b STRICT `3 verified, 0 violation(s), 0 unproven` on S (oracle `2 verified`, warned). Oracle diff vs twin = exactly `cq_template_mul_i32_hl_unc(h1, h0, 3)` + `cqrt_free(h1)` missing — r6's finding reproduced. ⚠ The CENSUS on S reads `5 template rail mint(s) of which 1 left dirty` against `mtT`'s `3 … 0`: the one "dirty" mint is `%7 = __cq_q_h_01(…)`, a clone call returning the CLASSICAL `k+1`, which `free_pairing_check.py` counts as a template mint (`__cq_q_` prefix, line ~810). Census noise on a correct stream, pre-existing (the oracle's `2 dirty` includes it) — not a gate, noted so nobody reads it as a leak.

**Q5 — the 48-cell table.** Sampled 14 rows on S, O and A (`probes/cells_sample.txt`): `i_arg_tc_nn_cd`, `i_arg_mt_nn_pd`, `i_arg_tc_ns_pd`, `i_inst_tc_nn_cd`, `i_inst_tc_ns_pd`, `i_inst_tc_nn_lv`, `i_arg_tc_nn_lv`, `m_arg_tc_nn_pd`, `m_inst_tc_ns_pd`, `x_outer_nn`, `x_inst_live`, `x_classical_inst`, `x_nested_arg`, `x_arg_range`. Every S verdict matches TRACK §6 (TRACE-IDENT / TRACE-DIFF / decline string / 2b figures). A = S on all 14 (the mt row `i_arg_mt_nn_pd` is already TRACE-IDENT on A — commit A alone fixes it; B/C are not needed for any nlfd row I sampled). No sampled cell is worse on S than on the oracle; the only "worse" program I found anywhere is F-2's.

**Q6 — L2/L3: who else asks "is this operand read"?**
| consumer | question asked | nlfd effect | consistent? |
|---|---|---|---|
| `FunctionLiveness` Existence (records, `deleteDeadCones`) | rewritable slot, or ARGUMENT in unread scalar slot → not read | new Argument clause | An `Argument` has no operands, so **instruction liveness is unchanged** — `deleteDeadCones`' deletion set and `userProgramReads` cannot move; only `deadParamMask` moves |
| `FunctionLiveness` Value (fence only) | any unread scalar slot → not read | new | only the fence asks it |
| `deleteDeadCones` step 3 | rewrites rewritable slots only | none | an instruction in a not-rewritable unread slot is Existence-live, never in `Del` (M1 shows the crash if that breaks) |
| `resolvePhantomCloneArgReads` step 1/2 | bare record; decline quantum not-null-safe | sees MORE dead outer slots | `x_outer_nn`, `p9` (decline where the oracle wrong-accepted) |
| M-C (d0) `ArithLowering.cpp:654` | `isRewritableDeadSlot` → a not-null-safe dead slot is a READ | none | asymmetric with the Argument clause, sound by unreachability: M-C is off in clone bodies (`inBennettClone`), and a module-level `Argument` is never quantum |
| M-A `cloneArgReachesResult` | `isRewritableDeadSlot` → READ = exempting hop | none | unreachable, as the header says: step 1 declines the quantum not-null-safe case before `lowerRotations` |
| the pre-`specialize()` drop | `deadParamMask` with no records | none | records do not exist yet (L1) |
| cepm branch (`agent-a3c46257…`, `7f0be42f`): `predictReturnTainted` / `specCallResultPredictedClassical` | predicts return taint from the ORIGINAL body | none | asks no slot record; the fence and records do not change `ReturnTainted` |
| rhk5 branch (`agent-a7712272…`, `c7dad811`): `cloneCallPreservesArg` | does the clone WRITE the formal? walks uses, recursing into inner clone calls (B4) | a dead formal forwarded into an unread slot is still a USE; the walk recurses into `h2clone`, whose formal has no uses → preserved | a different question (write, not read); no record consulted; agrees |
So "not a read" now means two things (Existence, Value), both named in the header, and each consumer's asymmetry is either unreachable or the conservative direction. The one inconsistency is F-1's: the STRIP's set (forward clone param + call site) is narrower than the set of places the neutralised value reaches (+ the twin) — L2's shape: the rewrite set was widened (argument-carried slots) and the twin, computed over the same closure one step earlier, was not.

**Q7 — owner question Q1 (`nullSafeSlot`'s string/unknown refusal is a write policy).** Opinion, not a decision: relax it to LLVM's DAE standard for int/fp scalars, keeping an explicit `returned` refusal (callee or call site) and the existing pointer/`byval` family refusal. Evidence: (a) LLVM-19 DAE writes `poison` into a dead slot with no attribute test beyond `swifterror`/pass-pointee-by-value and a `naked` callee, stripping only UB-implying attributes (recalled from the source, not re-read here); writing the defined `0` is strictly stronger than that. (b) MEASURED: clang -O1 already does exactly this in-TU under every calling convention I tried (`f3/f4/f10/f11`), with a string-free attribute set in each case — so (b) shows the calling-convention half, not the string-attribute half. (c) The verifier admits no int/fp parameter attribute whose meaning depends on the value except `range`/`nofpclass` (stripped) and `returned` (keep refusing). (d) It would retire the fence (F-2), `x_outer_nn`'s decline, step 1's IR-only over-decline and the `m_*_nn_pd` residual — all IR-only, so the practical payoff is small and the risk is a future string attribute with real meaning (none on x86-64 parameters that I know of). If the owner keeps the policy, nothing is unsound today; the cost is IR-only over-declines.

---

## Standing lessons

- **L1** — records, the fence and the strip all run inside `specialize()`, after `repropagateControlMerges` in both entry points (`CQLoweringPass.cpp` 746→947, 1540→1624, read). The Argument clause needs a record, so its pre-`specialize()` callers (drop, volatile stages) are unaffected. Nothing grows taint. No re-ask owed.
- **L2/L3** — table above; F-1 is the L2 miss.
- **L4** — no wire question.
- **L5** — the one syntactic answer to a semantic question is `nullSafeSlot`'s attribute allowlist, which is now explicitly labelled a WRITE policy (owner Q1); `isUnreadScalarSlot`'s type test is the right syntactic proxy (a scalar slot is not dereferenced by the call — verifier-enforced, above).
- **L7** — F-1 (header + TRACK step 4), F-2 (TRACK §1/§2 "neither accept is the twin's"), F-3 ("only allowlisted attributes"). The header's DAE analogy is fair; I would add that DAE also refuses a `naked` callee (recalled from the LLVM source, not re-read; moot here: the verifier forbids any use of a naked function's arguments, so there is nothing to forward).
- **Rule 14** — F-4. `stripUnreadSlotValueConstraints` is correctly the one strip (called by the rewrite).
- **Rule 12** — the Argument clause's accepts are paired with `…_outer_nn` (a decline whose subject — an outer not-null-safe slot made dead by the clause — still exists: its `CHECK-NOT: CQ_DEADARG_DBG` pins the drop did not take it); the fence's two declines carry the same pin, and its two precision controls exist. Negatives are pure (one `CHECK-NOT` + one `CHECK` of the string, behind `not`). Missing: a twin-bearing variant of `…_inner_arg_range.ll` (F-1).

## Mutants (private tree, full lit)

| mutant | change | lit (2415) | verdict |
|---|---|---|---|
| boundary before | unmodified `a6a76840` | — | `cq-opt` `3685d41f…` = implementer's recorded A |
| **M1** | `if ((Mode == SlotReads::Value \|\| isa<Argument>(U.get())) && …)` → `if ((true) && …)` — Existence collapses into Value | **3 FAILED**: `spec_accept_…_unread_scalar_classical_inst`, `spec_reject_…_inner_inst`, `spec_reject_…_inner_inst_musttail` (each `cq-opt` rc=139, "Call parameter type does not match function signature!" — the bd 91k9 dangling use) | KILLED — the Existence/Value split is pinned, and its failure mode is loud |
| boundary after | source restored, rebuilt | — | `3685d41f…` again |

I did not re-run N0–N6 (brief: read, do not re-run). N2 (the int/fp type test) is argued equivalent in TRACK §11; I agree for today's consumers — every consumer that acts on a pointer slot's record is gated by `nullSafeSlot` or by quantum-ness, and a handle is never a pointer.

## Composition

- **A × B (ev3m)**: a `musttail` forward of an ignored argument into a NOT-null-safe slot is still not the drop's (the drop asks `nullSafeSlot`), so it falls to A: `i_arg_mt_nn_pd` is TRACE-IDENT on A alone and on A+B+C, identical streams.
- **A × C (m5pn)**: `i_inst_mt_nn_cd` — measured: A declines with the fence string, S declines with the same string, the oracle aborts (134). C's demotion runs in `cloneFor` (`stripStaleClassicalAttrs`), before the fence, and does not change the verdict.
- **A × rhk5 / cepm**: no composed program constructed. rhk5's walk asks about writes and would recurse into the unread-slot callee and answer "preserved" (table); cepm's prediction reads no record. Neither branch's binary contains A, so a composed measurement needs the merge build — owed at the merge gate, not before.

## Tested and did not break

`sa1` (3 inputs); 14 cells ×3 binaries; the cache-hit pair (`p5`); call-site-only `range` (`p1b`); fp-handle slot (`p6`, out of population by `cloneFor`'s attribute drop); classical fp slot (`p7`, correct trace, F-1 only); theta source (`p2`, F-2); derived operand read only by the clone call, instruction (`p8`) and argument (`p9`) forms — both were wrong unitaries on the oracle and decline on S, while their null-safe spellings (`p9ns`, `p2ns`) are taken by the pre-`specialize()` drop and are twin-identical on both binaries; the attribute survey; the `-O2` exploitation check.

## Beads

- **Filed: bd `test_C_libtooling-vaep`** (P2, F-r1A-1), discovered-from bd `nlfd`.
- Not filed: F-2 (disclosed in source; a record correction, and the owner's Q1 decides it), F-3/F-4 (hygiene), F-5 (pre-existing, latent, noted in vaep's fix suggestion).

## Housekeeping

The private worktree `<scratchpad>/rev_r1A_nlfd` is removed (`git worktree remove --force`). The commit-A binary is kept at `<scratchpad>/r1A_nlfd/cq-opt.A` (`3685d41f…`), and `probes/run.sh A` now points at it. Every probe reruns with `probes/run.sh {S|O|A} <probe>.ll <argv>`. Outputs go to `$OUT` (default `<scratchpad>/r1A_nlfd/out`). Key outputs are copied to `probes/results/`. `bd nlfd` has a summary note appended.
