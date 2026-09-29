# Rule-13 review r2 — bd `test_C_libtooling-nlfd` + `ev3m` + `m5pn` (+ `vaep`), round 2

- **Subject**: worktree `agent-a333a1777db2f2295`, fix diff `76c0d965..a8d86576` (records `cb4c6861`).
  `build/ir-pass/cq-opt` sha-256 `73cfb84713d6b7ba35451cf0` (re-measured; equal to the implementer's
  `nlfd/bin/cq-opt.R2`).
- **Oracles**: `main` ba4fdad4 = `frozen/cq-opt.main_ba4fdad4` (`ac02fafabb9e62b1`); `main` 9a230646 =
  `frozen/cq-opt.main_9a230646` (`3f6db37f5cf937b4`); merged pre-fix `M` = `nlfd/bin/cq-opt.M`.
- **Time**: ~45 min. Load: single-process runs only (no `-j`).
- **Ran, literally**: the source diff read line by line; LLVM-19 `opt -passes=verify` on three hand-written
  demoted-forward modules; the four round-2 accept fixtures' RUN pipelines by hand (`cq-opt` + `FileCheck`,
  every prefix) on SUBJECT and `M`; 24 hand-written IR probes and 2 C probes on SUBJECT / OB / O9 (listed
  below); the three new e2e slices by hand (clang -O1 → llvm-link → cq-opt → stage 2b → link → run → diff
  golden) on SUBJECT / OB / O9, and again with `main` d21a59b0's `CQ.h` (fmt3); `tools/trace_twin_equiv.py`
  on the three golden pairs; `git merge-tree` of the subject against `main` d21a59b0.
- **Did NOT run**: lit, ctest, corpus A/B, the mutation matrix (read the implementer's counts; spot-checked
  the vaep kill direction by running the fixtures on `M`); no private build, no mutants of my own; no
  composed binary with bd `cepm`/`3zr4`/`fmt3`.

## Verdict: **CLEAR-WITH-ITEMS** — 0 P1 introduced, 0 P2 introduced, 3 P3; plus one PRE-EXISTING P1 filed (bd `test_C_libtooling-9oob`)

Round 2's four changes are correct and add nothing wrong that I could find. The one serious finding is
PRE-EXISTING (byte-identical on all three oracles), out of this round's scope, and was reached while testing
the vaep timing claim; it does not block this landing.

## The round-2 argument, restated, and where it was asserted rather than measured

1. **vaep.** A neutralised `0`/`0.0` may reach only a slot the record calls dead (every rewrite — module-level
   `resolvePhantomCloneArgReads`, `deleteDeadCones` step 3, `buildClone`'s forward loop, the pre-specialize drop
   — is gated on `isRecordedDeadSlot` / its own dead mask). `SpecDeadArgMask[Clone]` is written once
   (`Specialization.cpp:1019`), and the strip runs right there; `synthUncomputeTwin` is reached only via
   `ensureTwin`, whose only caller (`:976`) runs after `resolveSite` returned the clone's record; twins are made
   by `CloneFunctionInto`, which copies parameter attributes, so every SYNTHESIZED twin inherits the stripped set;
   the twin CALL is a fresh `CreateCall` with no call-site attributes (`EmitInverse.cpp:395-411`). ✔ All verified
   by reading. **Asserted, not true in general:** "no twin of a clone exists before its record" — false for a
   PRE-SUPPLIED `<clone>_unc` definition (F-r2-3; the real hazard there is F-r2-4, pre-existing).
   - **Is the strip verdict-neutral?** Yes, and this is the step the record does not argue: the strip runs
     BEFORE the enclosing clone's liveness (and before the fence's Value liveness), and `nullSafeSlot` reads the
     callee's parameter attributes — but `Range`/`NoFPClass` are IN `dropEligibleParamAttrs`' allowlist
     (`SpecializeDetect.cpp:118-119`), so removing them cannot flip a null-safety or liveness verdict.
   - **Only dead slots?** Yes: the loop is masked by `DeadSlots`. A cached clone shared by several callers: the
     dead bit is a property of the clone, not the caller; a caller whose operand is kept (classical, or not
     null-safe) passes a real value into an unconstrained parameter nothing reads — a sound weakening that
     emits no gate. Measured: nested 3-level probes, the SUBJECT's lowered module equals its no-`range` spelling
     byte-for-byte after textual attribute removal (`n3_{ns,nn,ns_top}` vs `_plain`), and every `__cq_q_*`
     definition (forward and `_unc`) is `range`-free, where OB leaves `range` on both twins (`n3_ns`) or on every
     clone and twin (`n3_nn`).
   - **Do the fixtures look at the twin?** Yes. Each of the three files has a `TWIN-LABEL:` line spelling the
     `_unc` signature WITHOUT the constraint; attribute print order is `noundef` → int attrs → `range` → string
     attrs, so a surviving `range(…)`/`nofpclass(…)` breaks the substring. Measured: on `M` the `CHECK` prefix
     (stream) is GREEN and the `TWIN` prefix RED for all three; on SUBJECT both GREEN.
2. **preallocated.** LLVM 19's verifier, measured (`probes/v_*.ll`): a forwarded `preallocated` operand on a
   plain call is invalid (`preallocated operand either requires a preallocated bundle or the call to be musttail
   (but not both)`); a forwarded `inalloca` and a forwarded `swifterror` parameter on a plain call are VALID. So
   declining exactly `musttail ∧ preallocated` and demoting `inalloca`/`swifterror` is right. The check sits in
   `scanBody` after only rotation/measure/curated-intrinsic/`returns_twice` exits, none of which can carry a
   `preallocated` pointer, and `scanBody` recurses into nested bodies — measured on a two-level forward
   (`pb3_two_level_forward.ll`: SUBJECT declines at `h`; OB/O9 abort 134). The decline is source-located via
   `Where->getDebugLoc()` (`SpecializeReject.cpp:1039`), measured `pa.c:4:17` (`pa_dbg.ll`); the fixture mirrors
   the string character-for-character. A clone whose OWN caller passes `preallocated` (no forward):
   `pb1_own_caller_prealloc.ll` SUBJECT ≡ OB byte-identical (unaffected). The `isMustTailCall()` conjunct is
   argued equivalent: a non-`musttail` `preallocated` call in a lifted body needs a bundle token from
   `llvm.call.preallocated.setup`, a non-curated intrinsic declaration the body scan already declines.
3. **F-r1A-4 (location only).** `DeadSlots = deadParamMask(*Clone, FunctionLiveness(Existence))` and the fence's
   `deadParamMask(*Clone, FunctionLiveness(Value)) & HandleLive` are the pre-refactor expressions verbatim (the
   three-argument overload now delegates). The two modes differ ONLY at an unread-scalar call slot with an
   INSTRUCTION operand (`DeadValueLiveness.cpp:230-235`), so whenever the verdict fires some call carries an
   operand in `Existence ∖ Value` — `Where` can only be empty if that call has no `!dbg`. Measured:
   `loc1_fence_dbg.ll` → `fence.c:6:22` (the `h2` call, not the `mul`), identical on `M`; an earlier classical call
   with its own `!dbg` (`loc2`) is not chosen.
4. **e2e.** Nine literal `add_test` lines; the three slices run strict 2b (no 11th arg); the twins are
   single-TU hand-inlined spellings with no clone and no `musttail` — independent. By hand: SUBJECT GOLDEN-IDENT,
   2b `6/6/4 verified, 0 violation(s), 0 unproven`, 0 dirty; OB/O9 abort 134 (`clone_*`) or decline
   (`rhk5_window`, `cq taint escape`); `trace_twin_equiv.py` EQUIV ×3 (44/44 controls). Also GOLDEN-IDENT when
   stage 1 uses `main` d21a59b0's `CQ.h` (bd fmt3's `nomerge`).
5. **ur72 context.** Only two fixtures that exist on `main` ba4fdad4 were modified
   (`spec_accept_dropped_arg_musttail_kept.ll`, `spec_accept_phantom_arg_read_musttail_inner_slot.ll`): 0 → 0
   `RUN: not` lines each. The three decline fixtures carrying the fence/step-1 string are NEW on the branch.
   The 11 OB→SUBJECT A→D rows in `results/r2/ab_OB_S.txt` are those two new fixtures plus cells and r1A probes;
   every one carries `"cq.probe.opaque"` on an int parameter and none has a `.c` source (the `.s1.ll` tags are
   copies of `.ll` files). IR-only, as claimed. One attack on ur72's "main compiles the population correctly"
   (a 4.4 select merge as the phantom operand, `u1_sel_phantom.ll`) is blocked earlier by the 2c
   condition-wire fence on all three binaries; I did not attack the write / nested / loop members (R2.6 #3).

## Findings

### F-r2-1 — P3 — INTRODUCED on the branch (round 1), unchanged by round 2: the two new decline LOCATIONS are unpinned
`spec_reject_phantom_arg_read_unread_scalar_{inner_inst,outer_nn,inner_inst_musttail}.ll` and
`spec_reject_musttail_forward_preallocated.ll` carry no `!dbg`; their `CHECK: error: {{.*}}in function …` accepts
`<unknown>:0:0`. A mutant that never sets `Where` (or passes an empty `DebugLoc` in the scanBody decline) leaves
lit green. F-r1A-4's "location from the same computation" is therefore witnessed only by my probes. Suggested
pin: `probes/loc1_fence_dbg.ll` (`CHECK: error: fence.c:6:22: in function __cq_q_h_01`) and `probes/pa_dbg.ll`
(`CHECK: error: pa.c:4:17: in function h`), both measured on SUBJECT.
Repro: `build/ir-pass/cq-opt -passes=cq-lowering -S probes/loc1_fence_dbg.ll -o /dev/null`.

### F-r2-2 — P3 — PRE-EXISTING (on ba4fdad4), Rule 14: "the constraints a null can violate" is spelled three times
`{Range, NoFPClass}` appears in `stripParamValueConstraints`, again in `stripUnreadSlotValueConstraints`' call-site
half, and in `dropDeadCallArguments`' own inline loop (`SpecializeDetect.cpp:214-217`), which round 2 did not
route through the new helper. All three agree today (safe direction). The day `dropEligibleParamAttrs` admits
another value constraint (bd `uyhx` is exactly that question), three sites must move together.

### F-r2-3 — P3 — INTRODUCED by round 2 (comment, L7 shape): "no twin of a clone exists before its record" is not total
The new comments at `Specialization.cpp:1020-1027` and `DeadValueLiveness.h` ("every later `_unc` twin inherits",
"no twin of a clone exists before its record") are true of SYNTHESIZED twins only: `ensureTwin` short-circuits on
a pre-supplied `<clone>_unc` DEFINITION, which keeps whatever attributes the input gave it. Measured
(`probes/pt_pretwin.ll`): the pre-supplied twin keeps `noundef range(i32 1, 100)` and receives `i32 0`, on SUBJECT
and OB alike. The attribute is the least of it — see F-r2-4 — so the fix is a qualifier in the comment
("…synthesized twin…; a pre-supplied twin is bd 9oob"), not code.

### F-r2-4 — P1-class, **PRE-EXISTING**, out of this round's scope — filed bd `test_C_libtooling-9oob`
A pre-supplied `__cq_q_<callee>_<mask>_unc` with a WRONG but undef-free body is used VERBATIM as the inner
clone's adjoint. The outer wrap then frees a rail still holding `f(args)`, entangled with the caller's registers
(a hidden measurement), and stage 2b reports it clean because it trusts `_unc` by name. **C-reachable**: two
plain-C TUs, the classical lib defines the compiler-reserved identifier
`void __cq_q_h2_11_unc(int o,int x,int k){}` (`probes/ptc/ptc.c`, `ptc.lib.c`). SUBJECT: exit 0, empty stderr,
2b STRICT `3 verified, 0 violation(s), 0 unproven`, and the trace goes `copy(h2,h3) … cqrt_free(h3)` with no
un-copy of `h3 = q+kq`, then `cqrt_ry(h0, 0.7)`. The control without the definition (`ptcT.*`) emits the
synthesized un-copy `add(h1,h0)->h6; copy(h6,h3); add_unc; free(h6)` before `free(h3)`. The lowered module is
byte-identical on `main` 9a230646, `main` ba4fdad4, `main`+cepm and SUBJECT, so it is **PRE-EXISTING**.
It is the inner-path sibling of bd `jj3o` (2), whose text calls the inner path "fenced" (that fence,
`findUndefOperandInBody`, checks undef only), and the same threat model as bd `fb5y` (P1, closed).
Repro:
```
cd probes/ptc
clang -I<W>/include -include CQ.h -O1 -emit-llvm -S ptc.c -o ptc.cq.ll
clang -O1 -emit-llvm -S ptc.lib.c -o ptc.lib.ll
llvm-link -S ptc.cq.ll ptc.lib.ll -o ptc.s1.ll
<W>/build/ir-pass/cq-opt -passes=cq-lowering -S ptc.s1.ll -o ptc.S.s2.ll   # exit 0
python3 <W>/tools/free_pairing_check.py ptc.S.s2.ll                        # 0 violation(s)
clang ptc.S.s2.ll <W>/build/runtime/libcq_templates.a <W>/build/runtime/libcq_runtime.a -o a && ./a 5
```

## Standing-lesson questions

- **L1**: round 2 adds no taint-dependent computation in the two-round window. The strip is attribute-only and
  lives inside `specialize()`. The preallocated decline reads body structure. The location change touches
  diagnostics only. Nothing to re-ask.
- **L2/L3**: the strip set widened from "call sites a null reaches" to "every recorded-dead parameter at the
  record". The other set over the same slots is `nullSafeSlot`'s allowlist, and it contains both stripped kinds,
  so the asymmetry is sound (verdict-neutral, above). The narrowed predicate (a decline that first also covered
  `inalloca`) was re-derived against the verifier by measurement.
- **L4**: no wire walker is touched.
- **L5**: the preallocated decline is keyed on the ATTRIBUTE the verifier keys on (`paramHasAttr(Preallocated)`),
  not on a name.
- **L7**: F-r2-3. The new comments on ur72 are qualified with "for every member MEASURED" in the source. The
  fixture headers state the over-decline without that qualifier. The attack I ran did not falsify them.
- **Rule 14**: F-r2-2 (pre-existing). The location loop is no longer a second spelling of the fence condition.
- **Rule 12**: the preallocated decline is paired with the `inalloca` accept (V5/V6 per the record). The
  decline's subject (the demotion) exists. Negatives are pure. Locations are unpinned (F-r2-1).

## Composition

The branch is merged with `main` ba4fdad4 only. Against current `main` d21a59b0 (bd cepm/3zr4 + bd fmt3),
`git merge-tree` reports conflicts in `CODE_MAP.md` and `ir-pass/src/Specialization.cpp`. The latter is textual:
both sides placed `kMsgPhantomArgRead` near `kMsgPredictedClassicalQuantum`. cepm's `predictReturnTainted` is a
forward taint closure over the ORIGINAL callee body and reads neither the dead-slot record nor parameter
attributes, so I found no semantic coupling by reading. Measured: the three new slices stay GOLDEN-IDENT with
fmt3's `CQ.h`. Owed at the landing: resolve the conflict, then run the four round-2 fixtures and the nine new
e2e entries on the composed binary. The merge-gate full suite covers the rest.

## What I tested and did not break

vaep on nested (3-level), cached (top-level + inner), null-safe and non-null-safe spellings; the strip's effect
on liveness/null-safety; the TWIN prefixes' sensitivity (red on `M`); the verifier rules for
preallocated / inalloca / swifterror after demotion; preallocated two levels deep, and via the clone's own
caller; source location of both declines; the fence verdict equivalence and its location with competing calls;
the three new slices end-to-end on three binaries and under fmt3's `CQ.h`; the twin-equivalence of their goldens;
that no pre-existing `main` fixture flipped to a decline; that the A→D movers are IR-only.

Probes: `probes/` (`v_*.ll`, `pa_dbg.ll`, `pb{1,2,3}_*.ll`, `n3_*.ll`, `loc{1,2,3}_*.ll`, `u1_sel_phantom{,T}.ll`,
`pt_pretwin.ll`, `ptc/`, `e2e/`), with the `.S/.OB/.O9` outputs beside them.
