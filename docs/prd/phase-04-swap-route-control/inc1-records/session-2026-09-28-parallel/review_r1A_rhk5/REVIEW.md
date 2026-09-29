# REVIEW r1A — bd `test_C_libtooling-rhk5`, Surface A (the fence: what is now admitted as read-only, and whether the proof is sound)

Rule-13 reviewer **r1A**, session 2026-09-28 (parallel). Independent of the implementer.

| | |
|---|---|
| Subject | branch `worktree-agent-a7712272d6ca568e9`, commit `c89afa59`, diff `9a230646..c89afa59` |
| Subject `cq-opt` | `fa71e37a884ba4489e96a66a0181a4b583830f48c7efb6cfdfbf6d7ad8f5b408` (verified by `shasum -a 256` before first use) |
| Subject `libCQPass.so` | `c21a35eff3059cf6b8f64a3a…` (verified) |
| Oracle | `scratchpad/frozen/cq-opt.main_9a230646`, `3f6db37f5cf937b4d70f5736…` (verified) |
| Time | ~80 min; box load average 256 → 26 over the session (timings below say which) |
| Probes | `probes/` (sources, stage-1 IR, lowered IR + traces under `probes/out/`); `probes/build.sh NAME` (2-TU `-O1` + `llvm-link`, as `run_slice_multi.sh`), `probes/run.sh S\|M IN.ll ARG` (lower → STRICT 2b → link → run; a module without `main` is linked against `probes/main_slice.c`, which calls `slice(atoi(argv[1]))`) |

**What I ran, literally.** `run.sh` (subject and oracle) on every probe named below; `/usr/bin/time -p` on the depth probes; `lit -j2 ir-pass/test --filter 'clone_read|clone_consumes|sibling_clone_arg_measured'` on the subject (**10 passed, 2416 discovered** — my one spot-check of the implementer's sweep; it matches §5.5's fixture count). I READ the implementer's mutation-matrix results (`rhk5_probes/results/mutmatrix_*.txt`).
**What I did NOT run.** No full `lit`, no `ctest`, no corpus A/B, no private build and therefore **no mutants of my own** (the box was at load ~250 for most of the session; the implementer's 8 mutants + null are read, not re-run); `tools/trace_twin_equiv.py` was not used as a witness — every twin comparison below is by reading the two streams.

## Verdict: **NOT-CLEAR**

One **P1 (scope-qualified)**: the body walk that is the change's whole safety argument trusts its gate vocabulary **by callee NAME**, and a module that pre-supplies a `_unc` twin (the threat model the change itself pins four times) can route a write of the caller's register through a module-defined `cq_template_*` function. The subject then discharges the caller's chain **after** the write: two `cqrt_free`s of non-`|0⟩` rails, one of them entangled with `q` — a hidden measurement — with `opt` exit 0, **no warning**, STRICT 2b `0 violation(s)` **and census `0 left dirty`**. The oracle, on the same input, leaks with the lyyf-(B) warning and frees nothing dirty. Reachable from 2-TU C (with CQ-reserved identifiers). The fix is one conjunct. Two P2s: the same "walked body ≠ executed body" gap through INTERPOSABLE linkage, and an **exponential** proof walk (no memo) that turns a 29-line C library into an 18-second compile at depth 12 (≈20 min at the depth cap).

If the orchestrator rules hostile reserved-namespace modules out of scope, F-r1A-1 drops to P2 and the verdict to CLEAR-WITH-ITEMS — but the change's own header claim ("Nothing is read off the NAME") is false either way and must be corrected at the source (L7).

---

## The argument, restated — and the step that is asserted

The chain `p = q*3; u = p^q` is an M-B **interior** component with borrowed parent `q`. Its `_unc`s are only correct if `q` holds the same **basis label** at each adjoint as at the forward gate (clause (d)). A clone call `h(m, q)` sits in the window. Before the change both spine predicates failed closed on it (leak + warning). The change proves, per call, that the callee body never **writes** the formal bound to `q`: every use of the formal must be an argument of (B1) a forward producer, (B2) an out-first `_unc` in a handle slot ≥1, (B3/B3′) a copy source / controlled-copy source-or-control, or (B4) another recorded clone / twin call proved the same way. Label preservation is exactly what clause (d) and (b′) need — I agree with that part of the argument, and I could not break it for **specializer-built** bodies (below).

**The asserted steps.** (i) *"Nothing is read off the NAME … the answer is derived from the callee BODY"* (`ChainWalk.h`): false — (B1)–(B3′) classify each use by the **callee's name** and never ask whether that callee is the runtime's external symbol or a function the module defines (F-r1A-1). (ii) Premise 1, *"the walked body IS the body that runs"*: true of an `internal` clone, not of an interposable definition, which `ensureTwin` reuses verbatim (F-r1A-2). (iii) Termination is argued; cost is not (F-r1A-3).

---

## Findings

Beads filed by this review: **`test_C_libtooling-fb5y`** (P1, F-r1A-1 + F-r1A-2) and **`test_C_libtooling-tcpq`** (P2, F-r1A-3; notes F-r1A-5). A note was appended to `rhk5`.

### F-r1A-1 — **P1 (scope-qualified)**, INTRODUCED — the walk's vocabulary is name-keyed; a pre-supplied twin writes `q` through a module-defined `cq_template_*` function and the subject frees two dirty rails, silently

**Mechanism.** `formalLabelPreserved` admits a use if `isTemplateProducer(UC)` — i.e. the callee's NAME starts with `cq_template_` and is not `_unc`/`_inv`/`_controlled` — without asking whether that callee is a declaration (the runtime ABI) or a body in the module. Same for (B2) `isUncHandleSlot(N, …)` and (B3′) `N.starts_with("cqrt_copy_")…`. The module can DEFINE `cq_template_evil_i32(int x){ cqrt_x(x); }`; nothing in the pass declines a module definition in that namespace (`a1e_redefine_unc.ll`: the oracle even accepts a module that redefines an ABI adjoint the pass itself emits), and a pre-supplied `<clone>_unc` is never lowered or vetted by the specializer, so it may call it.

**Exhibits (all run on both binaries):**

* `probes/a1f_evil_after_uncompute.ll` (hand IR; the change's own `spec_leak_clone_read_twin_writes_arg.ll` with the write moved to a `cq_template_evil_i32` call placed AFTER the twin has correctly uncomputed `out`, so `h`'s own Bennett wrap is clean on the oracle).
* `probes/a1c_c.c` + `a1c_c.lib.c` — **the same program in 2-TU C**, runtime value via `argv`: the lib TU defines `g`, `h`, `__attribute__((noinline)) int cq_template_evil_i32(int x){cqrt_x(x);return 0;}` and `void __cq_q_g_1_unc(int out,int k){…correct uncompute…; (void)cq_template_evil_i32(k);}`.

```
cd …/review_r1A_rhk5/probes
./build.sh a1c_c
./run.sh M a1c_c.s1.ll 5     # ORACLE
./run.sh S a1c_c.s1.ll 5     # SUBJECT
```

| | `opt` | stderr | STRICT 2b | stream in the caller after the clone call |
|---|---|---|---|---|
| ORACLE | 0 | lyyf-(B) **warning** | `2 left dirty`, 5 frees, 0 violation | chain `h1=3q`, `h2=q^3q` left allocated (the ruled warned leak); no dirty free |
| SUBJECT | 0 | **empty** | **`0 left dirty`**, 7 frees, 0 violation | `… cqrt_x(h0) …` (inside the clone's twin) … `cq_template_xor_i32_unc(h2, h0, h1); cqrt_free(h2); cq_template_mul_i32_hl_unc(h1, h0, 3); cqrt_free(h1)` |

Trace-level reasoning (Rule 2): after `cqrt_x(h0)` the register holds `~q`. `xor_unc(h2,h0,h1)` leaves `h2 = (q^3q)^(~q^3q) = 0xFFFFFFFF` — non-zero; `mul_unc(h1,h0,3)` leaves `h1 = 3q ^ 3·(~q)`, which **varies with q** (`q=0 → 0xFFFFFFFD`, `q=1 → 0xFFFFFFF9`), so `cqrt_free(h1)` is a reset of a rail entangled with `q` — **a hidden measurement the user never wrote (Rules 5, 6)**. Neither instrument sees it: 2b models every clone call as writing no argument (bd `e5ha`), and its census now reads `0 left dirty` because the rails *were* freed.

**Why INTRODUCED.** The oracle's disposition on the identical input is the warned leak with no dirty free; the only change is `cloneCallPreservesArg` admitting the call.

**Why scope-qualified.** Reaching it needs two CQ-reserved names in one module (`__cq_q_*_unc`, ISO-reserved by its `__` prefix, and a `cq_template_*` definition). But (a) the change itself puts the pre-supplied-twin route IN scope — four `spec_leak_clone_read_twin_*` fixtures and the header's "walked, not trusted" — and this is a fifth spelling of exactly that route; (b) the codebase already fences same-named fakes where it matters (the bd `1fim` void/arity fence in (B3′), bd `xy9n`, §4f's "(P4): the question was never the name"). **L5**: a semantic question ("does this callee write the operand?") answered syntactically.

**Fix (one conjunct, I did not build it):** in `formalLabelPreserved`, admit (B1)/(B2)/(B3)/(B3′) only when the used callee `isDeclaration()` — a runtime-ABI call is always external to the module; a DEFINED callee must go through (B4) (recorded + walked) or refuse. Pin with `a1f_evil_after_uncompute.ll` as a LEAK fixture. **And correct the `ChainWalk.h` sentence at the source** (L7's twist: a record correction that is not applied to the source is not a correction).

### F-r1A-2 — **P2**, INTRODUCED — premise 1 ("the walked body is the body that runs") is false for an INTERPOSABLE definition

(C1) checks `!F->isDeclaration()`; it does not check `F->isInterposable()` / `hasExactDefinition()`. `ensureTwin` reuses a pre-supplied twin whatever its linkage. `probes/a5_weak_twin.ll`: the module's `@__cq_q_g_1_unc` is **`weak`** and read-only; `probes/a5_strong_twin.c`, compiled to a separate object and linked at stage 4, supplies the strong definition, which ends in `cqrt_x(k)`.

```
L=/usr/local/opt/llvm@19/bin; W=<worktree>
$L/clang -O0 -c a5_strong_twin.c -o out/a5_strong_twin.o
$W/build/ir-pass/cq-opt -passes=cq-lowering -S a5_weak_twin.ll -o out/a5.S.s2.ll
$L/clang out/a5.S.s2.ll out/a5_strong_twin.o out/main_slice.o $W/build/runtime/libcq_templates.a $W/build/runtime/libcq_runtime.a -o out/a5.S.exe && out/a5.S.exe 5
```

Subject: `opt` 0, no warning, 2b `0 left dirty`, and the run shows `cqrt_x(h0)` followed by `xor_unc(h2,h0,h1); cqrt_free(h2); mul_unc(h1,h0,3); cqrt_free(h1)` — the F-r1A-1 dirty frees. Oracle: warned leak, no dirty free in the caller. P2 not P1 because it needs a link-time object the pass never sees; it is the textbook IPO trap and a one-word fix (`F->isInterposable()` → refuse), so it should ride with F-r1A-1's fix.

### F-r1A-3 — **P2**, INTRODUCED — the proof walk is exponential in clone nesting (no memo); a 29-line C library compiles in 18 s at depth 12, extrapolating to ~20 min at the depth cap

`formalLabelPreserved` recurses through (B4) with only a PATH stack (`Active`) — no memo of already-proved `(Function, slot)` pairs. Every Bennett-wrapped body uses a formal in the inner clone's compute call AND in its twin call, so each nesting level at least doubles the work, and a width-2 call DAG quadruples it. `probes/a3_d<D>.lib.c`: `a_i(k)=a_{i+1}(k)^b_{i+1}(k)`, `b_i(k)=a_{i+1}(k)+b_{i+1}(k)`, all `noinline` — program size and clone count **linear** in D; d4's `main`.

| D | ORACLE user s | SUBJECT user s (load ~26) |
|---|---|---|
| 8 | 0.19 | 0.26 |
| 10 | 0.20 | 1.27 |
| 12 | 0.23 | **17.85** |

(×~14 per two levels ≈ 4²; at load ~250 the D=12 wall time was 50.95 s.) The cap `kMaxCloneNesting = 16` bounds it at roughly 4¹⁵ paths per query — ≈20 min extrapolated at width 2, effectively a hang at width 3 (6¹⁵). The verdict itself is correct (the chain is discharged). **Fix:** memoize the per-`(Function, slot)` verdict (bodies are final at ask time, so a module-scoped cache is sound; a proved-false entry is sound too). Repro: `./build.sh a3_d12 && /usr/bin/time -p <subject cq-opt> -passes=cq-lowering -S a3_d12.s1.ll -o /dev/null`.

### F-r1A-4 — P3 — M7 / M8 are not "unreachable"; they are separable, in the accept direction only

The TRACK says no input distinguishes M7 (handle-slot mask) or M8 (record membership). A pre-supplied twin separates both: `probes/m8_twin_unrecorded_helper.ll` has the twin read `k` through a DEFINED, UNRECORDED, read-only `@helper_read` — the subject refuses at (C1)'s lookup (leak + warning, measured); M8 would walk the helper and admit (argued from the code, not built). I argue an M7 separation the same way (a twin passing `k` into a recorded clone's classical, dead slot). **Both separate only toward a CORRECT accept.** Once the body is walked, neither conjunct is load-bearing for soundness; they are scope limiters. The record should say so rather than "equivalent / no reachable input".

### F-r1A-5 — P3 — unpinned conjuncts, and two that are mutually redundant

No fixture reaches the cycle refusal (`is_contained(Active, Key)`), the depth cap, `isVarArg`, the operand-bundle loop, or (B3′)'s void/arity fence. `C->getCalledOperand() == V` is dead in typed IR (an `i32` handle cannot be a callee) and so is `K >= F->arg_size()` once varargs are refused. **The cycle check and the depth cap are mutually redundant for termination** (`probes/cyc_self_twin.ll`, a twin that calls itself with `k`: refused, measured; with the cycle check deleted the depth cap still refuses) — so neither is individually pinned, the bd `e1gr` shape. Suggest `cyc_self_twin.ll` as a LEAK fixture, plus a depth-17 chain.

### F-r1A-6 — P3 — Rule 14: (B3′) is a third spelling of "a controlled copy writes its LAST operand"

(B3′) re-derives `starts_with("cqrt_copy_") && ends_with("_controlled") && void && arity 3 && Slot != 2` inline, beside `Specialization::isCopyDestination` (last argument of any `cqrt_copy_*`) and `RotationLowering`'s `isCopyGate`. They agree today. Call one owner.

### F-r1A-7 — P3 — L7: the L3 paragraph's parenthetical is wider than the fact

`ChainWalk.h` says the moved-anchor scan's premise holds for synthesized bodies because "the Bennett wrap reads a formal only through the (B1)–(B4) shapes". The TRACK's own §8 `mg6f` note says the `_Bool`-condition clone select may **bracket the formal with `cqrt_x`**, which this walk refuses. What holds for such a body is label preservation **at the call boundary** (a bracket pair). The conclusion stands; the stated reason is over-general. Fix the sentence at the source.

---

## Standing-lesson questions

* **L1.** `cloneCallPreservesArg` records nothing and reads the clone body plus `SpecHandleArgMask` at ask time. Callers (enumerated with `grep`): `preservesBorrowedParent` (inside `uncompute`), `isInteriorConsumer` ← `isInteriorTerminalHandle` / `recoverDataDag`'s interior closure (inside `uncompute`), and `planInteriorDischarges` ← `lowerLateReassignments`, called in **both** entry points (`CQLoweringPass.cpp:1123`, `:1707`). All run after `specialize()` and after both control rounds. `uncompute` and the late round skip clone bodies (`AnyTaintedProducer` / `Sites` key on MODULE taint; `cloneTaint` is never unioned in), and `resolvePhantomCloneArgReads` skips recorded functions. **No round-2 premise found.** The residual premise failure is not temporal but linkage-based (F-r1A-2). In `runOnFunction`, if `specialize()` does not run the record is empty and the predicate fails closed — consistent.
* **L2.** Widened: `isInteriorConsumer` → (I3)/(I4), the interior `recoverDataDag` closure and the M-C plan move together (one predicate). Not widened, consistently: `isTerminalHandle`. Probed with `b2_twoclones` (one rail read by two clones and a template; subject stream = twin's, modulo the clones' Bennett vocabulary) and `b5_mc_inwindow` (an M-C candidate in the window; the subject matches the twin, including the out-of-place `q-5`).
* **L3.** `isInPlaceGateOn(clone)` is false everywhere, and the moved-anchor scan trusts every clone call. I tried to exhibit the implementer's argued jj3o gap (`c1_deadterm_hostile.ll` declines "dead chain would free a measured register"; `c2_deadterm_hostile_nomq.ll` streams are IDENTICAL on both binaries, and `3q` is discharged before the clone call). **Not exhibited.** The asymmetry is sound for the bodies the specializer synthesizes and stays argued-open for pre-supplied twins, as filed.
* **L4.** The walk is "every use must be admitted", and it breaks on the first refusal — a conjunction, so an early break is sound. It is not a return-first search for a write.
* **L5.** **Violated twice:** "does this callee write the operand?" is answered by name (F-r1A-1), and "is this the body that runs?" by `isDeclaration()` (F-r1A-2).
* **L7.** `ChainWalk.h`'s "Nothing is read off the NAME" (F-r1A-1) and the L3 parenthetical (F-r1A-7).
* **Rule 14.** F-r1A-6.
* **Rule 12.** Five accepts, each paired with LEAK fixtures whose subjects exist; the negatives are pure (the `LEAK-NOT`s are windowed between two positives, and `WARN` has its own prefix). Missing: a leak fixture for the name route (F-r1A-1), the linkage route (F-r1A-2) and the cycle (F-r1A-5). Spot-check: the 9 new fixtures plus the 1 modified one, **10/10 pass** on the subject.

## Composition (cepm+3zr4, nlfd+ev3m, z0re — none landed)

**`probes/comp_deadslot.c`** `s = h(q, p)` with `h(a,k){return k+1;}`: `q` sits in a **dead** slot and `p = 3q` in the live one. On the subject the vsfp neutraliser rewrites the dead slot to `i32 0` (`%7 = call @__cq_q_h_10(i32 0, i32 %h_op)`). (b′) then admits the call as `p`'s consumer, and the stream equals the twin's (`s = p + 1`): chain discharged, 0 dirty, no warning. The oracle warns with 2 dirty.
**Argument for nlfd/ev3m.** The walk does not consult any liveness record. If nlfd stops neutralising a dead slot, the formal is still unused and "preserved" by an empty use list, which is correct. If the dead-arg drop changes a clone's signature without re-keying `SpecHandleArgMask`, a misaligned mask bit can only (a) refuse (leak) or (b) send the walk to a formal whose uses decide — never admit a write. A `musttail` call in a clone body is still a `CallInst` argument use, so it goes through (B4) or refuses. **cepm:** a clone call with a CLASSICAL result still counts as a (b′) consumer and an (I4) forward consumer. That is right, because it read `R` and the result does not need to be a rail. **z0re:** I found no interaction. **Unverifiable here:** the actual nlfd/ev3m clone-body shapes. Re-run `comp_deadslot` and the `d1` family on the composed binary.

## What I attacked and did not break

* Specializer-built bodies reaching the caller's register **other than** through a formal. In C, the specializer declines a callee with memory access (`a4_mem`) or a quantum primitive (`a4b_rot`) before any clone exists — premise 2 holds for C.
* Writing slots classified as reads: `_unc` slot 0, copy destination, `cqrt_copy(k,k)`, and the formal bound in two slots (`h(q,q)` → both formals walked). All refuse, by reading the code; the implementer's M2/M5/M6 kills agree.
* The clone consumer **after** an Ry on `q` (`b1_after_ry`): IDENTICAL streams on both binaries, not introduced.
* A clone consumer in a classically-conditional block (`b3_condcall`): the subject equals the twin, both 1 dirty and warned.
* A clone reading `q` in a runtime-trip loop (`b4_loopcall`): the subject discharges after the loop, which analysis shows is correct. The twin DECLINES on both binaries (`operand predates a non-diagonal gate`, a pre-existing twin over-decline), so there is no twin stream to compare.
* An in-window M-C site (`b5_mc_inwindow`): equals the twin.
* A self-cycle (`cyc_self_twin`): terminates and refuses.
* Width-1 nesting to depth 12 (`a2_d{3,6,9,12}`): ≤0.52 s on both binaries (2^D walk), accepted and discharged.
