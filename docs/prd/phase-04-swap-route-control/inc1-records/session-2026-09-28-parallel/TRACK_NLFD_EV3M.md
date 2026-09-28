# Track NLFD + EV3M — bd `test_C_libtooling-nlfd` (P2) and bd `test_C_libtooling-ev3m` (P3)

Session 2026-09-28 (parallel), implementer track. One agent for both beads because both live in bd
vsfp's dead-argument liveness / clone-building area. Branch `worktree-agent-a333a1777db2f2295`, off
`main` `9a230646`. **NOT self-cleared** — this owes an independent Rule-13 round (§13 is the
attack list). Probes, harnesses and raw results: `nlfd_probes/` (tools in `nlfd_probes/tools/`,
sources in `nlfd_probes/src/`, raw outputs in `nlfd_probes/results/`).

⚠ **READ §5 FIRST — a stop-and-ask condition fired and is reported, not pressed past.** Two of the
three changes (the ev3m drop and the clone-`musttail` demotion) make the `musttail` spelling of a
program behave exactly like its plain-`tail` spelling — which is the right invariant — and so they
ADD CUSTOMERS to the open P1 bd `rhk5` (warned): `musttail` spellings of rhk5-shaped programs that
the ORACLE declined (3jru) or aborted on (exit 134) now compile into rhk5's warned divergence,
byte-identical to what the ORACLE already emits for their plain-`tail` spelling. The three changes
are in THREE SEPARATE COMMITS (§0) so the orchestrator can land nlfd alone.

## 0. Headline

| commit | what | effect (measured, §6/§10) |
|---|---|---|
| A — bd nlfd | the liveness call-slot rule no longer counts a function ARGUMENT in an UNREAD SCALAR slot (recorded dead, int/fp) as a read (fix direction B); `buildClone` strips the slot's value constraints where the neutralised `0` now arrives, and DECLINES (fix direction A, the module-level step-1 rule one clone level down) when a surviving INSTRUCTION in such a slot keeps a HANDLE parameter alive for nothing | r6 `sa1.ll` TRACE-DIFF → **TRACE-IDENT** with its twin; the instruction sub-class → loud decline (was the oracle's wrong unitary, or an abort when `musttail`) |
| B — bd ev3m | the pre-`specialize()` dead-argument drop no longer refuses a `musttail` SITE (a constant operand changes no signature, calling convention or ABI attribute) | r5 `mt2`, r6 `mm1`, and the bead's forwarder shapes (`ev1`, `ev2`, `ev6`): 3jru DECLINE → **TRACE-IDENT** with their twins; an e2e 2-TU slice + twin + `-twin-identical` gate |
| C — found here | `stripStaleClassicalAttrs` demotes every `musttail` call in a CLONE body to a plain call | a PRE-EXISTING, C-reachable verifier ABORT (exit 134) → the plain-`tail` spelling's stream (byte-identical, measured) |

| commit | `cq-opt` | `libCQPass.so` | `cq-opt-debugalloc` | lit (discovered / passed / XFAIL / failed) |
|---|---|---|---|---|
| ORACLE `main` `9a230646` | `3f6db37f5cf937b4d70f5736` | `356df92e0b58bbf787c41a25` | `36033dbf6641b168d7917bc4` | not run here (2407 fixtures at that commit) |
| A `a6a76840` (bd nlfd) | `3685d41f7176ec2d47fb2995` | `befaf2335359ad6a17daf3f3` | `105dd712a9f07888f1a21622` | 2415 / 2414 / 1 / 0 |
| B `1008dbe3` (bd ev3m) | `de63c48fe1e80abcdef900e7` | `e01e3b707c045ae2dc134a93` | `a6f8941476fcdd44cfc54599` | 2417 / 2416 / 1 / 0 |
| C `3626a38d` (bd m5pn) = SUBJECT | `93c65d0da41df3fc52ddc45e` | `7c5d011a133adb92fb911dc9` | `f69cc2cd974b4d1a7db57d81` | 2418 / 2417 / 1 / 0 |

The SUBJECT is the binary every measurement below ran on (bit-identical before and after the commit
split, measured). The records commit after C changes no code.

## 1. bd nlfd — the mechanism, measured

Repro: r6's `sa1.ll` (r5 `mtN` stage-1 IR — r2B's `k19` main — with `h2`'s parameter 0 given the
string attribute `"cq.probe.opaque"`). Lowered on the ORACLE (`results/`, `out/sa1.O.s2.ll`):

```
main:          %7 = tail call i32 @__cq_q_h_01(i32 noundef %h_op, i32 noundef %5)   ; p = 3q passed
__cq_q_h_01:   %3 = tail call i32 @__cq_q_h2_01(i32 noundef %0, i32 noundef %1)     ; forwarded
__cq_q_h2_01(i32 noundef "cq.probe.opaque" %0, …)                                     ; slot 0 recorded dead
```

`h2`'s clone records slot 0 dead. In `h`'s clone the liveness call-slot rule asked
`isRewritableDeadSlot` = record ∧ `nullSafeSlot`; the string attribute fails the allowlist, so the
slot counted as a READ, `%0` was live, `deadParamMask(h's clone)` left bit 0 clear, and `main`'s
(null-safe) slot was never neutralised by `resolvePhantomCloneArgReads`. The uncompute spine then
saw an extra consumer of `p`'s rail and left it dirty across `cqrt_ry_i32(h0, 0.7)`:
`diff sa1.O.trace mtT.trace` = exactly `cq_template_mul_i32_hl_unc(h1, h0, 3)` + `cqrt_free(h1)`
missing (r6's finding, reproduced). On the SUBJECT `main` passes `i32 noundef 0` and the trace is
byte-identical to `mtT`'s.

**Why "READ is the conservative direction" was false for liveness.** Liveness answers two
different questions with one mark: (i) "must this operand still EXIST?" (so `deleteDeadCones` step 3
never deletes a value a call still uses — the reason round 5 counted non-rewritable slots) and
(ii) "is this operand's VALUE observed?" (what `deadParamMask` means by "dead parameter"). For an
INSTRUCTION operand (i) is real; for an ARGUMENT it is vacuous — an argument is never deleted — and
counting it answered (ii) wrongly, one clone level up.

**The instruction sub-class is different** (cells `i_inst_*_nn_{cd,pd}`, §6). `h(a,k){ t = a*5;
return h2(t,k); }` with `h2`'s slot not null-safe and dead: `%t` MUST survive (the call uses it and
the rewrite may not null the slot), so it reads `%a`; `%a` is live under (i) and dead under (ii).
Neither accept is the twin's: keeping `main`'s slot is bd tzfa's phantom read (the ORACLE: exit 0,
warned, TRACE-DIFF); neutralising it would lower `t = a*5` on runtime handle 0 (bd sqjq's hazard).
With `musttail` the ORACLE ABORTED instead (exit 134, §4).

## 2. bd nlfd — the fix and why it is sound

**(B) Argument clause** (`DeadValueLiveness.cpp`, `FunctionLiveness`): in the default
`SlotReads::Existence` mode an argument operand of a call slot is not marked live when the slot is
REWRITABLE (unchanged) or when it is an UNREAD SCALAR slot (`isUnreadScalarSlot` = recorded dead ∧
the slot's type is an integer or floating-point scalar) AND the operand is an `Argument`.

Soundness argument (the reviewers should attack each step):
1. *The record says the callee never observes the slot.* The inner callee is a clone (only clones
   have records), whose record is exact for the built clone (bd sqjq: the dead cone is deleted right
   after the record; an inner call inherits a dead slot). Its `_unc` twin is synthesised from the
   finished clone body, so it does not read the slot either.
2. *A scalar slot is not read by the CALL.* `byval`/`inalloca`/`preallocated` copy their pointee at
   the call site — pointer-only by the verifier — so they are excluded by the type test (mutant N2
   measures that exclusion's weight, §11).
3. *So the value in the slot is unobservable except through a VALUE CONSTRAINT on the slot.* This is
   LLVM's own DAE premise: `removeDeadArgumentsFromCallers` writes `poison` into a dead slot whatever
   its other attributes, stripping only the UB-implying ones. On an int/fp slot the constraints are:
   `noundef` (a concrete `0` satisfies it), `range`/`nofpclass` (stripped — below), `returned`
   (clones carry none: `stripStaleClassicalAttrs`), `allocalign` (constrains a RETURNED POINTER; a
   clone never returns a pointer — SpecializeReject's ABI-return clause admits void, i32 and the
   reversible fp widths only), `immarg` (intrinsics only). `inreg`/`signext`/`zeroext`/`alignstack`/
   `swiftself`/`swiftasync` are ABI placement, satisfied by any value. A string attribute has no IR
   semantics.
4. *Where a `0` now arrives, the two violable constraints are stripped.* After the record, for each
   parameter recorded dead, each use in an unread scalar slot the rewrite may not null gets
   `stripUnreadSlotValueConstraints` (the strip of the one rewrite, factored out of
   `rewriteRecordedDeadSlotUse`, without the write). Pinned by `…_inner_arg_range.ll` (mutant N3).
5. *The IR operand of a not-null-safe slot is never rewritten* — `nullSafeSlot`'s allowlist stays a
   WRITE policy (the drop and the module-level resolution keep leaving such a slot alone). The
   enclosing parameter is simply passed along; the runtime value it carries is decided one level up,
   where the slot IS null-safe (or, if it is not, `resolvePhantomCloneArgReads` step 1 declines a
   quantum operand there — cell `x_outer_nn`, §6).

**(A) the fence** (`Specialization.cpp`, `buildClone`, right after the record): if a HANDLE
parameter (`Mask`) is live under `SlotReads::Existence` (the record) but dead under
`SlotReads::Value` (no unread scalar slot observes its operand), decline with
`kMsgPhantomArgRead`, located at the first call whose not-null-safe unread scalar slot holds an
instruction. Existence and Value liveness differ ONLY at such slots, so the condition is exactly
"a surviving instruction keeps a handle parameter alive for a slot nobody reads". The string is the
module-level one (`resolvePhantomCloneArgReads` step 1), moved above `buildClone`. Precision
controls: `…_inner_inst_live.ll` (the instruction is ALSO read by a live root → no decline, mutant
N4) and `…_classical_inst.ll` (a CLASSICAL parameter kept alive that way costs nothing → no decline,
mutant N5).

What (A) over-declines, knowingly: every module in the instruction sub-class, although the
hand-inlined twin accepts; IR-only as far as measured (clang-19 `-O1` on x86-64 puts only
`noundef`/`signext`/`zeroext`/`range`/`nofpclass` on an int/fp parameter — r5/r6's measurement, not
re-derived here), and a caller operand that is a `cq_theta` SOURCE (the module-level step 2 would
have exempted it). A twin-identical accept of that sub-class needs a constant written into the
not-null-safe slot — exactly what `nullSafeSlot`'s policy forbids — so it is an OWNER question
(§15, Q1), not an implementation gap.

## 3. bd ev3m — the mechanism and the fix

After bd vsfp the only C shape measured to hit the 3jru refusal where the twin compiles is a
`musttail` forward of an ignored quantum argument: the drop refused a `musttail` SITE, so the call
kept reading the operand, its result stayed conservatively tainted, and a user of that result made
`declineQuantumReturnCalls` speak (`mm1`: `in function main: cq taint escape: quantum value returned
across a function boundary`). The plain-`tail` spelling (`mmN`) is dropped and compiles
twin-identically on the ORACLE.

**Fix:** `dropEligibleSlot` and the drop's own site filter no longer refuse `musttail`
(`SpecializeDetect.cpp`). The bead's "cheaper candidate route" — see through a `musttail` forward and
rewrite both call sites together to keep the signature match — needs NOTHING extra: the drop
rewrites an OPERAND, never a signature, so there is no signature to keep in step, and its existing
fixpoint walks a forwarding chain one site per turn (`ev2`: three drops, one per `musttail` site, §9). LLVM 19's
`Verifier::verifyMustTailCall` checks: varargs match, return-type congruence, calling-convention
match, the call immediately precedes `ret` (optional bitcast) returning its value, parameter
COUNT/TYPE congruence of the caller's and the call's prototypes, and equality of the ABI-impacting
parameter attributes (`sret`, `byval`, `inalloca`, `inreg`, `alignstack`, `swiftself`,
`swiftasync`, `swifterror`, `preallocated`, `byref`, and `align` with byval/byref) between the
caller's parameters and the CALL SITE's. A constant operand changes none of these; the drop's strip
touches only `range`/`nofpclass`, which are not in that list. Measured: every rewritten `musttail`
module passes the in-process verifier (`cq-opt` exit 0), and the MT lines of
`spec_accept_dropped_arg_musttail_{return,forward_chain,kept}.ll` pin that the call is still a
`musttail` call with `0` in the dropped slot.

Retired conservatism: `spec_accept_dropped_arg_musttail_kept.ll` pinned it ("so that relaxing it is a
decision (mutant R7 flips it)") — ev3m is that decision; the file now pins the drop (name kept, L8).

## 4. A pre-existing ABORT the cell table found: `musttail` inside a clone

`int h(int a,int k){ __attribute__((musttail)) return h2(a,k); }` with `h2` READING `a`, called with a
quantum `p` (probe `mtl`, plain C, 2 TUs): `h`'s clone keeps the `musttail` marker `CloneFunction`
copied; `h2`'s clone returns a quantum rail, so `h`'s Bennett wrap copies it out AFTER the inner call;
the verifier then aborts the whole run — `musttail call must precede a ret with an optional
bitcast`, **exit 134 on the ORACLE**, measured (cells `i_*_mt_*_lv`, `i_inst_mt_nn_*`; `mtl`, `ev7`).
PRE-EXISTING (nothing in this track creates the marker), C-reachable, loud (an abort, not a silent
accept). Fix (commit C): `stripStaleClassicalAttrs` — applied to every clone and every `_unc` twin —
demotes each `musttail` call in the body to no tail kind. `musttail` guarantees only the tail-call
LOWERING; the call, its operands and its result are unchanged, and a clone is acyclic (recursion is
declined), so no stack guarantee is load-bearing. Measured: each such module's trace is then
byte-identical to its plain-`tail` spelling's trace on the ORACLE (`mtl`≡`mtlN`, `ev7`≡`ev7N`, and the
four `i_*_mt_*_lv` ≡ `i_*_tc_*_lv` cells). Pinned by `spec_accept_musttail_in_clone_demoted.ll`
(mutant D1). Filed as a new bead (§17).

## 5. ⚠ STOP-AND-ASK: commits B and C add customers to the open P1 bd `rhk5`

bd `rhk5` (P1, warned, PRE-EXISTING): a tainted-arg clone call scheduled between a derived chain
(`p = q*3`) and that chain's phase consumer leaves the chain's template rails dirty across a later
Ry. It is exactly what the plain-`tail` spellings below already compile into on the ORACLE:

| probe | shape | ORACLE | SUBJECT | SUBJECT vs plain-`tail` sibling on the ORACLE |
|---|---|---|---|---|
| `ev9` (commit B) | `f` calls `g(q,k)` (reads `q`) between `p` and `u = p^q`, ends `musttail return h2(p, z)` (`h2` ignores `p`) | DECLINE (3jru) | exit 0, 1 warning, `2 left dirty` | trace byte-identical to `ev9N` on the ORACLE |
| `ev7` (commit C) | `h(a,b,k){ musttail return h2(a,b,k); }`, `h2` ignores `a`, reads `b`; `main` passes `(p, q, m)` | ABORT (134) | exit 0, 1 warning, `2 left dirty` | ≡ `ev7N` on the ORACLE |
| `mtl` (commit C) | `h` musttail-forwards a READ argument | ABORT (134) | exit 0, 1 warning, `1 left dirty` | ≡ `mtlN` on the ORACLE |

"Pre-existing" is true of rhk5 and false of its population: these are the `musttail` spellings of
programs whose plain-`tail` spellings the ORACLE already compiles into rhk5. Commit B turns a
DECLINE into rhk5's warned exit-0 stream for them; commit C turns an ABORT into it. (In each probe
measured the dirty rails are REDUNDANT records — the measured result register is itself a complete
record of `q` — so the joint measurement statistics equal the twin's; that is an argument about
these probes, not about rhk5's class.) Commit A adds no rhk5 customer that I found: its accepts
(`sa1`, `x_nested_arg`, `x_arg_range`) are TRACE-IDENT with their twins, and its two controls keep
the ORACLE's streams byte-for-byte. **Decision owed (orchestrator/owner): land A alone; or A+B+C
with rhk5's population growth recorded (the bd vsfp round-3 precedent for `d2.c`); or hold B and C
until rhk5 is fixed.**

## 6. The interaction table — (null-safe? × musttail? × recorded-dead? × operand) — every cell against its hand-inlined twin

`tools/gen_cells.py` (IR subjects + hand-inlined IR twins), `tools/pairs.py`, args `5 7`. INNER cells
put the slot under test inside a clone (`main → h (clone) → h2`); MODULE cells put it in a user
function (`w` musttail/tail-returns `h2(X, k)`, r6 `mm1`'s shape). `cd` = `h2` reads the argument only
in an empty diamond (dead only after the CLONE's flatten — IR-only); `pd` = never read; `lv` = read.
`ns`/`nn` = null-safe / not (a string attribute). `arg`/`inst` = the slot's operand is the parameter /
`param * 5`.

Legend: TRACE-IDENT / TRACE-DIFF = both accept, traces equal / not; VERDICT-DIFF = one declines or
aborts; DECL-SAME = both decline with one string. "dirty" is stage 2b's template-rail census. ⟵ marks
a row whose verdict moved. The SUBJECT column is `cells_S2.txt` (binary with A+B+C; the final binary
`93c65d0da41df3fc` differs from it by comments only — re-measured on the final binary, §10).

| subject | twin | ORACLE | SUBJECT |
|---|---|---|---|
| `i_arg_mt_ns_cd` | `iT_arg_cd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_arg_mt_ns_pd` | `iT_arg_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_arg_mt_ns_lv` | `iT_arg_lv` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines ⟵ |
| `i_arg_mt_nn_cd` | `iT_arg_cd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines ⟵ |
| `i_arg_mt_nn_pd` | `iT_arg_pd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines ⟵ |
| `i_arg_mt_nn_lv` | `iT_arg_lv` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines ⟵ |
| `i_arg_tc_ns_cd` | `iT_arg_cd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_arg_tc_ns_pd` | `iT_arg_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_arg_tc_ns_lv` | `iT_arg_lv` | TRACE-DIFF — exit 0, warn 1, dirty 1, 25 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines |
| `i_arg_tc_nn_cd` | `iT_arg_cd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines ⟵ |
| `i_arg_tc_nn_pd` | `iT_arg_pd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines ⟵ |
| `i_arg_tc_nn_lv` | `iT_arg_lv` | TRACE-DIFF — exit 0, warn 1, dirty 1, 25 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines |
| `i_inst_mt_ns_cd` | `iT_inst_cd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_inst_mt_ns_pd` | `iT_inst_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_inst_mt_ns_lv` | `iT_inst_lv` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 28 lines ⟵ |
| `i_inst_mt_nn_cd` | `iT_inst_cd` | VERDICT-DIFF — ABORT (exit 134) | **VERDICT-DIFF** — decline: cq specialization: quantum argument to a parameter the lifted callee n |
| `i_inst_mt_nn_pd` | `iT_inst_pd` | VERDICT-DIFF — ABORT (exit 134) | **VERDICT-DIFF** — decline: cq specialization: quantum argument to a parameter the lifted callee n |
| `i_inst_mt_nn_lv` | `iT_inst_lv` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 28 lines ⟵ |
| `i_inst_tc_ns_cd` | `iT_inst_cd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_inst_tc_ns_pd` | `iT_inst_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `i_inst_tc_ns_lv` | `iT_inst_lv` | TRACE-DIFF — exit 0, warn 1, dirty 1, 28 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 28 lines |
| `i_inst_tc_nn_cd` | `iT_inst_cd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 15 lines | **VERDICT-DIFF** — decline: cq specialization: quantum argument to a parameter the lifted callee n ⟵ |
| `i_inst_tc_nn_pd` | `iT_inst_pd` | TRACE-DIFF — exit 0, warn 1, dirty 1, 15 lines | **VERDICT-DIFF** — decline: cq specialization: quantum argument to a parameter the lifted callee n ⟵ |
| `i_inst_tc_nn_lv` | `iT_inst_lv` | TRACE-DIFF — exit 0, warn 1, dirty 1, 28 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 28 lines |
| `m_arg_mt_ns_cd` | `mT_arg_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_mt_ns_pd` | `mT_arg_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines ⟵ |
| `m_arg_mt_ns_lv` | `mT_arg_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_mt_nn_cd` | `mT_arg_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_mt_nn_pd` | `mT_arg_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_mt_nn_lv` | `mT_arg_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_tc_ns_cd` | `mT_arg_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_tc_ns_pd` | `mT_arg_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines |
| `m_arg_tc_ns_lv` | `mT_arg_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_tc_nn_cd` | `mT_arg_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_tc_nn_pd` | `mT_arg_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_arg_tc_nn_lv` | `mT_arg_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_mt_ns_cd` | `mT_inst_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_mt_ns_pd` | `mT_inst_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines ⟵ |
| `m_inst_mt_ns_lv` | `mT_inst_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_mt_nn_cd` | `mT_inst_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_mt_nn_pd` | `mT_inst_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_mt_nn_lv` | `mT_inst_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_tc_ns_cd` | `mT_inst_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_tc_ns_pd` | `mT_inst_pd` | TRACE-IDENT — exit 0, warn 0, dirty 0, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines |
| `m_inst_tc_ns_lv` | `mT_inst_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_tc_nn_cd` | `mT_inst_cd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_tc_nn_pd` | `mT_inst_pd` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **VERDICT-DIFF** — decline: cq taint escape: quantum value returned across a function boundary |
| `m_inst_tc_nn_lv` | `mT_inst_lv` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |

**Reading it.** Every moved row is one of four kinds:
- `i_arg_*_nn_{cd,pd}` (4 rows) — **bd nlfd (commit A)**: TRACE-DIFF (the ORACLE's tzfa phantom,
  warned, 1 dirty) → **TRACE-IDENT**.
- `i_inst_tc_nn_{cd,pd}` (2 rows) — **the fence (commit A)**: the ORACLE's wrong accept → a loud
  decline; the twin accepts (the knowing over-decline, §2). `i_inst_mt_nn_{cd,pd}` decline too (the
  ORACLE aborted there, exit 134).
- `i_*_mt_*_lv` (4 rows) — **the demotion (commit C)**: ABORT → exit 0 with the stream of the
  plain-`tail` sibling `i_*_tc_*_lv` (byte-identical traces, `mtvstc_S2.txt`), which is TRACE-DIFF
  against the hand-inlined twin on the ORACLE and here alike (bd rhk5's shape + the known clone
  copy-out; PRE-EXISTING).
- `m_{arg,inst}_mt_ns_pd` (2 rows) — **bd ev3m (commit B)**: the 3jru decline → **TRACE-IDENT**.

Every unmoved non-IDENT row is PRE-EXISTING and IR-only or the twin's own verdict: the `lv` rows
(rhk5 / copy-out), the `m_*_cd` rows (a branch-only read the pre-`specialize()` drop cannot see — an
IR-only shape, `-O1` folds an empty diamond — so the module-level call keeps reading and 3jru speaks),
the `m_*_nn_pd` rows (a not-null-safe MODULE slot: the drop may not write it — the §15 Q1 residual),
and the `m_*_lv` rows (DECL-SAME: the twin returns a quantum value too).

The EXTRA probes (precision controls, nesting, strip, the outer-not-null-safe L2 case):

| subject | twin | ORACLE | SUBJECT |
|---|---|---|---|
| `x_inst_live` | `x_inst_liveT` | TRACE-DIFF — exit 0, warn 1, dirty 1, 21 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 21 lines |
| `x_nested_arg` | `x_nested_argT` | TRACE-DIFF — exit 0, warn 1, dirty 1, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines ⟵ |
| `x_arg_range` | `x_arg_rangeT` | TRACE-DIFF — exit 0, warn 1, dirty 1, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines ⟵ |
| `x_classical_inst` | `x_classical_instT` | TRACE-DIFF — exit 0, warn 1, dirty 1, 25 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines |
| `x_outer_nn` | `x_outer_nnT` | TRACE-DIFF — exit 0, warn 1, dirty 1, 12 lines | **VERDICT-DIFF** — decline: cq specialization: quantum argument to a parameter the lifted callee n ⟵ |

- `x_nested_arg`, `x_arg_range` — commit A, **TRACE-IDENT**.
- `x_inst_live`, `x_classical_inst` — the fence's precision controls; the SUBJECT's trace equals the
  ORACLE's byte-for-byte (measured with `cmp`), and both are TRACE-DIFF against the twin for bd
  rhk5's reason.
- `x_outer_nn` — L2 (c): the ORACLE's tzfa phantom accept → the module-level step-1 decline.

C-level probes (2 TUs where a library is involved; `tools/gen_c.py`), each against its hand-inlined
twin and, where it exists, its plain-`tail` spelling:

| subject | twin | ORACLE | SUBJECT |
|---|---|---|---|
| `mtl` | `mtlT` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines ⟵ |
| `mtl` | `mtlN` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-IDENT** — exit 0, warn 1, dirty 1, 25 lines ⟵ |
| `mtlN` | `mtlT` | TRACE-DIFF — exit 0, warn 1, dirty 1, 25 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 1, 25 lines |
| `ev1` | `ev1T` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines ⟵ |
| `ev1N` | `ev1T` | TRACE-IDENT — exit 0, warn 0, dirty 0, 12 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines |
| `ev2` | `ev2T` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines ⟵ |
| `ev4` | `ev4T` | TRACE-IDENT — exit 0, warn 0, dirty 1, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `ev6` | `ev6T` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 12 lines ⟵ |
| `ev7` | `ev7T` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-DIFF** — exit 0, warn 1, dirty 2, 23 lines ⟵ |
| `ev7` | `ev7N` | VERDICT-DIFF — ABORT (exit 134) | **TRACE-IDENT** — exit 0, warn 1, dirty 2, 23 lines ⟵ |
| `ev8` | `ev8T` | DECL-SAME — decline: cq taint escape: quantum value returned across a function boundary | **DECL-SAME** — decline: cq taint escape: quantum value returned across a function boundary |
| `ev9` | `ev9T` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-DIFF** — exit 0, warn 1, dirty 2, 16 lines ⟵ |
| `ev9` | `ev9N` | VERDICT-DIFF — decline: cq taint escape: quantum value returned across a function boundary | **TRACE-IDENT** — exit 0, warn 1, dirty 2, 16 lines ⟵ |
| `ev9N` | `ev9T` | TRACE-DIFF — exit 0, warn 1, dirty 2, 16 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 2, 16 lines |
| `ev7N` | `ev7T` | TRACE-DIFF — exit 0, warn 1, dirty 2, 23 lines | **TRACE-DIFF** — exit 0, warn 1, dirty 2, 23 lines |
| `mt3` | `mt3T` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `mt3N` | `mt3T` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |
| `mt2N` | `mt2T` | TRACE-IDENT — exit 0, warn 0, dirty 0, 14 lines | **TRACE-IDENT** — exit 0, warn 0, dirty 0, 14 lines |

- `ev1`, `ev2`, `ev6` (the bead's forwarder, a 3-deep `musttail` chain, a forwarder that computes on
  the argument first), `mm1`, `mt2` (seed table) — **bd ev3m**: the 3jru decline → **TRACE-IDENT**.
- `mtl`, `ev7` (commit C) and `ev9` (commit B) — **§5**: now ≡ their plain-`tail` spellings on the
  ORACLE (byte-identical), which are rhk5's warned TRACE-DIFF.
- `ev4` (a `musttail` forward two levels below `main`) — TRACE-IDENT before and after (the clone route
  handled it on the ORACLE; the drop now does).
- `ev8` (a `musttail` forward of a LIVE quantum argument, module level) — DECL-SAME with its twin (the
  twin returns a quantum value too).

## 7. Predicates added / changed

| predicate | where | change |
|---|---|---|
| `isUnreadScalarSlot(CB, A, taint)` | DeadValueLiveness.{h,cpp} | NEW: `isRecordedDeadSlot` ∧ int/fp slot type (by the call's function type) |
| `stripUnreadSlotValueConstraints(CB, A)` | DeadValueLiveness.{h,cpp} | NEW: the `range`/`nofpclass` strip, factored out of `rewriteRecordedDeadSlotUse` (which calls it — Rule 14, one strip) |
| `SlotReads` + `FunctionLiveness(F, taint, Mode)` + `deadParamMask(F, taint, Mode)` | DeadValueLiveness.{h,cpp} | NEW mode parameter (default `Existence` = every existing caller, byte-unchanged except the Argument clause); `Value` asked only by the fence |
| the liveness call-slot rule | `FunctionLiveness` | CHANGED: + the Argument clause (Existence) / every unread scalar slot (Value) |
| the fence | `buildClone` | NEW decline, `kMsgPhantomArgRead` (moved above `buildClone`, same string) |
| the strip of an Argument-carried dead slot | `buildClone` | NEW |
| `dropEligibleSlot` | SpecializeDetect.cpp | CHANGED: no `musttail` refusal |
| the drop's site filter | `dropDeadCallArguments` | CHANGED: no `musttail` refusal |
| `stripStaleClassicalAttrs` | SpecializeClone.cpp | CHANGED: + `musttail` → no tail kind |

Rule 14: the fence CALLS `deadParamMask`/`isUnreadScalarSlot`/`isRewritableDeadSlot`, it re-derives
nothing; the strip is the one rewrite's own strip, factored out. `nullSafeSlot` is unchanged and still
the one WRITE question; `isUnreadScalarSlot` is a different question ("is the value observed?"), and
the header says so at both predicates.

## 8. L1 / L2 / L3

- **L1.** Every changed stage runs outside the round-1/round-2 window or reads nothing a round-2
  delta can falsify. The drop (slots A and B) runs before any detection in both entry points
  (`CQLoweringPass.cpp` 176/406 and 1289/1391); its premise ("no stage has read the argument yet")
  is unchanged by admitting `musttail` sites. `buildClone` (record, fence, strip) and `cloneFor`
  (the demotion) run inside `specialize()`, AFTER `repropagateControlMerges` in both entry points
  (745→946, 1539→1623), so they see the post-fixpoint module; the fence's premise is the clone's own
  `Mask` and records, both written in `specialize()`. `FunctionLiveness`'s new clause needs a
  record, and records exist only from `specialize()` on, so its pre-specialize callers (the drop,
  the volatile stages' `deleteDeadCones`) are byte-unchanged. Nothing grows the taint set: the strip
  removes attributes, the demotion changes a tail-call kind, the drop writes constants (a shrink).
- **L2 (widening a set).** The Argument clause widens the set of slots that do not make an operand
  live. Other sets computed over the same closure: (a) `deleteDeadCones`' deletion set — unaffected
  (an argument is never deleted; step 3 only rewrites operands of dead INSTRUCTIONS, and an
  instruction in a not-null-safe unread slot is still live); (b) `userProgramReads`' liveness —
  asks instruction liveness only, which the clause does not change (an argument has no operands to
  propagate); (c) the record consumers (`resolvePhantomCloneArgReads`, M-C (d0), M-A) — now see MORE
  recorded-dead outer slots; step 1 declines a quantum operand in such a slot when it is not
  null-safe (`x_outer_nn`, A→D: the ORACLE accepted it with bd tzfa's phantom read, TRACE-DIFF vs
  the twin), step 2 neutralises and checks the rest; M-C/M-A ask `isRewritableDeadSlot` on the
  neutralised constant. ev3m widens the drop's eligible sites: the census of every corpus module
  containing `musttail` is in §10 (CENSUS).
- **L3 (narrowing / a new caller).** The fence is a new caller of `deadParamMask` in a new mode, and
  of `isUnreadScalarSlot`/`isRewritableDeadSlot`; neither callee's retirement trigger is affected
  (`isRewritableDeadSlot`'s M-A trigger names `resolvePhantomCloneArgReads` step 1, unchanged). The
  demotion narrows nothing another predicate names: no predicate in the pass asks
  `isMustTailCall()` except the drop (changed here) — `grep -rn isMustTailCall ir-pass/src` after the
  change: only the demotion.

## 9. Fixtures and e2e (Rule 12)

Generated by `nlfd_probes/tools/mkfix.py` (the vsfp mkfix convention: CHECKs DERIVED from the
SUBJECT's output only after its trace was measured equal to the hand-inlined twin's, the ordered
call stream pinned EXACTLY with a CHECK-NOT between matches, census lines pinned or forbidden;
`mkfix.py --check` re-derives every file and diffs — clean). Red-green through the fixtures' OWN
RUN lines against the ORACLE binary (`tools/redgreen.sh`, a scratch lit site config):

| fixture | commit | kind | ORACLE | SUBJECT | killed by |
|---|---|---|---|---|---|
| `spec_accept_phantom_arg_read_unread_scalar_inner_arg.ll` (r6 `sa1`) | A | accept, twin's stream | **FAIL** | PASS | N1 |
| `…_unread_scalar_inner_arg_range.ll` | A | accept + STRIP lines | **FAIL** | PASS | N1, N3 |
| `…_unread_scalar_nested_arg.ll` | A | accept, twin's stream | **FAIL** | PASS | N1 |
| `…_unread_scalar_inner_inst_live.ll` | A | precision control (CLONE stream pinned) | PASS | PASS | N4 |
| `…_unread_scalar_classical_inst.ll` | A | handle-mask control | PASS | PASS | N4, N5 |
| `spec_reject_phantom_arg_read_unread_scalar_inner_inst.ll` | A | decline (the fence) | **FAIL** (wrong accept) | PASS | N6 |
| `…_unread_scalar_inner_inst_musttail.ll` | A | decline (the fence) | **FAIL** (abort 134) | PASS | N6 |
| `…_unread_scalar_outer_nn.ll` | A | decline (module step 1, L2) | **FAIL** (wrong accept) | PASS | N1 |
| `spec_accept_dropped_arg_musttail_return.ll` (r6 `mm1`) | B | accept + DROP + MT lines | **FAIL** (3jru) | PASS | E1 |
| `spec_accept_dropped_arg_musttail_forward_chain.ll` (`ev2`) | B | accept + 3 DROP + MT lines | **FAIL** (3jru) | PASS | E1 |
| `spec_accept_dropped_arg_musttail_kept.ll` | B | CHANGED: pinned the retired conservatism, now pins the drop (name kept, L8) | **FAIL** | PASS | E1 |
| `spec_accept_phantom_arg_read_musttail_inner_slot.ll` | B | RE-SPELLED (branch-only read) — the drop had removed its subject (Rule 12(c)): before the re-spell it went RED on the SUBJECT on its NODROP/CLONE lines | PASS | PASS | — (W1, bd vsfp's, not re-run) |
| `spec_accept_musttail_in_clone_demoted.ll` (`mtl`) | C | accept, CLONE has no `musttail`, the original `h` keeps it | **FAIL** (abort 134) | PASS | D1 |

`ls ir-pass/test/*.ll | wc -l`: **2418** (`main` `9a230646`: 2407, counted with `ls-tree`; +11 new,
2 changed: A +8, B +2 new / 2 changed, C +1). The two controls pass on the ORACLE by design — they
pin what must NOT move.

**e2e (commit B), 3 new ctest entries:** `e2e-slice-spec-dropped-arg-musttail-return` (2-TU,
`run_slice_multi.sh`; r5 `mt2` with the result USED by `main`'s return), `…-twin` (hand-inlined,
`run_slice.sh`), `e2e-spec-dropped-arg-musttail-return-twin-identical`. Measured with the harness
recipe (`tools/mkgold.sh`, `tools/gold_e2e.sh`): the ORACLE DECLINES the slice (`cq taint escape:
quantum value returned across a function boundary`); the SUBJECT exits 0, 14 trace lines, 2b STRICT
`3 verified, 0 violation(s), 0 unproven`, CENSUS `3 template rail mint(s) of which 0 left dirty`,
TWIN-IDENT (the twin is 14 lines on both binaries). ⚠ An intermediate spelling stored the result to
a `volatile` sink and the ORACLE then declined at the STORE refusal instead of 3jru — the slice
would have pinned the wrong owner; it now returns `w(…) - argc - 1` (exit 0 under `pipefail`).
**The existing `e2e-slice-spec-dropped-arg-musttail-inner` pair changed what it witnesses**: since
commit B the drop takes that program before `specialize()` (census: `drop arg 0 of @h2 in @h`,
`drop arg 0 of @h in @slice`), its golden is unchanged (measured == the committed golden), and its
CMake comment and C header now say so; the in-clone `musttail` slot it was written for is pinned
at IR level only (the re-spelled fixture above).

## 10. Measurements (literal)

All on the SUBJECT `93c65d0da41df3fc` unless a row says otherwise; LOAD-CAVEAT: the box carried
other agents' load (1-min load average up to ~480 during the sweeps); every sweep is deterministic
and none has a timeout, so contention cost wall-clock only.

**Layers run, literally:**
- `cd build && lit -j4 ir-pass/test` on each commit: A **2415 discovered, 2414 passed, 1 XFAIL, 0
  failed**; B **2417 / 2416 / 1 / 0**; C (= SUBJECT) **2418 / 2417 / 1 / 0**.
- `ctest --test-dir build -j4 -R "spec|twin-identical|multi|scrub|taintset|volatile|free-pairing-selftest|cq-opt-equivalence$"`
  on the SUBJECT: **106/106 passed**, 310.44 s (includes `taintset-scrub-guard-selftest`, every
  `*-twin-identical` gate, all 2-TU slices and the SAMPLED `cq-opt-equivalence` — the full
  `cq-opt-equivalence-full` sweep was NOT run). On stage B: `ctest -R "musttail|byval-slot"` **7/7**.
  Before the split: `ctest -j4 -R "musttail|byval-slot|spec-dropped|volatile"` **27/27**.
- `python3 tools/update_code_map.py --check` → clean at each of A, B, C (regenerated per commit).
- e2e by hand with the harness recipe (`tools/gold_e2e.sh`): the new `musttail-return` slice and the
  existing `musttail-inner` slice, SUBJECT and ORACLE — §9.

**Corpus A/B** (`tools/ab.py`, `tools/final_ab.sh`; exit code, stdout sha-256, first error line; 4
workers). Denominator **4496** modules = lit **2418** + e2e single-TU **610** (636 (source, CASE)
jobs; 26 need another TU and were NOT swept) + multi-TU **33** (every `run_slice_multi.sh` entry,
libs llvm-linked) + probe **1435** (every stage-1 `.ll`/`.c` of session-2026-09-25's
`review_r{1A..6}_vsfp`, `vsfp_probes`, `review_r2A_9bhg`, and this track's `nlfd_probes/src`; the
`.c` built with its `.lib.c` where one exists; 0 build failures).

| A → B | movers | D→A | A→D | STRING | STREAM |
|---|---|---|---|---|---|
| SUBJECT → SUBJECT (NULL, run FIRST) | **0** of 4496 | | | | |
| ORACLE → SUBJECT | **83** | 34 | 8 | 5 | 36 |
| stage A → SUBJECT (what B + C add) | **56** | — | — | — | — (every one contains `musttail`) |

ORACLE → SUBJECT, classified (`results/final_ab_OS.txt`; `tools/movers.py`):
- **lit (11)**: exactly this track's 13 new/changed fixtures minus the two precision controls (which
  do not move by design): 3 D→A, 2 A→D, 1 STRING (abort → decline), 5 STREAM. Nothing else in the
  2418-fixture suite moved.
- **multi (2)**: `e2e-slice-spec-dropped-arg-musttail-return` D→A (twin-identical, §9);
  `e2e-slice-spec-dropped-arg-musttail-inner` STREAM (now dropped pre-`specialize()`; golden
  unchanged, `ctest` green).
- **e2e single-TU (0).**
- **probe (70)**: this track's own probes (every one in §6's tables, with its twin verdict) and six
  prior-session modules: r5 `mt1.c`/`mt1.s1.ll` STREAM (TRACE-IDENT with `mtT` before and after),
  r5 `mt2.c` D→A and r6 `mm1.c` D→A (TRACE-IDENT with their twins), r6 `sa1.ll` STREAM (TRACE-DIFF →
  TRACE-IDENT), r2 `musttail_kept.ll` STREAM (the fixture's own copy).
- The first ORACLE → SUBJECT run (same binary, a corpus built before `…_outer_nn` existed; null 0 of
  4491) gave 80 movers; the final run's 83 are those 80 plus the three `outer_nn` modules, nothing
  else (`tools/movers.py`: 0 GONE, 3 NEW).

**Drop census A/B** (`tools/census.py`: `CQ_DEADARG_DBG=1` lines over every corpus module
containing `musttail` — the only construct commit B changes the drop for; the vsfp lesson that a
decline fixture can lose its subject with no stdout/stderr move): **96 modules, 55 census movers**,
every one this track's fixture/probe, a prior-session `musttail` probe (r5 `mt1`/`mt2`/`mt3`, r6
`mm1`), the r2 copy of `…_musttail_kept.ll`, or the `musttail-inner` e2e slice. **No lit DECLINE
fixture lost its subject.**

**Probe families on the SUBJECT, re-run after the commit split** (`tools/run_all.sh S FINAL`,
`results/*_FINAL.txt`): byte-identical to the pre-split runs (`cells_S2`, `mtvstc_S2`, `c_S2`,
`seed_S2`, `x_S3`).

## 11. Mutation matrix

`nlfd_probes/tools/mutants.py`: a SCRATCH copy of the tree with its own build dir (no binary a
measurement of the worktree reads is ever relinked); one anchored replacement per mutant (the
anchor must match exactly once); all four targets rebuilt; a binary equal to the base refused, a
null NOT equal to it aborts; then the FULL lit suite (`lit -j4`, 2418 fixtures) through the scratch
build's own site config. Base build = the SUBJECT, bit-identical (`93c65d0da41df3fc`).

| mutant | removes | failed / 2418 | killed by | verdict |
|---|---|---|---|---|
| N0_null | nothing (a comment); binary = base | 0 | — | null |
| N1_no_argument_clause | the Argument clause of the call-slot rule (commit A's (B)) | 4 | `…_inner_arg`, `…_inner_arg_range`, `…_nested_arg`, `…_outer_nn` | KILLED |
| N2_no_scalar_type_test | the int/fp test in `isUnreadScalarSlot` | 0 | — | **MISSED → EQUIVALENT, argued below** |
| N3_no_strip | the `range`/`nofpclass` strip on an Argument-carried dead slot | 1 | `…_inner_arg_range` | KILLED |
| N4_fence_structural | the fence's value-liveness test (fires on ANY instruction in a not-null-safe unread slot) | 2 | `…_inner_inst_live`, `…_classical_inst` | KILLED |
| N5_no_handle_mask | the fence's handle-mask conjunct | 1 | `…_classical_inst` | KILLED |
| N6_no_fence | the fence | 2 | `spec_reject_…_inner_inst`, `spec_reject_…_inner_inst_musttail` | KILLED |
| E1_musttail_refused | commit B (the drop's `musttail` refusal restored) | 3 | `spec_accept_dropped_arg_musttail_{return,forward_chain,kept}` | KILLED |
| D1_no_demotion | commit C (the clone `musttail` demotion) | 1 | `spec_accept_musttail_in_clone_demoted` | KILLED — and its binary `de63c48fe1e80abc` is bit-identical to commit B's, an independent check that C is exactly the demotion |

**8 KILLED, 0 MISSED that matters, 1 EQUIVALENT (N2).** N2's argument: the type test excludes
POINTER slots from "unread scalar". Without it, a pointer ARGUMENT forwarded into a recorded-dead
pointer slot (e.g. `byval`, whose copy is a read AT THE CALL) would let the enclosing parameter be
recorded dead. Every consumer that ACTS on a record is gated by `nullSafeSlot` (the rewrite, M-C
(d0), M-A — never true for a pointer) or asks about a QUANTUM operand (`resolvePhantomCloneArgReads`
step 1/2 — a pointer operand is never tainted; `scanBody`/SpecializeReject decline pointer casts of
tainted values), and the fence asks only HANDLE parameters (never pointers). So no consumer can
observe the difference today; the conjunct keeps the predicate's NAME true. Retirement trigger: the
day any consumer writes, declines or exempts on the bare record for a pointer slot, a fixture for N2
becomes constructible and owed.

⚠ **THE FIRST RUN OF THIS MATRIX WAS CONTAMINATED, AND ITS OWN CLOSING CONTROL CAUGHT IT** (kept as
`results/mutants_run1_CONTAMINATED.txt`, L10). The restore step used `rsync -a`, which restores a
source with its OLD mtime, so `make` never recompiled a restored file: from N3 on every mutant
carried the previous mutants' objects (N3 = N2+N3, …, E1 = N2+N6+E1, D1 = N2+N6+E1+D1 — which is
why E1 and D1 appeared to "kill" the fence's two decline fixtures). The final "restored; rebuild
base" line printed D1's hash instead of the base's. Fix: a restore WRITES each file fresh and every
mutant is bracketed by a rebuild that must hash to the base (a BOUNDARY CONTROL before and after,
`assert_base`); the scratch tree was force-recompiled and re-verified bit-identical before the
re-run. Every verdict above is from the re-run (`results/mutants.txt`, `mutants_run2_log.txt`).
N0–N2 were valid in both runs (identical hashes); N3's clean binary is `bbdef19e…` against the
contaminated `50508770…`.

## 12. Allocator sweeps

`nlfd_probes/tools/alloc.py` over every `ir-pass/test/*.ll` (denominator **2418**): plain `cq-opt`
(`93c65d0da41df3fc`) vs `cq-opt-debugalloc` (`f69cc2cd974b4d1a`) under `CQ_OPT_DEBUG_ALLOC=lifo`
and `=nofree` — exit code, stdout sha-256 and first error line compared across the three:
**0 disagreements of 2418** (`results/alloc_S.txt`). Run once, on the final binary.

## 13. ATTACK FIRST (for the Rule-13 reviewers)

1. **(B)'s one claim: a value placed in an UNREAD SCALAR slot is unobservable except through a
   value constraint on the slot** (§2 step 3). Enumerate every LLVM-19 parameter attribute that the
   verifier admits on an integer or floating-point parameter and on a CALL-SITE argument, and find
   one that (a) constrains the value beyond `noundef`/`range`/`nofpclass`, or (b) makes the CALL
   itself read the value. My list: `allocalign` (vacuous — a clone never returns a pointer),
   `returned` (stripped from clones; a CALL-SITE `returned` I did not construct), `immarg`
   (intrinsics only), `alignstack`/`inreg`/`swiftself`/`swiftasync` (ABI placement). A string
   attribute a backend interprets would break it; I know of none on a parameter.
2. **The strip's reach.** The neutralised `0` reaches every unread scalar slot along a forwarding
   chain; each level strips its own call site and callee parameter in its own `buildClone`. Attack
   a CACHE HIT (the same `(callee, mask)` clone called from two enclosing clones, only one of which
   records its parameter dead), a slot whose `range` is on the CALL SITE only, and an `nofpclass`
   fp slot of an fp-ABI clone (the slot is `i32` after `cloneFor`'s rewrite — the type test reads the
   call's function type).
3. **The fence's condition** (Existence-live ∧ Value-dead ∧ handle). Existence and Value liveness
   differ only at a not-null-safe unread scalar slot with an INSTRUCTION operand — confirm by reading
   the call-slot rule; mutant N4 measures the value test, N5 the handle mask. Attack: an instruction
   whose value is ALSO consumed by an inner `ReturnTainted` clone call (a root — value-live), a
   handle parameter that reaches the slot through a `select`/`freeze`/cast chain, and an fp-ABI
   handle.
4. **The fence PREEMPTS.** It fires inside `specialize()` and `LLVMContext::diagnose` exits on the
   first `DS_Error` (bd br4a), so a module one of the post-specialize owners (d88e → 2qyz → l3oi →
   3d8q → s82e → tu9q → vsfp) would have declined now declines with the phantom-read string. The
   corpus A/B (§10) lists every STRING mover; I claim none is a verdict change.
5. **`x_outer_nn`: a module-level ACCEPT became a DECLINE** (L2 (c)). On the ORACLE it was bd tzfa's
   wrong unitary (warned), so the verdict move is toward safety; the twin accepts, so it is also an
   over-decline. Look for a C spelling (a not-null-safe int parameter from C) — none measured.
6. **ev3m writes into `musttail` slots.** Attack the verifier's `musttail` rules with an `inreg`
   parameter (ABI-matched caller↔call site; the drop never touches it), a `swifttailcc`/`tailcc`
   call, a `musttail` through a bitcast callee (excluded by the function-type filter), and the
   drop's own clean-up (`deleteDeadCones`' block merge and two-entry-φ fold) on the CALLER's side —
   can anything land between a `musttail` call and its `ret`?
7. **ev3m's population.** Every `musttail` spelling whose plain-`tail` spelling compiles into a
   pre-existing defect now compiles into it too (§5 measured bd rhk5). Look for bd s82e / bd qjoc /
   bd rhk5 siblings among `musttail` spellings, and for a DECLINE fixture whose subject the drop now
   removes (the CENSUS, §10).
8. **The demotion.** A `musttail` that is SEMANTIC inside a clone: a varargs `...` forward (needs a
   variadic caller — `scanBody` declines variadic callees, and a clone is never variadic), a
   `byval`/`inalloca` perfect forward (pointer, classical), a `musttail` to an intrinsic. The
   demotion also runs on every `_unc` twin (`stripStaleClassicalAttrs`).
9. **Lost subjects.** `spec_accept_phantom_arg_read_musttail_inner_slot.ll` was re-spelled (IR-only
   branch-only read) and the e2e pair `e2e-spec-dropped-arg-musttail-inner-twin-identical` now
   witnesses the DROP, not the in-clone slot. Check no other fixture silently lost its subject to
   ev3m (CENSUS) or to nlfd (the record moves only for modules with a not-null-safe dead slot).
10. **The two precision controls pin the ORACLE's CLONE streams, not `main`'s** (bd rhk5's divergent
    stream is deliberately unpinned — bd jlf8). Check that the CLONE lines still catch the property
    they claim (mutants N4/N5 kill them by declining, not by a stream change).

## 14. What I did NOT run or attack

- The full `ctest -j6` (owner ruling 2026-09-26 — it runs at the merge gate on `main`).
- `cq-opt-equivalence-full`; only the sampled `cq-opt-equivalence` entry, if listed in §10.
- No composition with the other tracks of this session; no composition with the parked 9bhg branch.
- No Guard Malloc, no `+Asserts` build.
- No per-attribute construction of every LLVM-19 int/fp parameter attribute (§13 item 1 is an
  argument from the attribute list, not a measurement), and no C spelling of a not-null-safe
  int/fp parameter on any target other than x86-64 (r6's "none found" is inherited, not re-derived).
- bd rhk5 itself (not this track's); the `lv` cells' divergence from the twin is rhk5's / the known
  clone copy-out's, measured PRE-EXISTING (ORACLE-identical for the plain-`tail` cells) and left.
- The IR-only module-level residuals the table shows (`m_*_cd`: a branch-only read the drop cannot
  see → 3jru; `m_*_nn_pd`: a not-null-safe module slot → 3jru) — pre-existing, IR-only, unchanged.

## 15. Open questions

- **Q1 (owner).** `nullSafeSlot`'s string/unknown-attribute refusal is a WRITE POLICY: LLVM's own
  DAE writes `poison` into a dead slot whatever its other attributes (stripping only the
  UB-implying ones), and (B) relies on exactly that premise for the RUNTIME value. Relaxing the
  policy to DAE's standard (keep the pointer/`byval` refusal — that one is soundness, bd 91k9) would
  retire the fence's over-decline, `resolvePhantomCloneArgReads` step 1's IR-only over-decline,
  `x_outer_nn`'s, and the `m_*_nn_pd` 3jru residual. Keep the policy?
- **Q2 (orchestrator/owner).** §5: land commit A alone, or A+B+C with bd rhk5's population growth
  recorded, or hold B and C for rhk5?
- **Q3.** The brief asked that "a `musttail` forward of a LIVE quantum arg must still behave as its
  twin": it now behaves as its plain-`tail` twin (byte-identical), which itself differs from the
  hand-inlined twin by bd rhk5 — so that requirement is met only up to rhk5.

## 16. Proposed CLAUDE.md text (the owner's to apply)

For §5 "Open follow-ons", replacing nothing (an addition; the owner edits CLAUDE.md):

> ⚠ **bd `nlfd` / bd `ev3m` (2026-09-28, branch `worktree-agent-a333a1777db2f2295`, pending
> Rule-13).** Liveness now has TWO named questions (`SlotReads`): *must this operand still EXIST?*
> and *is its VALUE observed?* An ARGUMENT forwarded into an UNREAD SCALAR slot (recorded dead,
> int/fp) is no read of the enclosing parameter — the w7nm mechanism is gone for every attribute,
> not only `musttail` — and a HANDLE parameter kept alive only by a surviving instruction in a
> not-null-safe unread slot DECLINES in `buildClone` (the module-level phantom-read rule, one clone
> level down; IR-only as measured). `nullSafeSlot` stays a WRITE policy. The dead-argument drop no
> longer refuses a `musttail` site, and a clone's `musttail` is demoted to a plain call (a
> PRE-EXISTING, C-reachable verifier abort). ⚠ Those two make a `musttail` spelling compile exactly
> like its plain-`tail` spelling — and therefore ADD `musttail` customers to the open P1 bd `rhk5`.

## 17. Beads

- **NEW: bd `test_C_libtooling-m5pn`** (P2, bug, PRE-EXISTING, C-reachable verifier ABORT) — a
  `musttail` call cloned into a Phase-6 clone (§4); fixed by commit C; linked discovered-from bd
  `nlfd`, related to bd `rhk5`.
- bd `nlfd`, bd `ev3m`: notes appended (`--append-notes`), NOT closed.
- NOT filed separately: the bd `rhk5` population growth (§5) — recorded on bd `rhk5`'s notes and in
  m5pn's description, because the defect is rhk5's and the decision is the orchestrator's (Q2).
- NOT filed: the mutation harness's own mtime defect (§11) — an instrument of this track, fixed in the
  same session before any verdict was taken from it.
