# Track vsfp — a callee parameter with no uses is not an argument (bd vsfp + bd hgwx)

Session 2026-09-26. bd `test_C_libtooling-vsfp` (P1 SILENT DEPHASING, pre-existing, population
grown by bd 9bhg) and its warned sibling bd `test_C_libtooling-hgwx`. Found by the bd 9bhg Rule-13
round r2A (`review_r2A_9bhg/REVIEW.md` F-9C-1) and, for hgwx, bd d88e's r1B (F-DB-1).

- Worktree branch: `worktree-agent-abf65d7dcfbff38c8`, based on `main` `aee8f4f8`.
- **NOT self-cleared.** This is a Rule-13 change (TaintPropagation-adjacent orchestration, M-C's
  G7, a new post-`specialize()` decline). §10 is the attack list for the rounds.
- ⚠ **Both Rule-13 rounds on round 1 were NOT-CLEAR; ROUND 2 is at the end of this file (§R2).**
  §1–§12 are round 1's record, with each falsified sentence marked inline.
- ⚠ **Both Rule-13 rounds on round 2 were NOT-CLEAR too; ROUND 3 follows §R2 (§R3)** — bd otam, tzfa,
  stl3. The current description of the mechanism is §R3 on top of §R2.

Binaries (sha-256 prefixes):

| tag | what | `cq-opt` |
|---|---|---|
| ORACLE | `main` `aee8f4f8`, frozen (`frozen/cq-opt.main_aee8`) | `69250feaf68bbe49` |
| SUBJECT (ROUND 1, `5e56060b` — superseded: §R2) | this branch, round 1 | `73fd07592c4960dd` (`libCQPass.so` `11e9c571a4314fcf`, `cq-opt-debugalloc` `c8b735ca1c9e3e52`) |
| COMPOSED | this branch merged with bd 9bhg `f2148d0a` (scratch, removed) | `e29f68ce5298dedc` |

Build null control: a fresh build of the unmodified worktree hashed BIT-IDENTICAL to the frozen
ORACLE before any edit, and the mutation worktree's comment-only null mutant M0 rebuilt to the
SUBJECT's exact hash.

Probes, fixture sources, scripts and results are under `vsfp_probes/` (`src/{own,fx,ll}`, `tools/`,
`results/`). The scripts carry this session's scratchpad paths and say so; `tools/h.py` is the
harness (2-TU = the `run_slice_multi.sh` recipe).

## 1. Headline

- ⚠ **ROUND-1 CLAIM, FALSE AS STATED (Rule-13 r1A F-VA-7 #4; corrected in §R2).** "The phantom read is gone at its cause." A new normaliser, `dropDeadCallArguments`
  (`SpecializeDetect.{h,cpp}`), runs FIRST in both entry points (right after the passthrough
  early-out): every integer/fp argument of a direct call to an exact, non-vararg definition whose
  parameter has NO USES becomes `Constant::getNullValue`, and the operand's now-dead cone is
  deleted (non-call instructions only), to a fixpoint. That is what `clang -O1` does to the
  hand-inlined twin — and what `-O1`'s own dead-argument elimination already does within one TU;
  CQ is the first stage that sees both TUs.
- **Every F-9C-1 member is now twin-identical or declines with the twin's verdict**, on this
  branch AND composed with bd 9bhg (§7). hgwx's measured members (`j02C`, `e02C`, `j01C`) are
  TRACE-IDENTICAL to their twins with 0 warnings and a 0-dirty census.
- ⚠ **ROUND-1 CLAIM, FALSE (r1A F-VA-2, r1B F-VB-1; §R2): "TOTAL".** The backstop, `declinePhantomCloneArgReads` (`Specialization.{h,cpp}`), OBSERVES the built
  clones after `specialize()`: a module-level call that passes a tainted operand to a parameter the
  built clone never reads declines loudly (`cq specialization: quantum argument to a parameter the
  lifted callee never reads`), unless the operand is a `cq_theta` result (the user's own register;
  exempt, §4). It is C-reachable: a callee whose read of the parameter the CLONE pipeline removes
  (`volatile int z = a;`, erased by the fenv-ruled store elimination) is a phantom read the
  predictor cannot see. ⚠ **FALSE ATTRIBUTION (r1B F-VB-3):** the MODULE pre-pass
  `eraseDeadVolatileScalarStores` erased that store on the ORIGINAL callee before
  `detectSpecializations` — predictable pre-emission; round 2's slot B predicts it.
- **hgwx's residual needed one more line: M-C `priorUseIsSettled` arm (d0)** (`ArithLowering.cpp`):
  a call that passes `P` only in slots whose callee parameter has no uses does not read `P`, and
  neither can its `_unc` twin. It moved 0 of 5421 modules and fixes the C-reachable
  volatile-callee spelling of hgwx (§5). ⚠ **ONE spelling (r1B F-VB-1 `v30`):** `volatile char` kept
  a dead `trunc` the clone Bennett-reversed, so the parameter "had a use" and (d0) was blind.
- **Two new beads**: bd `qjoc` (P1, pre-existing, no clone — a dead 4.4 select left behind by the
  volatile-store erasure still mints an entangled `%out`; it is the TWIN of the backstop's C
  customer and falsifies CLAUDE.md's fenv "both are sound" sentence) and bd `jr8q` (P3 over-warn:
  M-A's `isCloneCallHop` calls every `__cq_q_*` result a record by name).
- **Consequences to read, not to average**: the drop removes the SUBJECT of every Phase-6 fixture
  written with a callee that ignores its argument — 33 lit modules touched (§3). 25 decline and 4
  accept fixtures were RE-SPELLED with a dead read so their fences stay pinned; 14 of them had kept
  their verdict AND their decline string while their subject changed owner — invisible to every A/B,
  found only by an env-gated census of the drop (`CQ_DEADARG_DBG`). And the drop changes
  verdicts the owner has open questions on: bd z0re's dead-parameter side door now declines like
  the twin, and bd cepm's over-decline and bd 9bhg's provisional-return customers disappear for a
  callee that ignores its argument (§8).

## 2. Mechanism and the timing argument

**The defect.** A Phase-6 site `h(p, m)` whose callee ignores `p` was specialized into a clone that
never reads its slot 0, yet the CALL still read `p` (hgwx's root cause). When `p` is a DERIVED
which-path rail of a register `x` — a 4.4 bool-select `%out`, a 6.5 `%out`, a template rail — that
phantom read is its only reader, so it is kept allocated and entangled with `x`; a later
non-diagonal gate on `x` then dephases. Template rails warned (lyyf-(B)); value-merge rails were
silent (exit 0, 0 warnings, 2b STRICT clean). The twin (`int t = m + 1;`) never computes `p`.

**Why "after `specialize()`" cannot be the fix.** `specialize()` learns the clone's verdict after
round-1 control emission, and the round-2 re-detection (bd 9paa) makes a `g(%out)` site out of a
6.5/4.5 rail that exists only because round 1 emitted it. Dropping the argument there leaves the
rail minted, orphaned and entangled — the same dephasing. So the fact must be known BEFORE any stage
reads the argument, and it can be: "the callee parameter has no uses" is a structural property of
the body the clone is built from, independent of taint.

**Why taint-agnostic, and why FIRST.**
- Taint-keyed, the drop would miss r2A `s3d`: `r` (a 6.5 merge φ of classical values) is classical
  at every slot before emission; `h(r, m)` becomes a Phase-6 site only in round 2.
- First (after the passthrough early-out, before the by-ref inliner): the pre-passes (rail bank,
  volatile folds, fp80, PredMux, unroll, ctlz) then see the TWIN's IR [⚠ FALSE in three measured ways,
  r1A F-VA-2/3/4 — dead intrinsics, dead φ cycles, emptied arms; §R2 states what IS the twin's], so their verdicts are the
  twin's. The drop needs taint only for the intrinsic-site membership skip; it SHRINKS taint and
  grows nothing, and the full re-`propagate` after it is exactly the restart every fixpoint below
  performs (the call result's taint came from the dropped operand), so it owes no
  `adjudicateTaintDelta`.
- Is "no uses" monotone across the window? No pre-pass adds a use of an unused parameter (they
  clone, fold and delete); callee bodies are untainted at module level, so the taint-driven
  pre-passes do not touch them. A use the CLONE pipeline later removes is the backstop's (§4). [⚠ The
  C customer named for this was the MODULE fenv pre-pass, not the clone pipeline — r1B F-VB-3.]

**What the drop will not do** (each is a conjunct; §9 says which are pinned):
pointer/vector/aggregate arguments; constant operands (load-bearing for TERMINATION, §9); callees
that may be interposed (`!hasExactDefinition()` — LLVM DAE's own precondition and the specializer's
`scanBody` one); vararg callees; a call whose function type differs from the callee's; a parameter
or call-site argument carrying any attribute but `noundef`/`signext`/`zeroext`/`inreg`; and it never
DELETES A CALL (a dead `cq_theta` is the user's gate; `-O1` keeps it in the twin too). [⚠ FALSE for
LLVM intrinsics (r1A F-VA-2): `-O1` deletes a dead `llvm.smax`/`abs`/`ctpop` in any TU. Round 2 never
deletes a ROOT and deletes every DEAD call, intrinsics included.]

**Null constant, not DAE's `poison`**: a `noundef` parameter makes a poison argument immediate UB
unless the callee's attribute is stripped (this stage never touches the callee), and a clone call
inside a clone is duplicated into its `_unc` twin, where an undef/poison literal is bd xy9n's
two-reads-two-values hazard.

## 3. Fixtures (Rule 12)

**New, 20** (`ir-pass/test/spec_{accept,reject}_{dropped_arg,phantom_arg_read}_*.ll`). 15 are RED on
the ORACLE and green here (measured through a lit site config pointing `%cq-opt` at the frozen
oracle: 15 FAIL / 5 PASS there, 20/20 PASS here); 5 are CONTROLS, green on both (a spec-QUANTUM clone
that reads its argument — byte-identical lowered module; the backstop's theta-source exemption; a
`weak` callee the drop must not touch; two spec-quantum readers M-C must keep unsettled). Three of
them (`theta_kept`'s partner `pure_call_kept`, `quantum_reader_outofplace`, and the rewritten header
of `quantum_reader_unsettled`) exist because the mutation matrix said a conjunct was unpinned (§9).

| fixture | pins | oracle |
|---|---|---|
| `…dropped_arg_boolsel` | the bead's shape, 4.4 `%out` (r2A `b15`) | silent dephase |
| `…dropped_arg_boolsel_provisional` | the bead's repro `b10f` inside `noinline f` | declines (3jru); silent on 9bhg |
| `spec_reject_dropped_arg_classical_call_arm` | r2A `s3d`, the ROUND-2 6.5 `%out` member; twin's decline string | silent dephase |
| `…dropped_arg_inplace_mc` | hgwx `j02C`: M-C in place like the twin | out-of-place + warning |
| `…dropped_arg_nested` | 3-TU, `out3` forwards `a` to `in1`: the FIXPOINT (two DBG lines in order) | silent |
| `…dropped_arg_quantum_clone_dead_slot` | a spec-QUANTUM clone with a dead masked slot: mask `011`→`010` | silent |
| `…dropped_arg_quantum_clone_control` (control) | a clone that reads its arg is unchanged | identical |
| `…dropped_arg_scrubbed_handle_branch` | l3oi's original spelling now accepts like the twin | declines (l3oi) |
| `spec_reject_dropped_arg_statepred_runtime_seed` | z0re `l12C`: the twin's F1 decline | accepts |
| `…dropped_arg_fp` | the `double` slot, `0.000000e+00` | out-of-place fp rail + warning |
| `…dropped_arg_theta_kept` | the cone walk never deletes a call (dead `cq_theta` kept) | clone call |
| `spec_reject_dropped_arg_weak_callee` (control) | no drop on an interposable callee | identical |
| `spec_reject_phantom_arg_read_volatile_callee` | the backstop, FROM C | silent dephase |
| `spec_reject_phantom_arg_read_range_attr` | the backstop, drop defeated by `range` | silent dephase |
| `spec_reject_phantom_arg_read_clone_sweep` | the backstop OBSERVES a use the clone's PredMux sweep removed | silent dephase |
| `spec_accept_phantom_arg_read_theta_source` (control) | the exemption (r2A `cv9S`) | identical |
| `spec_accept_phantom_arg_read_theta_source_inplace_mc` | M-C arm (d0) | out-of-place + warning |
| `…dropped_arg_quantum_reader_unsettled` (control) | a spec-quantum clone + Q+Q add, unchanged (d88e `j02Q`) | identical |
| `…dropped_arg_quantum_reader_outofplace` (control) | (d0)'s per-slot READ test: a reading clone keeps a Q+C add out of place | identical |
| `…dropped_arg_pure_call_kept` | the cone walk never deletes a call LLVM calls trivially dead (`memory(none)` clone call) | clone call |

Every drop-dependent fixture carries an `env CQ_DEADARG_DBG=1` RUN and checks the census line (or
its absence), because a same-string owner move is invisible to every other check.

**Re-spelled, 29.** The census (`CQ_DEADARG_DBG`, one stderr line per drop; env-gated, no behaviour
change) found 33 lit modules the drop touches. The stdout/stderr A/B saw only 15 of them move; the
other 18 kept their verdict AND their decline string while their SUBJECT changed owner (14 bd d88e
decline fixtures now declined at the classical-mux guard itself, same string). Each fixture whose
callee ignored the argument got ONE dead read in the callee (`%vsfp.read = mul …`), a header note,
and an `env CQ_DEADARG_DBG=1` + `CHECK-NOT: CQ_DEADARG_DBG` pin — so the fence it was written for is
still reached, and a future widening of the drop (dataflow liveness) turns it red instead of
silently retiring it (L8): the 14 d88e declines, the 6 l3oi declines, `spec_reject_ret_{poison,
undef_derived,undef_spelling,poison_nested}`, `control_predmux_reject_selectform_purecallee_retpoison`,
and the accepts `spec_result_classical`, `spec_reseed_theta_source`,
`lowering_classical_mux_phi_onereg_spec_scrubbed_{elsewhere,base_degenerate}` (the first's
whole-file `CHECK-NOT: cq_template` rescoped to the caller: the clone body now has the dead read's
template pair). ⚠ That residual population — a callee that READS its argument yet returns
classical — is IR-only from C at -O1, EXCEPT through the volatile spelling (§4), which keeps the
l3oi / d88e fences C-reachable.

**Converted, 1.** `lowering_reject_live_record_clone_unused_arg.ll` pinned M-A clause 3 on a clone
call with an unread slot; the drop removes that call's read and the dead sibling record, so it now
pins the twin's stream (no warning; `__cq_q_inner_10(i32 0, …)`). Its header's "IR-ONLY" paragraph
had predicted exactly this. The same shape with the drop defeated declines at the backstop, so
`cloneArgReachesResult`'s unused-slot branch is now reached only by an exempt `cq_theta` operand
(comment corrected at the source, `RotationLowering.cpp`).

**Unchanged but touched, 3** (owner verified by string specificity): the two
`control_inplace_ry_reject_rail_round2_*` (a classical `ext_sink(%measure)`), and
`spec_reject_arity_64` (63 dead `Argument` operands dropped; the 65-parameter arity fence fires
unchanged).

**e2e, 6 new + 1 re-spelled.** `slice_spec_dropped_arg_{boolsel,inplace}` (2-TU, lib
`spec_dropped_arg_lib.c`), their `_twin` single-TU slices, and two `*-twin-identical` gates. Both
gates are RED on the oracle [⚠ WRONG (r1B F-VB-6): the twin-identical gates compare two committed
goldens and cannot be red on any binary; what is red is the two 2-TU SLICE entries] (measured: the oracle's 2-TU boolsel trace carries the 11-line `%out`
copy block; its inplace trace carries `cq_template_add_i32_hl` + the Ry on the copy). The d88e
golden `slice_spec_lift_scrubbed_elsewhere` kept its bytes, but its library now stores `a` to a
volatile local so the slice still scrubs (with an unused `a` it would scrub nothing).

## 4. The backstop, and its one exemption

`declinePhantomCloneArgReads(M, taint)`: for every call in a NON-clone function to a function the
specializer built (`taint.SpecHandleArgMask`, its own record — never the `__cq_q_` name), for EVERY
slot (not only the detection mask: a round-2-tainted unmasked slot is a phantom read on the same
terms), if the built callee's parameter has no uses and the operand is tainted and is not a
`cq_theta` result → decline. Clone bodies are not scanned: an inner call's phantom operand is
uncomputed by the enclosing Bennett wrap before the clone returns.

**Why it observes rather than predicts.** It reads the BUILT clone: the fenv-ruled volatile erasure,
PredMux's sweep and `lowerCloneSelect`'s tree erase all remove parameter uses AFTER the drop ran.
[⚠ The volatile erasure does NOT run after the drop on the clone — it runs on the original callee
before `detectSpecializations` (r1B F-VB-3). Round 2 moved the question there (slot B).]

**Slot** (both entry points): LAST in the post-`specialize()` decline chain — after the d88e lift
re-ask, the 2qyz re-sweep, the l3oi fence, the 3d8q stale-reader backstop, s82e's and tu9q's loop
re-asks; before `lowerRotations` (which RAUWs `cq_theta` results to handles). Composed with bd 9bhg
the order is d88e → 2qyz → l3oi → 9bhg's late 3jru → 3d8q → s82e → tu9q → vsfp. Why last: the twin
never computes the phantom operand, so any other owner that fires also fires on the twin [⚠ FALSE in one
direction (r1B F-VB-5 `v27`): an earlier owner can fire on the phantom operand's own cone, which the
twin lacks — a decline where the twin accepts] and must
keep its string (`diagnose` exits on the first `DS_Error`). Nothing between `specialize()` and here
writes `taint.Tainted`.

**The exemption** is r2A's harmless quadrant: a `cq_theta` result is the user's register, the phantom
read neither mints nor keeps alive anything the twin lacks. Without it r2A `cv9S` (ACCEPT on the
oracle, twin-identical) went A→D in an intermediate build — measured, and why it exists. What such a
read could still do is M-C's G7 → (d0), §5.

## 5. hgwx — what the drop subsumes and what it did not

- **Subsumed:** every measured hgwx member (`j02C`, `e02C`, `j01C`, r2A's warned `b2 b5 b6 b7f b8f
  b12f b17f b18f`) — the phantom read is dropped, M-C lowers in place, no warning, census 0 dirty.
- **Not subsumed:** the volatile-callee spelling (`h(a,k){ volatile int z = a; return k+1; }`), a
  C-reachable clone that never reads a `cq_theta` operand (exempt from the backstop). M-C's G7 still
  counted the call as an unsettled prior reader and lowered `u = t + q` out of place — dephased,
  warned — while the twin is in place. r1B's mutant B (settle every `__cq_q_*` by NAME) is unsound
  for a clone that reads `P`. **Arm (d0)** asks the PARAMETER instead: a call to a defined, non-vararg
  function that passes `P` only in slots whose parameter has no uses is settled — it cannot observe
  `P` or mint a rail from it, and its only possible adjoint (the clone's `_unc` twin) is the same body
  with the same unused parameter. A clone that READS the slot (spec-quantum, or classical-with-a-real
  read) falls through to (d) exactly as before — pinned by `…quantum_reader_outofplace` (mutant D2;
  the first control, `…quantum_reader_unsettled`, uses a Q+Q add that never reaches G7 and MISSED D2 —
  its header claimed otherwise and was corrected). Whether settling a READING clone would be sound is
  NOT claimed: arm (d)'s hazard is a later clone `_unc` re-reading `P`, and the module spine never
  adjoints a clone call today, so it is plausibly sound — an accept-direction widening that would owe
  its own round.
  (d0) moved 0 of 5421 modules (lit + corpora, v3 vs v4).
- **Left:** the SPURIOUS lyyf-(B) warning on that stream (M-A's `isCloneCallHop` by name) → bd `jr8q`.
- `ArithLowering.cpp` arm (d)/(e) comments corrected at the source (L7).

## 6. A second defect the twin check exposed: bd qjoc

The backstop's C customer's hand-inlined twin (`volatile int z = p;` in the caller) is ALSO dephased,
on every binary, with no clone: `eraseDeadVolatileScalarStores` leaves `p` dead and a dead 4.4
select still gets its `%out` minted and never discharged. Filed P1 (bd `qjoc`) with the repro and a
candidate fix (delete the stored value's dead cone at the erasure). It falsifies CLAUDE.md's fenv
paragraph "the dead product IS lowered, uncomputed and freed … Both are sound" for a select. For
`spec_reject_phantom_arg_read_volatile_callee` the twin is therefore not a correctness oracle; the
decline is the safe direction.

## 7. Composition with bd 9bhg (`f2148d0a`)

Scratch worktree, `git merge f2148d0a` onto this branch's WIP commit; removed after.
- **Conflicts:** `CODE_MAP.md` (regenerated) and two fixtures both branches edited,
  `taint_reject_scrubbed_handle_clone_arg{,_mixed}.ll`: 9bhg turned them into ACCEPTS (ordered
  scrub); resolved by taking 9bhg's version and applying the vsfp re-spell (dead read + DBG pin).
- **9bhg's own fixtures that move under the drop (5):** `taint_accept_spec_classical_return{,_arith,
  _branch,_clone_arg}.ll` and `taint_reject_scrubbed_handle_clone_arg_layout.ll` — all callees ignore
  `a`, so the spec site vanished (the composed module is the twin). Re-spelled the same way; the
  first also needed its clone-body `CHECK-NEXT` chain relaxed (the dead read's templates precede the
  `add`). Patches: `vsfp_probes/results/compose_9bhg_{conflict_resolution,fixture_respell}.patch` —
  for bd 9bhg's owner to apply at merge.
- **Composed gates:** lit 2335 discovered, 2334 passed + 1 XFAIL; `ctest -R "spec|twin-identical"`
  77/77. `cq-opt` `e29f68ce5298dedc`.
- **r2A battery** (361 modules, null 9bhg-vs-9bhg 0): 9bhg → composed moves 130: A→D 3, D→A 26,
  DIAG 2, STREAM 99. All are TRACE-IDENT / DECL-SAME with their twins (26 D→A, 94 STREAM, 1 DIAG, 1
  A→D), or DECL-SAME with the 2-TU hand twin (`s3b`, `s3c`), or oracle-trace-identical to 9bhg (IR text
  only: `g3C g4C s_f32T s_f64T s_f80T`). Every F-9C-1 member (`b10 b15 s3d b10f b15f s3c b26 b20` and
  the warned `b2 b5 b6 b7f b8f b12f b17f b18f`, plus `j02C`) is twin-identical or DECL-SAME composed.

## 8. Measurements (commands in `vsfp_probes/tools/`)

- **Full lit** (subject, final): 2328 discovered, 2327 passed + 1 XFAIL.
- **Corpus A/B, ORACLE → SUBJECT** (`ab.py`; stdout sha, stderr text, exit code; null control ORACLE →
  ORACLE run FIRST on every list, 0 movers each):
  - **lit, 2328 fixtures: 16 movers, all this change's own** — the 15 red new fixtures (the 5 controls
    do not move) + the converted live-record fixture. The 29 re-spelled fixtures do NOT move.
  - **e2e single-TU 397 modules: 0. multi-TU 27: 2 (the two new 2-TU slices)** — the re-spelled
    d88e slice does not move. (Stage-1 modules built from every `run_slice*.sh` registration.)
  - **record-probe corpus, 2679 modules** (every `.c`/`.ll` under this session's record dirs, the
    r2A/r1A/r1B/d88e/xdu2/8e5r batteries included): **309 movers** (A→D 14, D→A 182, DIAG 71, STREAM 42), every one classified by
    `twin.py` (hand twin, else a FAIR auto twin that inlines only the dropped callee):
    293 TRACE-IDENT / DECL-SAME; `s3b`/`s3c` DECL-SAME with the 2-TU hand twin (the auto twin sees
    `K`'s `const` and speculates it); battery `n4 s_f32 s_f64 s_f80` TRACE-IDENT with r2A's hand twins
    of the same programs; `rb02C` equivalent by reading (the twin's `-O1` folds `t+5`/`t` into
    `select(c,5,0)+t`: same values); 9 STREAM rows oracle-trace-identical (IR text only).
  - **A→D population, named (14):** 13 are bd z0re's side-door members — 11 distinct programs,
    `l12C l17C a01C a02C r03C zcC zfC zjC zkC zmC zxdC`, plus r1A_9bhg's copies of `l12C`/`l17C` — now
    declining with the twin's F1 / angle-select string; 1 is r2A `s3d`, declining with the twin's
    `control flow under quantum control`.
- **Per record dir** (probe movers): r2A 137, r1A_9bhg 51, r1B_d88e 62, d88e 23, `probes` 15, r1B_9bhg
  12, r1A_d88e 9 (`twin_final.txt`).
- **Two instrument failures of this track, both caught, both L10's shape.** (1) An A/B over a list of
  RELATIVE paths reported `movers=0` over the full denominator — every input unreadable to both
  binaries. Caught by implausibility; `ab.py` now refuses a run with an unreadable input (positive
  control: a nonexistent path → `INPUT ERROR`). (2) See §9: four mutants were STALE binaries.
- **Mutation matrix**: §9. **Full ctest, equivalence-full, code map**: §11.

## 9. Mutation matrix (full lit per mutant, `lit --timeout 60`)

Source mutants built one at a time in a scratch worktree (`tools/mutants.py`), each binary run over the
whole lit suite through the oracle-style site config (`tools/mutmatrix.sh`, which reports lit's own
discovered count and refuses a 0-test run as BROKEN). **Null control first: M0 (a comment-only edit) —
0 failed of 2326 and of 2328, and its binary is bit-identical to the SUBJECT.**

| mutant | what it removes | result |
|---|---|---|
| M1 | the drop (returns false) | KILLED, 11 |
| M2 | the fixpoint (one pass) | KILLED, 1 (`…nested`) |
| M3 | the constant-operand skip | KILLED by NON-TERMINATION: 15 TIMEOUT — the skip is what makes the fixpoint terminate |
| M4 | the `use_empty()` test (drop every int/fp argument) | KILLED, 211 |
| M5 | `hasExactDefinition()` (only `!isDeclaration()`) | KILLED, 1 (`…weak_callee`) |
| M6 | the parameter-attribute whitelist | KILLED, 1 (`…range_attr`) |
| M7 | the int/fp type restriction (pointers too) | MISSED — argued equivalent: with the attribute whitelist refusing `nonnull`/`dereferenceable`/`byval`…, a null for an unused pointer parameter is sound; the restriction is scope (keeps the drop off addresses) |
| M8 | the cone deletion | KILLED, 7 (the dead select's `%out` is minted again) |
| M9 | the `!isa<CallBase>` conjunct of the cone walk | KILLED, 1 (`…pure_call_kept`; `…theta_kept` alone MISSED it — a `cq_theta` call is never trivially dead) |
| M10 | the intrinsic-site membership skip | MISSED — ⚠ "equivalent" was FALSE (r1A F-VA-5): LOAD-BEARING for a module that DEFINES `cq_theta_si32` (the angle became 0.0); pinned in round 2 |
| M11 | the vararg exclusion | MISSED — argued equivalent: a dead FIXED parameter of an exact vararg definition is as dead; conservatism |
| B1 | the backstop (returns false) | KILLED, 3 |
| B2 | the `cq_theta` exemption | KILLED, 2 |
| B3 | the "parameter has no uses" test | KILLED, 10 |
| B4 | the "operand is tainted" test | KILLED, 2 |
| B5 | the clone-body skip | MISSED — equivalent by construction: module `taint` never holds a clone-body value (C-Taint), so the tainted-operand test is false there anyway |
| D1 | arm (d0) | KILLED, 1 (`…theta_source_inplace_mc`) |
| D2 | (d0)'s per-slot READ test (settle any call to a defined function) | KILLED, 1 (`…quantum_reader_outofplace`, added for it; the first control MISSED it) |

⚠ **THE HARNESS LIED ONCE, IN THE KILLED DIRECTION, AND THE DENOMINATOR DID NOT CATCH IT** — four
mutants were STALE: `make` compares mtimes at one-second resolution here, so a mutant whose source was
written in the second its predecessor's object was built was NOT recompiled, and "M4" was byte-for-byte
M3 (sha-256: M3==M4, M6==M7, M8==M9, B3==B4). M4 then "timed out" for M3's reason. Found by hashing
every mutant binary; the four were rebuilt with an explicit mtime bump (`mutants.py` now does this and
prints each hash), and the table above is the rebuilt binaries' result. A second trap in the same run:
lit has no default timeout, so M3's non-terminating pass hung the whole matrix (12 wedged `cq-opt`
processes, killed by PID) until `--timeout 60` was added; its first row reads BROKEN, which is the
denominator check doing its job.

## 10. What a Rule-13 round should attack first

1. **The slot and the taint-agnosticism of the drop.** It rewrites CLASSICAL calls too (measured:
   no classical-only fixture moved, but the corpus is one-function-heavy, bd 1yeu). Does any
   pre-pass (by-ref inliner, rail bank, volatile folds, fp80, PredMux, unroll, ctlz) depend on a call
   operand being non-constant, or on an instruction the cone deletion removes? Is "no uses" really
   monotone across the window for every pre-pass (the argument in §2 is by enumeration)?
2. **The cone deletion.** It deletes non-call trivially-dead instructions, phis included. A dead phi
   cycle survives (not use-empty). Can it delete something a later stage keys on (rail-bank loads,
   an `!cq.*`-carrying instruction)? It runs before every record is taken, so no record can dangle —
   check that claim.
3. **The backstop's exemption.** "A `cq_theta` result is harmless" — attack it with other consumers
   of a phantom read than M-C (the spine's FreePoint, M-B interior plans, the stale-reader record,
   `loopCarriedHandlePhi`), e.g. a theta-source phantom read inside a loop, or before a
   `cq_measure` of the same register.
4. **Arm (d0)** is a Rule-13 change to M-C's G7: attack a call that passes `P` twice (one read slot,
   one unread), a `_unc` twin reached through arm (b) first, the late (x67f) round.
5. **Equivalent mutants §9 calls MISSED-by-construction** (intrinsic skip, vararg, pointer type,
   clone-body scan): is any of them in fact load-bearing?
6. **The 29 re-spells.** A dead read changes the CLONE (a Bennett-wrapped template pair). Does any
   re-spelled fixture now reach its fence for a different reason than before?
7. **Policy interactions for the owner** (§1): bd z0re's dead-parameter side door, bd cepm's and bd
   9bhg's customers — the drop answers these for a callee that ignores its argument by twin parity,
   and leaves the side doors themselves (a clone that READS its argument yet returns classical)
   exactly as they were.

## 11. Gates as literally run

All on the SUBJECT binaries (`cq-opt` `73fd07592c4960dd`, rebuilt after the last comment edits to the
same hash):
- `cmake --build build -j8` (all targets, incl. `cq-opt-debugalloc`, `cq-scrub-selftest`).
- `lit ir-pass/test`: **2328 discovered, 2327 passed, 1 XFAIL** (50 s).
- `ctest --test-dir build -j6 --output-on-failure`: **515/515 passed in 596.95 s**, started under load
  (load averages 10.6 / 13.7 / 63.8 at start — the mutation matrix had just finished), so the time is
  not comparable with a quiet-box figure. +6 entries: the two 2-TU slices, their twins, the two
  `*-twin-identical` gates.
- `cmake --build build --target cq-opt-equivalence-full`: **2328 fixtures, 0 mismatches**.
- `python3 tools/update_code_map.py --check`: clean (regenerated).

## 12. What this track did NOT attack

- A statevector check (owner rule); the dephasing numbers are r2A's analytic ones.
- `invoke`/C++, `callbr`, musttail calls with a dropped argument, and multi-module link orders beyond
  `llvm-link caller lib…`.
- The widening of the drop to "a parameter used only by a volatile store to a non-escaping local"
  (fenv-consistent; would turn the backstop's C customer into the coherent accept) — left to bd qjoc.
- `+Asserts` / ASan builds (bd r4f6's four-fixture bill).
- The second entry point is a dead shim (AXIS-F); it got the same two slots and was not exercised.

---

# ROUND 2 (2026-09-26) — liveness, not use-count

Both Rule-13 rounds on `5e56060b` were **NOT-CLEAR** (`review_r1A_vsfp/REVIEW.md`,
`review_r1B_vsfp/REVIEW.md`, committed with this round, unmodified). The 16 named F-9C-1 members and
hgwx's members were twin-identical, but the CLASS was not closed and the backstop was not total. The
common root is CLAUDE.md L5: the drop, the backstop and arm (d0) all asked `use_empty()` of a
parameter, and the caller-side clean-up was a local "trivially dead, never a call" walk. The twin gets
every one of those shapes right because `clang -O1` asks the semantic question — dead-code
elimination by LIVENESS. Round 2 asks that question, in one place, and calls it from every consumer.

⚠ **§1–§12 above are ROUND-1 TEXT and are kept as the record of what round 1 claimed.** Each round-1
sentence the reviews falsified is marked inline with `⚠` and the finding id; this section is the
current description. Do not quote §1–§12 without their markers.

**NOT self-cleared.** Round 2 owes its own Rule-13 round(s): §R2.12 is the attack list.

Binaries (sha-256 prefixes, all re-measured):

| tag | what | `cq-opt` |
|---|---|---|
| ORACLE | `main` `aee8f4f8`, frozen | `69250feaf68bbe49` |
| ROUND 1 | `5e56060b` (`bin/cq-opt.v5`) | `73fd07592c4960dd` |
| SUBJECT | round 2, final | `d17c95e8353711b1` (`libCQPass.so` `6c6d477073d4c5a1`, `cq-opt-debugalloc` `811fd55484018ec3`) |
| COMPOSED | round 2 merged with bd 9bhg `f2148d0a` (scratch worktree, removed) | `5e5a47214a22180c` |
| 9BHG | bd 9bhg `f2148d0a` alone | `bfb441d3b9568bd1` |

Build null controls: the mutation worktree's comment-only null mutant N0 hashed BIT-IDENTICAL to the
SUBJECT (`cq-opt` AND `cq-opt-debugalloc`); every comment-only edit made after the matrix rebuilt the
SUBJECT to the same hash, and the composed tree rebuilt after its last (comment-only) sync to the same
`5e5a47214a22180c` (§R2.9).

## R2.1 The finding ledger, and what round 2 did with each

| id | sev | round-2 disposition | pin |
|---|---|---|---|
| F-VA-1 (ctz4) | P1, introduced | the drop mirrors LLVM DAE's preconditions: exact definition, **not `naked`**, not variadic, not `musttail`, call type = callee type; a parameter carrying none of `returned`/`swifterror`/`byval`/`inalloca`/`preallocated`; attributes whitelisted, `range`/`nofpclass` STRIPPED as DAE strips its UB-implying set | `spec_accept_dropped_arg_naked_kept.ll`, `spec_reject_dropped_arg_naked_quantum.ll` (oracle verdict), `spec_accept_dropped_arg_range_attr_stripped.ll` |
| F-VA-2 (m1gi) | P1 | the caller-side clean-up is `deleteDeadCones`: the dead part of the operand's cone by LIVENESS, dead intrinsics and dead side-effect-free calls included, never a root | `spec_accept_dropped_arg_dead_intrinsic_{smax,abs,ctpop}.ll`, e2e `…-dead-smax` |
| F-VA-3 | P2 | liveness has no `use_empty()` blind spot: a dead φ cycle is dead | `spec_accept_dropped_arg_dead_loop_cycle.ll` (the `dcar1` shape, twin-identical) |
| F-VA-4 | P3 | `deleteDeadCones` folds an arm it emptied (SimplifyCFG's empty-arm fold, and the two-entry-φ fold to a `select` + block merge) | `spec_accept_dropped_arg_emptied_arm{,_phi}.ll` (`ediam1`/`ediam2`, twin-identical) |
| F-VA-5 | P3 | the intrinsic-site skip is load-bearing and pinned; front-end sites are also liveness ROOTS by membership, and reserved-namespace calls by name (conservative direction) | `spec_accept_dropped_arg_reserved_symbol_{angle,theta_kept}.ll`, `…_reserved_marker_kept.ll` |
| F-VA-6 | P3 | `spec_result_classical.ll`'s NOT restored to its whole-file window | that file |
| F-VA-7 | P2 | the five claims corrected at the source (`SpecializeDetect.{h,cpp}`, `CQLoweringPass.cpp`, `ArithLowering.cpp`, `Specialization.h`) and marked in §1–§9 | — |
| F-VB-1 (a8q5) | P1, pre-existing | the fenv stages delete their dead cone; the drop is asked again right after them (slot B) | `spec_accept_dropped_arg_volatile_{char,derived,double,two_stores,promoted_residue,round2_arm,hgwx,promoted_bool,stale_attrs}.ll`, e2e `…-volatile-char` |
| F-VB-2 | P1, composed | as F-VB-1; composed v21–v25 are twin-identical (§R2.8) | the composed battery |
| F-VB-3 | P2 | attribution corrected (`Specialization.h`, `ArithLowering.cpp` (d0), fixture header, §1/§2/§4, bd jr8q note); the shipped `volatile int z = a;` customer is now PREDICTED (slot B) and accepts with the fenv-intended twin's stream | `spec_reject_phantom_arg_read_volatile_callee.ll` (name kept, now an accept) |
| F-VB-4 | P3 | the backstop declines only a value NOTHING ELSE keeps alive; `v12` itself is now removed by slot B before the backstop | `spec_accept_dropped_arg_volatile_promoted_bool.ll`, `spec_accept_phantom_arg_read_kept_alive.ll` |
| F-VB-5 | P3 | the slot rationale rewritten at the source (`CQLoweringPass.cpp`) | — |
| F-VB-6 | P3 | the wording fixed in `tests/e2e/CMakeLists.txt`, both slice headers and §3 | — |
| F-VB-7 (qjoc) | P3 / owner | the fenv erasure deletes the dead product; CLAUDE.md's "Both are sound" is FLAGGED, not edited (§R2.6) | `lowering_volatile_scalar_deadstore{,_select,_template}.ll`, `…_promoted_residue.ll`, `lowering_reject_volatile_scalar_deadstore_measured.ll` (name kept, now an accept) |

## R2.2 The predicate — `DeadValueLiveness.{h,cpp}` (new)

**Mark-from-roots liveness** (the classic DCE argument): a value is LIVE iff it is a root or an operand
of a live instruction; every other instruction is dead. **ROOTS** (`isLivenessRoot`), identity roots
asked FIRST so no later rule can override them:

1. every front-end intrinsic SITE (`cq_theta`/`cq_phi`/`cq_measure`), by MEMBERSHIP of the taint lists;
2. every call to a function the specializer built (`SpecHandleArgMask`, its own record);
3. every call into the reserved namespaces `cq_`, `__cq_`, `cqrt_` — the NAME used only to ADD a root
   (it can refuse a deletion, never allow one), for a module that DEFINES a reserved symbol with a
   pure body (r1A F-VA-5's `resv2` shape). ⚠ Its first spelling sat after the side-effect branch and
   never fired for a defined attribute-less callee; the marker fixture measured that and it was moved;
4. every terminator and EH pad (so every branch condition is live — no control dependence);
5. every instruction LLVM says `mayHaveSideEffects()`, EXCEPT a direct `call` to an exact,
   non-`naked`, non-variadic definition whose BODY is side-effect-free and terminating
   (`bodyIsSideEffectFree`: acyclic CFG, no call of any kind, no memory write, no EH, only
   `br`/`switch`/`ret`). The body rule exists because `-O1`'s inferred attributes are STALE after the
   fenv stages erase a store (r1B `v16`: `memory(inaccessiblemem: readwrite)`, no `willreturn`).

**The call-slot rule** — the only interprocedural step: an argument in a slot the specializer RECORDED
dead (`taint.SpecDeadArgMask`, `isRecordedDeadSlot`) does not become live through that call. Before
`specialize()` the record is empty, so every slot counts as read.

**LIMITS, stated in the header:** no control dependence (a branch-only read keeps a parameter live —
the conservative direction for every client); loops are not special; pointers are values.

**Why not LLVM's ADCE/DAE.** ADCE deletes by liveness over the WHOLE function — including every dead
tainted computation in the input, and it removes dead branches — which changes more than the dead cone
of a dropped operand (every fixture that pins a dead tainted value's lowering would move, and a
branch removal needs post-dominator bookkeeping this stage does not own). DAE rewrites SIGNATURES,
which a Phase-6 clone's `_unc` twin and the specializer's mask cannot follow. Round 2 therefore
mirrors ADCE's liveness QUESTION and DAE's PRECONDITIONS, and scopes the deletion to the cones of its
seeds. The body rule is narrower than LLVM's `FunctionAttrs` inference (no loops, no calls), in the
conservative direction.

**The one deletion — `deleteDeadCones(F, Seeds)`**: the dead part of each seed's backward cone
(through operands of dead instructions; a live operand stops the walk), forward-closed over dead users,
debug intrinsics salvaged and never deleted, references dropped before erasure (so cycles are fine),
then SimplifyCFG's two folds for a conditional branch whose successors reach one block `S` through
arms the deletion touched: no φ in `S` → `br S`; φs in `S` and exactly the two paths as predecessors →
each φ becomes `select Cond, v_true, v_false` (`FoldTwoEntryPHINode`), then `MergeBlockIntoPredecessor`.
The dead condition cone is deleted the same way. Never the entry block, never an address-taken block.
The fold considers a branch whose arm or common successor the deletion touched, OR an arm the caller
reports it emptied: the three
fenv stages erase stores/loads themselves, and `if (a > 3) { volatile int z = 1; }` in a callee left an
EMPTY diamond whose condition kept `a` live — measured on an intermediate round-2 build (`r2f`), that C
program reached the phantom-read backstop instead of lowering to its fenv-intended twin; with the fold
it drops at slot B and is TRACE-IDENT (`spec_accept_dropped_arg_volatile_arm_{const,value,constfold}.ll`).

## R2.3 Where the predicate is asked (Rule 14: one predicate, every consumer calls it)

| consumer | what it asks |
|---|---|
| `dropDeadCallArguments` (slots A and B) | `deadParamMask(callee)` for the slot; `deleteDeadCones` for the cleanup; every unused call to a user DEFINITION is also a seed (the dead call a TU boundary hid — r2A `s3d`'s `K(m)`, `dc1`'s unused clone call) |
| `foldVolatileConstAllocaLoads` | `deleteDeadCones({}, emptied blocks)` — the empty-arm fold for an arm the fold emptied |
| `eraseDeadVolatileScalarStores` | `deleteDeadCones(stored values, emptied blocks)` after erasing the stores (bd qjoc) |
| `promoteVolatileScalarLocals` | `deleteDeadCones(promoted stores' values, emptied blocks)` after `PromoteMemToReg` (`v29c`) |
| `buildClone` | `SpecDeadArgMask[Clone] = deadParamMask(clone)`, on the stock-opcode body after control flattening and inner retargeting, before `lowerCloneSelect`/`lowerOps` |
| `declinePhantomCloneArgReads` | `isRecordedDeadSlot` for the slot; `FunctionLiveness` of the caller for "kept alive elsewhere" |
| M-C arm (d0) | `isRecordedDeadSlot` for every slot `P` is passed in |

## R2.4 Final pre-pass order (both entry points) and the L1 stage table

`run()` (and `runOnFunction()`, mirrored) up to `specialize()`:

1. passthrough early-out; `propagate`
2. **SLOT A** `dropDeadCallArguments` (+ `propagate` if changed)
3. `lowerByRefInline` fixpoint
4. `declineForeignRailBankSeeds`; `promoteRailBankCells` fixpoint; `markRailBankAllocas`
5. `foldIdentityBitcasts`; `foldVolatileConstGlobalLoads`; `foldVolatileConstAllocaLoads` — **now folds an arm it emptied**
6. `eraseDeadVolatileScalarStores` — **now deletes the stored value's dead cone and folds an arm it emptied**
7. `promoteVolatileScalarLocals` fixpoint — **now deletes the promoted residue and folds an arm it emptied**
8. **SLOT B** `dropDeadCallArguments` (+ `propagate` if changed) — **new**
9. `promoteFp80Union` fixpoint; PredMux; unroll; ctlz; … `detectSpecializations`; round-1
   emission; round 2 (bd 9paa); `specialize()`; the post-`specialize()` decline chain ending in
   `declinePhantomCloneArgReads`; `lowerRotations`; `lowerOps` (M-C (d0)); …

| stage (moved / changed) | premise it relies on | can anything between its slot and the premise's owner falsify it? | grows taint? |
|---|---|---|---|
| SLOT A | no stage has READ the dropped operand (no mask, no rail, no record keyed on it) | nothing runs before it | ⚠ **YES, it can** (r2A F-WA-2 #3: its fold can mint a tainted `select`); the `propagate` restart it already performs is the whole obligation — right conclusion, wrong ground (§R3.6) |
| (5) const fold + arm fold | an arm it emptied has no effect (it is empty) and a φ fold's incomings are available at the branch | the fold runs inside the stage, on blocks the stage just emptied; nothing between | ⚠ **FALSE — YES** (bd otam, r2A F-WA-1/F-WA-2 #2): a `select` on a TAINTED condition is a new tainted value, and round 2 never re-propagated. Round 3: re-`propagate` on a true return (§R3.2) |
| (6) erase + cone | the cone is DEAD under liveness at this point | liveness is computed at the call; the deleted instructions are dead by definition; front-end sites are roots | ⚠ **FALSE — YES** (bd otam, r2A `stale3a/b/c`, `loop2`): the arm fold behind the cone deletion mints a tainted `select`. Round 3: re-`propagate` on a true return (§R3.2) |
| (7) promote + residue | same | same | no (its own `propagate` after a true return) |
| SLOT B | no stage has read the operand yet | stages 3–7 read call operands? `lowerByRefInline` inlines by-ref libm calls (no call left to drop); the rail bank records metadata on ALLOCAS and mints `cqrt_alloc` (a root); the folds are accept-only normalisers. None records an SSA value SLOT B deletes | no |
| clone record (`buildClone`) | the clone body at record time is the body that runs | later clone passes lower reads into runtime calls (no NEW read of a dead slot); a dead instruction left in the clone is lowered as a forward/adjoint pair inside the Bennett wrap (net identity); the clone's `_unc` twin is never emitted at top level (r1B measured) | no |
| backstop / (d0) | the record | round 2 of control detection runs on MODULE functions, not clone bodies | no |

⚠ **The window question this table cannot close by argument:** the record is keyed on the clone
FUNCTION and asked by callee identity; `ScrubMap` drops a deleted clone's key. A clone rebuilt under
the same pointer is the 8e5r class the scrub containers exist for.

## R2.5 The backstop now — `declinePhantomCloneArgReads`

⚠ **SUPERSEDED IN ROUND 3 (bd tzfa, r2B F-WB-1).** The "kept alive elsewhere" exemption below was
UNSOUND: it accepted with the phantom read still in the use list, and the uncompute spine then saw
one consumer too many and left a template rail dirty (`k19`: `q` fully dephased). Round 3 replaced
the function by `resolvePhantomCloneArgReads` (neutralise every recorded-dead slot, then decline an
unread quantum operand) — §R3.3. The text below is round 2's record.

For every call in a non-clone function to a callee with a record, for every slot the record calls
dead, operand `Op` declines iff: `Op` is not a constant; `Op` is QUANTUM (tainted, or in
`ControlOwnedRails`/`UntaintedMergeRails`/`OutputRails`); `Op` is not a `cq_theta` result (r1B's
nine-shape exemption, argued at the definition); and nothing else keeps `Op` alive
(`keptAliveElsewhere`: a live non-call user under the caller's liveness, a `cq_measure` or
`cq_theta` arg-0 read, a `ret`, or a clone read slot). Runtime `cqrt_*`/`cq_template_*` users are
not counted as keepers (a `%out` rail's `cqrt_copy_*` writes are users too, and telling a write from
a read needs the runtime ABI's slot semantics): **an over-decline is possible where some emitted
runtime gate genuinely READS the phantom operand and nothing else does** — named, not constructed.

**What it is NOT (L7):** "TOTAL". It observes phantom reads THROUGH A CLONE CALL whose slot the
CLONE's own pipeline made dead. Since round 2 the drop predicts every slot whose parameter is dead in
the ORIGINAL callee after the fenv stages, so the backstop's remaining customer is a slot only the
clone's flatten kills (a branch-only read) — hand-written IR; `clang -O1` deletes an empty diamond.
⚠ **FALSE (r2B F-WB-2, bd stl3): the C-reachable count was NOT zero** — every `(void)K` / `__builtin_expect` / `? K : 0` spelling on a volatile GLOBAL reached this fence (the global fold had no arm fold), and a keeper made it ACCEPT a Rule-8 wrong unitary (bd tzfa). Corrected in §R3. Its C-reachable customer count is **zero** as far as measured — ⚠ after one was FOUND and removed
this round: `if (a > 3) { volatile int z = 1; }` reached it on build `r2f` (the fenv stage emptied the
arm but nothing folded it); the fenv stages now fold what they empty (§R2.2).

## R2.6 F-VB-7 — the owner-ruled fenv sentence, FLAGGED (not edited)

CLAUDE.md "Scope of the semantic model": *"with **no** enclosing tainted control flow the dead product
IS lowered, uncomputed and freed; inside a PredMux region it is deleted outright. Both are sound; they
are not the same circuit."* **False on both halves before round 2, for programs whose dead product's
source takes a later non-diagonal gate** (measured on the oracle and on round 1, byte-identical):

- `qjoc` (a dead 4.4 SELECT, no call): `int p = b ? 9 : 4; volatile int z = p; int t = m + 1;
  b = cq_theta(b, .7); return t + cq_measure(b);` — the select was claimed, its `%out` which-path rail
  minted and never discharged: 15 trace lines against the fenv-intended program's 4, exit 0, NO
  warning, 2b STRICT clean. P(b=1) for odd m: 0.8356 (dephased) vs cos²(0.6) = 0.6812.
- `qjoc_tpl` (a dead TEMPLATE product): `int p = q * 3; volatile int z = p; int t = m + 1;
  q = cq_theta(q, .7); return t + cq_measure(q);` — `cq_template_mul_i32_hl(h0, 3) -> h1` was never
  uncomputed; h1 stayed dirty across `Ry(.7)` on h0 (warned, lyyf-(B)).

Round 2 makes the stage delete the dead cone, so both now lower to the fenv-intended program (twin
TRACE-IDENT, `lowering_volatile_scalar_deadstore_{select,template}.ll`). The sentence therefore
describes neither the old behaviour (not "sound") nor the new one (there is no asymmetry left: the
product is gone in both cases). **Owner: the ruling is not in question; the sentence's second half
should say the computation is deleted in both cases.** Recorded in `QramLowering.h` and at the
`CQLoweringPass.cpp` call sites.

## R2.7 Fixtures

`ls ir-pass/test/*.ll | wc -l`: **2363** (round 1: 2328).

- **New, 33**, generated by `vsfp_probes/r2/tools/mkfix2.py` from the module's lowered output (ordered call
  sequence of the quantum function, SSA names wildcarded, constants kept; a `CHECK-NOT` for any runtime
  or clone call between consecutive matches; a `NEG` prefix forbidding every callee the ORACLE emitted
  there and the subject does not; the drop census pinned by `DROP`/`NODROP`):
  naked ×2; dead intrinsic ×3; dead loop cycle; emptied arm ×2; reserved symbol ×3 (angle, theta kept,
  marker kept); range attr stripped; volatile callee ×9; fenv-emptied arm ×3; `qjoc` ×2 + promoted
  residue; dead clone call; nested fixpoint (4 TUs); dead read (liveness, IR); loop callee kept;
  classical dead slot; kept alive.
- **Rewritten (names kept — CLAUDE.md L8)**: `spec_reject_phantom_arg_read_volatile_callee.ll` (now
  an accept), `spec_reject_phantom_arg_read_range_attr.ll` (a string attribute now defeats the drop),
  `spec_accept_phantom_arg_read_theta_source{,_inplace_mc}.ll` (a branch-only read — the only IR
  route to the backstop), `lowering_volatile_scalar_deadstore.ll`,
  `lowering_reject_volatile_scalar_deadstore_measured.ll` (now an accept).
- **Renamed (round-1's own, never merged)**: `…_pure_call_kept.ll` → `…_dead_pure_call.ll`;
  `spec_reject_dropped_arg_classical_call_arm.ll` → `spec_accept_…` (the dead `K(m)` goes).
- **Re-spelled again**: round 1's 29 dead-`mul` reads are now BRANCH-ONLY reads (a dead `mul` no longer
  keeps a parameter live); `…_spec_scrubbed_base_fp.ll` could not be (an FP-returning clone with a
  tainted terminator declines at `floating-point return-taint`), so its original spelling is restored
  and it pins the twin's verdict — its header says why.
- **Kept alive by a real use** (their subject was a dead call the drop now deletes):
  `spec_reject_fp_abi{,_return}.ll`, `spec_overaccept_probe_{fp_arg,i128_return}.ll`,
  `lowering_io_user_defined_callee.ll`; `control_inplace_ry_reject_rail_round2_{measured_parent,
  sibling_theta}.ll`'s `ext_sink` is now an opaque declaration (its empty body made the load-bearing
  diamond a dead call).
- **F-VA-6**: `spec_result_classical.ll`'s NOT is back to its whole-file window.

**Red-green, measured** (`tools/redgreen.sh`: the scratch lit site config pointed at each binary;
the family = every fixture this branch added or changed, 94 files): ORACLE 48 PASS / 46 FAIL; ROUND 1
(`v5`) 61 / 33; FINAL 94 / 0. Of the **37 new or renamed files, 30 are RED on round 1 and 29 on the
oracle**. The 7 green on round 1 are pins of round-2 HAZARDS the old code could not have
(`…_loop_callee_kept`, `…_nested_fixpoint`, `…_reserved_{marker_kept,symbol_angle,symbol_theta_kept}`,
`…_varargs_kept`, `…_phantom_arg_read_classical_slot`); each is red under the mutant named in §R2.10.
The 44 family files green on BOTH old binaries are those pins, the controls, and the re-spelled
d88e/9bhg/scrub fixtures whose subject is pre-existing behaviour kept reachable (they must pass on
the oracle by design).

**e2e**: `slice_spec_dropped_arg_{volatile_char,dead_smax}.c` + goldens + `*-twin-identical` gates
against the boolsel twin (4 entries); `spec_lift_classical_lib.c` / `slice_spec_lift_scrubbed_elsewhere.c`
headers corrected (the d88e golden no longer reaches the specializer; bytes unchanged);
`slice_multi_caller.c`'s `main` now returns `slice()` so `lib_bias()` stays a LIVE cross-TU call.

## R2.8 Composition with bd 9bhg

Scratch worktree `compwt2`, branch `vsfp-r2-compose-scratch` (both removed after): round 2 committed
as a scratch commit, `f2148d0a` merged; two fixture conflicts resolved to 9bhg's version and re-spelled
with a branch-only read (`vsfp_probes/r2/tools/compose2_respell.sh`), plus five 9bhg fixtures whose callee
ignores `a`; one `CHECK-NEXT` relaxed (`taint_accept_spec_classical_return.ll`: the clone's entry
block now carries the join label).

Composed binary `5e5a47214a22180c` (final round-2 sources + `f2148d0a`, a clean rebuild after the final
source copy):

- `lit ir-pass/test` in the composed tree: **2375 discovered, 2374 passed, 1 XFAIL**.
- Targeted ctest in the composed tree (`-R "spec|twin-identical|multi|scrub|libm-ld80-next"`):
  **91/91 passed**.
- The round-2 battery (84 pairs, `r2bat.sh comp3`): **79 TRACE-IDENT + 5 ORACLE-SAME, 0 other** —
  including r1B's composed members **v21–v25, all TRACE-IDENT** (on the round-1 composed binary they
  were silent dephasings, F-VB-2).
- Corpus A/B over the r2A (361) + r1B (170) batteries = 531 modules: null `comp3→comp3` **0**;
  `comp2→comp3` (the fold changes after the first composed build) **0**; `9bhg→comp3` **248 movers**
  (D→A 42, DIAG 2, STREAM 204), twin-classified (`twin_comp3.txt`, from `twin_comp2.txt` + the 0-mover
  delta): D→A 26 TRACE-IDENT + 14 TRACE-IDENT(auto) + 2 hand (`v08d` ×2, TRACE-IDENT with `v08T`);
  DIAG 1 DECL-SAME + 1 DECL-SAME(auto); STREAM 129 TRACE-IDENT + 58 TRACE-IDENT(auto) + 17 hand rows,
  every hand row trace-identical between the composed binary and round 2 alone (`otrace.py`,
  `OT_BASE=r2`), i.e. composition adds nothing to the non-composed classification below.

## R2.9 Measurements (commands under `vsfp_probes/r2/tools/`)

All on SUBJECT `d17c95e8353711b1` unless stated. Every A/B ran its null control FIRST on the same
list (`ab.py A A`, **0 movers** each time), with absolute paths (round 1's relative-path trap).

- **Full lit** (the owner's round-2 scope: no full `ctest -j6` on the branch — ruled 2026-09-26):
  `lit ir-pass/test` **2363 discovered, 2362 passed, 1 XFAIL** (55 s).
- **Targeted ctest**, literally `ctest --test-dir build -R "spec|twin-identical|multi|scrub|libm-ld80-next|free-pairing-selftest|cq-opt-equivalence$|taintset" -j6`:
  **92/92 passed** (every `spec` e2e slice incl. the 4 new entries, all 46 `*-twin-identical` gates,
  the multi-TU slices, the three `libm-ld80-next*` slices the fenv stages touch, `taintset-scrub-guard`
  (+ selftest), both `ir-pass-scrub-on-delete-selftest` entries, `e2e-free-pairing-selftest`,
  the sampled `cq-opt-equivalence`).
- **`cmake --build build --target cq-opt-equivalence-full`**: **2363 fixtures, 0 mismatches**.
- **`python3 tools/update_code_map.py --check`**: clean (regenerated).
- **Duplicate-body scan** (CLAUDE.md L8, two fixtures were renamed; `tools/dupscan.py`): 0 of the 9
  duplicate-body groups among 2363 fixtures contains a file this branch added or changed.
- **Build null controls**: the mutation worktree's null mutant N0 rebuilt to the SUBJECT's exact
  `cq-opt` AND `cq-opt-debugalloc` hashes; a comment-only edit after the matrix rebuilt to the same
  `cq-opt` hash (`d17c95e8353711b1`), so the matrix measured the committed binary.

**Corpus A/B**, denominator **5949** = lit 2361 + record probes 2679 (every `.c`/`.ll` under the 16
record dirs of this session) + round-2 probes 483 (this worktree's r1A/r1B review probes, the r1B
working set, the round-2 fixture sources and battery) + e2e single-TU 397 + multi-TU 29:

| A → B | movers | A→D | D→A | DIAG | STREAM |
|---|---|---|---|---|---|
| ORACLE → SUBJECT | 651 | 18 (P 13, Q 2, lit 3) | 292 (P 186, Q 99, lit 7) | 69 (P) | 272 (P 45, Q 186, lit 35, multi-TU 6) |
| ROUND 1 (`v5`) → round 2 (`r2`) | 259 (of 5938) | 4 (lit 1, Q 3: `naked2` ×3 + its fixture) | 92 | 0 | 163 |
| `r2` → `r2f` → SUBJECT (increments) | 1, then 3 | 0 | 3 (the fenv-arm fixtures) | 0 | 1 (the marker fixture) |

- **Every lit mover is this branch's own fixture** (`litmov.py`: 3 A→D, 7 D→A, 35 STREAM, all
  added or changed here). ⚠ That is true only AFTER eight files whose subject the dead-call deletion
  removed were given a live use (§R2.7): six went RED in lit (the four fp/`i128` ABI declines, the two
  `ext_sink` fixtures), but **two stayed GREEN with their subject gone** and were found only as A/B
  movers on files this branch had not touched — `lowering_io_user_defined_callee.ll` (its tape
  `CHECK-NOT`s passed vacuously once the call was deleted) and `slice_multi_caller.c` (trace unchanged,
  the cross-TU `lib_bias()` call gone). Rule 12(c)'s shape, caught by the A/B, not by lit.
- **Every multi-TU mover** is one of this branch's slices or `slice_multi_caller.c` (source changed).
- **Every non-lit mover twin-classified** (`twin.py`; hand twin, else a FAIR auto twin inlining only
  the dropped callee): A→D 11 DECL-SAME + 4 DECL-SAME(auto) (bd z0re's side door, as round 1; and
  `statepred_runtime_seed`); D→A 168 TRACE-IDENT + 109 TRACE-IDENT(auto) + 8 hand; DIAG 56
  DECL-SAME + 13 DECL-SAME(auto); STREAM 120 TRACE-IDENT + 80 TRACE-IDENT(auto) + 30 hand. **The hand
  rows**: `v08d` ×3, `v08c` ×3 → TRACE-IDENT with `v08T`; `qjoc`/`v01T`/`v02T`/`dvT` (the fenv twins
  themselves) → TRACE-IDENT with the program without the volatile line; `v08e` ×3 → a spec-QUANTUM
  clone's copy-out wrapper around the twin's arithmetic, and its only change from the ORACLE is the
  dead `mul_i32_hl(h0, 3)` and its `_unc`/`free` removed (listed in `hand4.txt`); every remaining hand
  row (`n4`, `s_f*`/`s_f*T`, `rb02C`, `g3C`/`g4C`, `l20C` ×2, `e2ec`, `v16b` ×3, `q1`,
  `quantum_clone_dead_slot` ×2) is trace-identical between round 1 and round 2 (`otrace.py`,
  `OT_BASE=v5`), i.e. round 1's classification stands. 7 rows have no source for the twin script:
  the six multi-TU slices of this branch (twin-identical gates) and `d01C.handedited` (an IR-only
  STREAM mover, trace-identical to the ORACLE).
- **The 84-pair round-2 battery** (`r2bat.sh`: every r1A, r1B, F-9C-1 and hgwx probe against its
  hand twin, + 5 oracle singles): SUBJECT **79 TRACE-IDENT + 5 ORACLE-SAME, 0 other**. On the ORACLE:
  9 TRACE-IDENT, 34 TRACE-DIFF, 34 VERDICT-DIFF, 2 DECL-DIFFSTR, 5 ORACLE-SAME. On ROUND 1: 32
  TRACE-IDENT, 24 TRACE-DIFF, 19 VERDICT-DIFF, 2 DECL-SAME, 3 ORACLE-SAME, 2 ORACLE-DIFF (`naked1`,
  `naked2` — bd ctz4).
- **Census** (`census2.py`, both levers `CQ_DEADARG_DBG`/`CQ_DEADCONE_DBG`, positive and negative
  control first): lit **45 of 2363** modules touched, **43 of them this branch's own**; the two others
  keep verdict AND string: `spec_reject_arity_64.ll` (dead params 2.. of a 65-parameter callee dropped;
  the arity fence still fires on the tainted slot) and `taint_reject_quantum_return_volatile_flag.ll`
  (the promotion empties the `flag = 0` arm and its two-entry φ is folded to a select — the same
  quantum-condition mux PredMux built before; same `cq taint escape` string, not an A/B mover). e2e:
  **9 of 426** — the three `libm-ld80-next*` slices (fenv cone deletions; goldens unchanged) and six
  multi-TU slices of this branch.

## R2.10 Mutation matrix

Each mutant is a one-site source edit (`tools/mutants2.py`, applied in a scratch worktree, anchor
found EXACTLY once or the build aborts; mtime bumped past make's 1 s resolution; a mutant whose
binary hashes EQUAL to the subject is refused as stale-or-compiled-away). Each mutant builds its OWN
`cq-opt` AND `cq-opt-debugalloc` (the five `%debugalloc-cq-opt` fixtures run the mutant too), and
every full-lit run (`lit --timeout 60`) goes through a site config with NO default debugalloc.
Measured boundary controls (`results/stale_debugalloc.txt`): a debugalloc OLDER than the `cq-opt`
under test → lit `fatal` (rc 2); `VSFP_DEBUGALLOC` unset → config `KeyError` (rc 2); the fresh one →
PASS. The null mutant N0 (a comment) moved **0 of 2363** and hashes to the subject. 32 mutants ran
over 2361 fixtures; after the `musttail`/varargs pins were added, N0, R7 and R12 ran over 2363.

| mutant | removes | discovered | failed | killed by (first 3) | verdict |
|---|---|---|---|---|---|
| N0_null | NULL CONTROL: a comment in `dropDeadCallArguments`; binary == subject | 2363 | 0 |  | null: 0 moved (binary hash = subject) |
| R1_drop_off | the drop never runs (both slots) | 2361 | 38 | `spec_accept_dropped_arg_classical_call_arm`, `spec_accept_dropped_arg_volatile_char`, `spec_accept_dropped_arg_fp` … | KILLED |
| R2_no_fixpoint | the drop makes one turn per slot | 2361 | 1 | `spec_accept_dropped_arg_nested_fixpoint` | KILLED |
| R3_constants_too | the drop revisits constant operands (termination) | 2361 | 38 | `spec_accept_dropped_arg_nested_fixpoint`, `spec_accept_dropped_arg_dead_intrinsic_abs`, `spec_accept_dropped_arg_quantum_clone_dead_slot` … | KILLED |
| R4_all_args_dead | every parameter reported dead | 2361 | 243 | `spec_accept_dropped_arg_volatile_char`, `spec_accept_dropped_arg_dead_intrinsic_abs`, `spec_accept_dropped_arg_scrubbed_handle_branch` … | KILLED |
| R5_use_empty_mask | round 1's `use_empty()` instead of liveness | 2361 | 1 | `spec_accept_dropped_arg_dead_read_ir` | KILLED |
| R6_naked_too | `naked` callees eligible | 2361 | 2 | `spec_accept_dropped_arg_naked_kept`, `spec_reject_dropped_arg_naked_quantum` | KILLED |
| R7_musttail_too | `musttail` sites eligible | 2363 | 1 | `spec_accept_dropped_arg_musttail_kept` | KILLED |
| R8_no_attr_strip | `range`/`nofpclass` not stripped | 2361 | 1 | `spec_accept_dropped_arg_range_attr_stripped` | KILLED |
| R9_no_intrinsic_skip | front-end intrinsic sites not skipped by the drop | 2361 | 1 | `spec_accept_dropped_arg_reserved_symbol_angle` | KILLED |
| R10_no_deadcall_seeds | unused calls to definitions not seeded | 2361 | 2 | `spec_accept_dead_clone_call`, `spec_accept_dropped_arg_volatile_stale_attrs` | KILLED |
| R11_no_slotB | slot B (after the fenv stages) removed | 2361 | 13 | `spec_accept_dropped_arg_volatile_promoted_residue`, `spec_accept_dropped_arg_volatile_arm_value`, `spec_accept_dropped_arg_volatile_stale_attrs` … | KILLED |
| R12_varargs_too | variadic callees eligible | 2363 | 1 | `spec_accept_dropped_arg_varargs_kept` | KILLED |
| L1_calls_always_roots | every call is a liveness root (round 1's "never a call") | 2361 | 8 | `spec_accept_dropped_arg_volatile_round2_arm`, `spec_accept_dropped_arg_volatile_stale_attrs`, `spec_accept_dead_clone_call` … | KILLED |
| L2_no_frontend_membership | no root by front-end MEMBERSHIP | 2361 | 0 |  | EQUIVALENT since L10: every front-end site's callee name starts with `cq_` (membership ⊂ reserved name); L11 kills |
| L3_no_clone_root | no root by specializer RECORD | 2361 | 0 |  | EQUIVALENT (doubly covered): a clone's name starts with `__cq_` (reserved root) and its body has calls (not body-pure) |
| L4_no_body_purity | no body rule (attributes only) | 2361 | 1 | `spec_accept_dropped_arg_volatile_stale_attrs` | KILLED |
| L10_no_reserved_name | no root by RESERVED NAME | 2361 | 1 | `spec_accept_dropped_arg_reserved_marker_kept` | KILLED |
| L11_no_identity_roots | no identity roots at all (membership, record, name) | 2361 | 2 | `spec_accept_dropped_arg_reserved_marker_kept`, `spec_accept_dropped_arg_reserved_symbol_theta_kept` | KILLED |
| L5_loops_pure | body rule admits cyclic bodies | 2361 | 1 | `spec_accept_dropped_arg_loop_callee_kept` | KILLED |
| L6_no_recorded_dead_slot | the call-slot rule never fires | 2361 | 3 | `spec_accept_phantom_arg_read_theta_source_inplace_mc`, `spec_reject_phantom_arg_read_clone_sweep`, `spec_reject_phantom_arg_read_range_attr` | KILLED |
| L7_no_fold | no empty-arm fold | 2361 | 7 | `spec_accept_dropped_arg_volatile_arm_const`, `spec_accept_dropped_arg_classical_call_arm`, `spec_accept_dropped_arg_volatile_round2_arm` … | KILLED |
| L8_no_phi_fold | no two-entry-φ fold | 2361 | 1 | `spec_accept_dropped_arg_emptied_arm_phi` | KILLED |
| L9_no_block_merge | no merge after the φ fold | 2361 | 1 | `spec_accept_dropped_arg_emptied_arm_phi` | KILLED |
| V1_no_erase_cone | the store erasure leaves its cone | 2361 | 6 | `spec_accept_dropped_arg_volatile_arm_value`, `spec_accept_dropped_arg_volatile_arm_const`, `lowering_volatile_scalar_deadstore_select` … | KILLED |
| V2_no_promote_cone | the promotion leaves its residue | 2361 | 1 | `lowering_volatile_scalar_promoted_residue` | KILLED |
| V3_no_constfold_arm | the const-alloca fold does not fold what it emptied | 2361 | 1 | `spec_accept_dropped_arg_volatile_arm_constfold` | KILLED |
| V4_erase_arm_untouched | the erasure does not report the blocks it emptied | 2361 | 2 | `spec_accept_dropped_arg_volatile_arm_value`, `spec_accept_dropped_arg_volatile_arm_const` | KILLED |
| B1_backstop_off | the backstop never fires | 2361 | 2 | `spec_reject_phantom_arg_read_range_attr`, `spec_reject_phantom_arg_read_clone_sweep` | KILLED |
| B2_no_theta_exempt | no `cq_theta`-result exemption | 2361 | 3 | `lowering_classical_mux_phi_onereg_spec_scrubbed_base_degenerate`, `spec_reseed_theta_source`, `spec_result_classical` | KILLED |
| B3_no_keeper_check | no "kept alive elsewhere" check | 2361 | 1 | `spec_accept_phantom_arg_read_kept_alive` | KILLED |
| B4_ignore_quantum | classical operands declined too | 2361 | 1 | `spec_accept_phantom_arg_read_classical_slot` | KILLED |
| B5_scan_clone_bodies | clone bodies scanned | 2361 | 0 |  | EQUIVALENT by construction: the backstop's quantum test reads MODULE taint, which does not describe clone-body values (probe `nested_clone_phantom.ll`: subject = mutant = oracle stream) |
| B6_no_record | `buildClone` records nothing | 2361 | 3 | `spec_accept_phantom_arg_read_theta_source_inplace_mc`, `spec_reject_phantom_arg_read_range_attr`, `spec_reject_phantom_arg_read_clone_sweep` | KILLED |
| D1_d0_off | M-C arm (d0) off | 2361 | 1 | `spec_accept_phantom_arg_read_theta_source_inplace_mc` | KILLED |
| D2_d0_any_slot | (d0) settles every slot | 2361 | 14 | `lowering_mc_late_fallback_reader_after`, `lowering_mc_late_fallback_measured_chain`, `lowering_mc_late_fallback_terminal_dag` … | KILLED |

**32 KILLED, 3 EQUIVALENT (argued, each with its reason), 0 MISSED** over 35 real mutants + the null.

## R2.11 Per-bead results

| bead | round-2 result (each "TRACE-IDENT" is against the bead's own twin, on the SUBJECT) |
|---|---|
| **vsfp** (P1) | Every F-9C-1 member, every r1A/r1B probe and hgwx's members TRACE-IDENT or oracle-verdict (battery 79 + 5 of 84). The backstop's measured C customer count is ZERO; its IR customers are a slot the CLONE's flatten kills. **Not self-cleared** (§R2.12). |
| **hgwx** (P2) | (d0) asks the specializer's record; `v30` (the "(d0)-blind" spelling) now drops at slot B and is in place like `v30F`; `j02C`/`e02C`/`j01C` TRACE-IDENT. bd jr8q (M-A by-name record) stays open and is now IR-only. |
| **ctz4** (P1, introduced by round 1) | FIXED: `naked1` keeps `m*3` (ORACLE-SAME), `naked2` declines at the inline-asm fence (ORACLE-SAME). Mutant R6 pinned. |
| **m1gi** (P1, introduced by round 1) | FIXED: `prov1`, `bint1–5`, `ctlz1/2` TRACE-IDENT; three intrinsic fixtures + one e2e slice; mutant L1 pinned. |
| **a8q5** (P1, pre-existing) | FIXED: every F-VB-1 spelling TRACE-IDENT with the fenv-intended program, composed v21–v25 too; 12 fixtures + one e2e slice; mutants R11, V1, V2, V3, V4 pinned. |
| **qjoc** (P1, pre-existing) | FIXED: `qjoc`/`qjoc_tpl` TRACE-IDENT; 3 new fixtures + 2 rewritten; the CLAUDE.md sentence FLAGGED to the owner (§R2.6). |
| **F-VA-4 (ediam1/2)** | FIXED, no bead needed: the empty-arm and two-entry-φ folds; `ediam1`/`ediam2` TRACE-IDENT; mutants L7/L8/L9 pinned. |
| **dcar1** (F-VA-3) | FIXED: TRACE-IDENT with its twin (reachable from C; `spec_accept_dropped_arg_dead_loop_cycle.ll`). |
| **resv2** (F-VA-5, M10) | Pinned: `spec_accept_dropped_arg_reserved_symbol_angle.ll` (mutant R9). |

## R2.12 What a Rule-13 round should attack first

Ordered by where a silent miscompile would hide, not by size:

1. **`bodyIsSideEffectFree` (the body rule of the ROOT set).** It makes a call NOT a root although
   its attributes say it may have side effects. Its conjuncts: exact, non-`naked`, non-variadic
   definition; acyclic CFG (`FindFunctionBackedges` empty); no `CallBase` at all; no instruction with
   `mayHaveSideEffects()` or an EH pad; terminators only `br`/`switch`/`ret`. Attack: anything that
   observably happens in a body passing all of these (a trapping load or division is UB in LLVM's
   model, so its deletion is DCE-legal; is there anything else?). Mutant L4 (rule off) is pinned by
   `…_volatile_stale_attrs.ll`, L5 (loops allowed) by `…_loop_callee_kept.ll`.
2. **The dead-call seeding** in the drop. Every unused call to a module DEFINITION is a seed; the
   predicate decides. It deletes whole calls that `-O1` could not see across the TU boundary. Attack
   a call that is unused yet must run: a clone (root by record), a reserved name (root by name),
   `cq_*` sites (root by membership AND name) — and anything else?
3. **The empty-arm folds** (`deleteDeadCones` step 4): the `select` created from a two-entry φ on
   a TAINTED condition becomes a 4.4 data select before detection (the `ediam2` shape; its twin is
   exactly that select). The fold also runs on arms the fenv stages emptied (caller-touched blocks)
   and on a PRE-EXISTING empty arm whose common successor the deletion touched (the candidate set
   includes predecessors of touched blocks) — i.e. it can rewrite a shape `-O1` left, when `-O1`'s φ
   fold hit its cost limit. Attack the φ-availability argument, a merge with a third predecessor,
   and loops (an arm that is a latch).
4. **Slot B's window** (stages 3–7 between the two drops): the claim that no stage in it records
   an SSA value slot B deletes, and that the fenv stages' own deletions are dead by the predicate.
5. **The clone record's timing** (`buildClone`, after control flatten and inner retarget, before
   `lowerCloneSelect`/`lowerOps`): a clone pass after the record that ADDS a read of a slot recorded
   dead would make (d0) and the backstop unsound. We found none; the record is keyed by clone
   `Function*` in a `ScrubMap` (scrub selftest extended).
6. **(d0)**: a slot recorded dead in which the clone still performs a DEAD computation (lowered as a
   forward template + its `_unc` inside the Bennett wrap) — the argument is that it is an identity on
   the operand before the call returns. Check it against a clone whose wrap does NOT uncompute
   everything (any clone path that leaves a rail).
7. **The backstop's "kept alive elsewhere"** — runtime `cqrt_*`/`cq_template_*` users are not keepers,
   so an over-decline is possible where an emitted gate genuinely reads the phantom operand and
   nothing else does (named, not constructed). And the one exemption (`cq_theta` result).
8. **The CLAUDE.md fenv sentence** (§R2.6) is an owner question, not a reviewer one — but a reviewer
   should confirm the two counter-examples on the oracle.

---

# ROUND 3 (2026-09-26) — taint freshness, the phantom read NEUTRALISED, the global fold's arm

Both Rule-13 rounds on round 2 (`0a485382`) were **NOT-CLEAR** (`review_r2A_vsfp/REVIEW.md`: F-WA-1..5,
bd `otam`; `review_r2B_vsfp/REVIEW.md`: F-WB-1..5, bds `tzfa`, `stl3`; committed unmodified at
`0979276f`). What held, by their own account: the body-purity rule, user gates never deleted, the
empty-arm fold's CFG surgery, the passthrough, `SpecDeadArgMask`'s soundness, (d0), the 84-pair battery
and the 9bhg composition. **NOT self-cleared**: round 3 owes its own Rule-13 round (§R3.12).

Measurement scope was set by the owner for this round (lighter): full `lit ir-pass/test`, targeted
`ctest -R` for touched/added entries, every probe of both round-2 reviews + the round-1 vsfp reviews +
r2A_9bhg against its twin, a corpus A/B vs the ORACLE over lit + e2e + multi-TU + those review probe
dirs only, ≤8 mutants for the new/changed predicates plus a null, `update_code_map.py --check`. **No full
ctest, no allocator sweeps, no 9bhg composition** (it runs at the 9bhg merge).

| tag | what | `cq-opt` |
|---|---|---|
| ORACLE | `main` `aee8f4f8` | `69250feaf68bbe49` |
| ROUND 1 | `5e56060b` | `73fd07592c4960dd` |
| ROUND 2 | `0a485382` | `d17c95e8353711b1` |
| SUBJECT | round 3, final | `3cb890ef25187b4b` (`libCQPass.so` `2764c64abcc871bc`, `cq-opt-debugalloc` `ce5fbf89cd8f5f82`) |

Build null controls: the mutation worktree `mutwt3` (detached at `0979276f`, round-3 sources synced)
built the SUBJECT's exact `cq-opt` hash before any mutation, and the null mutant N0 (a comment) rebuilt
to it again; every comment-only edit after the measurements rebuilt the SUBJECT to the same hash.

## R3.1 Ledger

| id | sev | disposition | pins |
|---|---|---|---|
| F-WA-1 (otam) | P1, introduced | every volatile stage re-`propagate`s when it changed the IR (both entry points); `declineStaleTaintSet` re-derives the set before `detectSpecializations` and declines loudly on any difference (§R3.2) | `lowering_volatile_arm_fold_{repropagate,repropagate_addc,repropagate_escape,repropagate_loop,stale_taint_redgreen}.ll`, `lowering_volatile_constfold_arm_repropagate.ll`, e2e `…-volatile-arm-fold-repropagate` (+ twin-identical) |
| F-WA-2 | P2 | the three false claims corrected at the source (`QramLowering.h` ×3 headers incl. the global fold's, `CQLoweringPass.cpp` slot A and the three call sites) and marked in §R2.4 | — |
| F-WA-3 | P2 | mutation rows O1/O2/O4 added and KILLED (§R3.10) | the otam fixtures |
| F-WA-4 | P3 | named in the dead shim's AXIS-F hazard list (the drop, the resolution; the F-scoped intrinsic skip) | — |
| F-WA-5 | P3 | noted; no action (this round's scratch dirs are `r3p/`, `e2e3/`, `mutwt3/`) | — |
| F-WB-1 (tzfa) | P1 | `resolvePhantomCloneArgReads` NEUTRALISES every recorded-dead slot, then declines a quantum operand the user program no longer reads (§R3.3) | `spec_accept_phantom_arg_read_template_reader.ll`, `spec_reject_phantom_arg_read_unread_{select,template}.ll`, the four re-derived phantom fixtures, e2e `…-volatile-global` (+ twin-identical) |
| F-WB-2 (stl3) | P2 | `foldVolatileConstGlobalLoads` gets the empty-arm fold (+ the otam re-propagate); `deleteDeadCones` seeds the condition after every fold (a φ of EQUAL incomings left a dead TAINTED compare lowered as a dirty flag) (§R3.4) | `spec_accept_dropped_arg_volatile_global_{arm,expect,phi,oracle}.ll` |
| F-WB-3 | P3 | `cloneArgReachesResult` asks `isRecordedDeadSlot` (Rule 14); both false comments rewritten (`ArithLowering.cpp` (d0), `RotationLowering.cpp`) | `spec_accept_phantom_arg_read_measured_record.ll` (NOWARN) |
| F-WB-4 | P3/owner | r2B's replacement sentence and counter-examples recorded for the owner (§R3.8); CLAUDE.md NOT edited | — |
| F-WB-5 | P3 | a bd 9bhg-alone note; the composition is not run this round (brief) | — |

## R3.2 bd otam — taint freshness across the pre-pass window

**The defect** (r2A F-WA-1). Round 2 gave `foldVolatileConstAllocaLoads` and
`eraseDeadVolatileScalarStores` the arm fold (`deleteDeadCones(…, Emptied)`). Its two-entry-φ fold
creates `select Cond, vT, vF`; with a TAINTED `Cond` that select is a NEW tainted value (a φ of
classical incomings is not tainted by data flow; the select is, through its condition). Both call
sites ignored the stage's return, so `taint.Tainted` stayed stale until some unrelated stage happened
to re-propagate — and when none did, control detection (keyed on the tainted condition) still claimed
the select and RAUW'd it to its `%out` handle while every taint consumer saw it classical: a rail
handle passed to classical `f`, a user `cq_measure` lowered as a never-quantum measure (vanished),
classical arithmetic on handles across a loop's back edge. Exit 0, 0 bytes of stderr, 2b clean.

**The fix, in two parts, and why not one "re-propagate at the end".**
1. **Per stage** — `if (stage(M, taint)) taint = propagate(M, wd);` for the global fold, the alloca
   fold and the store erasure, in both entry points. This is the window's existing uniform rule
   (every other pre-pass already did it); the three volatile stages were the only exception, because
   their headers said "classical, so taint is unaffected" — true of the folded value, false of the arm
   fold behind it.
2. **One postcondition** — `declineStaleTaintSet(M, wd, taint)` (TaintPropagation.{h,cpp}) right
   before `detectSpecializations`, i.e. after the last pre-pass and before the first guard: it runs a
   fresh `propagate` and declines (`cq lowering: taint set is stale after a pre-pass …`) on ANY
   difference, in either direction.

A single re-`propagate` at the end of the window, with no per-stage rule, would NOT be a fix: every
stage between the volatile folds and the end reads `taint.Tainted` (the promotion's taint gate, slot
B's front-end skip, PredMux's region claim, the unroller and the ctlz recogniser are all taint-driven),
so they would still run on the stale set — and it would silently repair the set below, hiding the
omission. A silent end-of-window re-`propagate` repairs; the check REFUSES. With the per-stage rule
the window is fresh; with the check, the NEXT stage that grows taint and forgets is a loud decline,
not a miscompile — which is what "it cannot recur for the next stage" can honestly mean. What the
check cannot see is a stale window a LATER stage's own re-`propagate` already repaired (stated at the
declaration).

**Contract written where the next caller will read it** (L8): `DeadValueLiveness.h`'s
`deleteDeadCones` now carries "THE CALLER'S OBLIGATION — THIS FUNCTION CAN GROW THE TAINT SET", and
each volatile stage's header says so.

## R3.3 bd tzfa — the phantom read NEUTRALISED

**The defect** (r2B F-WB-1). Round 2's backstop exempted an operand "kept alive elsewhere" and then
ACCEPTED with the phantom clone call still in the operand's use list. The phantom read did not keep
the rail alive — it kept the uncompute SPINE from discharging it: `p = q * 3` had two consumers (the
oracle's `xor` and the clone call), so the spine left `p`'s template rail dirty, a complete which-path
record of `q` across `Ry(0.7)` (`k19`: the oracle's phase erased; the ORACLE emits the same stream;
round 1 declined).

**The fix** — `resolvePhantomCloneArgReads` (Specialization.{h,cpp}), same slot (last in the
post-`specialize()` decline chain, before `lowerRotations`, both entry points):
1. **Neutralise.** Every slot the specializer RECORDED dead (`isRecordedDeadSlot`, the one predicate's
   record) of every call to a clone in a non-clone function gets `Constant::getNullValue` — the drop's
   rewrite, `range`/`nofpclass` stripped. From then on no stage — terminal selection, free points,
   M-C, M-A's hop walk, stage 2b — can see the read.
2. **Decline what the twin does not compute.** A neutralised operand that is QUANTUM (tainted, or a
   control-emitted rail) and that the user program no longer reads (`userProgramReads`: a
   `cq_measure`, a `cq_theta` arg-0, a clone read slot, a `ret`, a control-emitted runtime call on a
   USER value, or a live instruction) is something only the phantom built — a 4.4 `%out` rail no
   stage uncomputes, or a dead tainted op the spine does not uncompute. Declined. The one exemption
   stays: a `cq_theta` RESULT (the user's register; r1B's nine shapes).

**Why one rewrite rather than an exemption in the spine** (the brief asked for "the spine … must
treat a RECORDED-DEAD clone slot read as NOT a use — use the one shared predicate"). The neutralisation
IS that, for every consumer at once: it asks `isRecordedDeadSlot` once, at the one point the record
exists, and removes the read, so the spine's terminal selection, `FreePoint`, M-C (d0), M-A and 2b need
no exemption of their own. An exemption per consumer is the L3-mirror hazard (a consumer that forgets
it re-opens bd tzfa with no diagnostic). Soundness rests on the record: the clone never reads the slot
(r2B verified the record and that no later clone pass adds a read), so the constant is unobservable
— including through the clone's `_unc` twin, a verbatim copy of the same body.

**What stays declined, IR-only** (the C spellings now drop at slot B, §R3.4): a phantom operand
minted ONLY for the call (`k1` branch-only → `spec_reject_phantom_arg_read_unread_select.ll`) and a
dead tainted op read only by the call (`k3` branch-only → `…_unread_template.ll`, where `-O1` rewrote
`p + 1 == 7` to `q == 2`). Both are over-declines against their twins. The second could become the
twin by deleting the dead op, which is not done post-`specialize()` (plan structures hold raw
pointers there) — named, not built. ⚠ Also named, not constructed: a control-emitted rail
(`%out`) read ONLY by a later control-emitted compare is counted as unread (the emitter's traffic on
its own rail is treated as construction, since telling a read from a write needs the runtime ABI's
slot semantics) — an over-decline.

(d0) is unchanged and now has no MODULE-level population (a neutralised call is not a user of the
operand); it stays the one spelling of the question for an inner clone call inside a clone body.

## R3.4 bd stl3 — the global fold's arm, and a φ of equal incomings

`foldVolatileConstGlobalLoads` was the one volatile fold without the empty-arm fold (r2B F-WB-2: an
L2 omission — the set of stages given the fold was widened by three and this sibling was left out).
It now records, per function, the blocks it empties and calls `deleteDeadCones(F, {}, taint,
"volatile-globalfold", Blocks)`, and re-`propagate`s on a true return (the otam rule). A second defect
is in `deleteDeadCones`: after a fold whose φs all had EQUAL incomings (`(a > 3) ? K : 0` with
`K == 0`) it seeded the condition's cone only when NO φ was left. ⚠ For `g13` (a CLASSICAL condition
in the callee) that is cleanup only — a dead compare keeps no parameter live under liveness, and
mutant S2 passes `g13`'s fixture — and the first draft of this paragraph, and of the source comment,
said otherwise (L7, caught before commit by reading S2's result). Where it is load-bearing is a
TAINTED condition: `int r = (q > 3) ? K : 0;` in `main` leaves a dead tainted compare that is lowered
as a forward template and never uncomputed — a dirty flag across the later Ry (S2 was MISSED by the
whole suite until `lowering_volatile_globalfold_equal_phi.ll` pinned it, §R3.10). The condition is
now seeded after every fold (a condition a new `select` reads is live, and the recursive call deletes
nothing).

## R3.5 F-WB-3 — the third "slot unread"

`RotationLowering.cpp`'s `cloneArgReachesResult` asked `Argument::use_empty()` of the clone parameter
— a third spelling of the question beside the record (Rule 14). It now asks `isRecordedDeadSlot` (no
record → no hop, the decline direction), which also closes its old stated IR residual (a parameter
read only by a stripped in-body compare: the record calls it dead). With the neutralisation in front
of it, no module-level dead-slot read reaches M-A at all; the warning on r2B's `k5` (and `d1`/`d4`)
is gone (`spec_accept_phantom_arg_read_measured_record.ll`, NOWARN prefix; that fixture warns on
round 2). Both false comments rewritten at the source.

## R3.6 F-WA-2 — the falsified claims, corrected at the source

- `QramLowering.h`: the alloca fold's "folded values are CLASSICAL, so taint is unaffected and no
  re-propagate is needed" → marked FALSE with bd otam's mechanism; the global fold's same sentence
  (the precedent it cited) rewritten; the store erasure's header now states the caller's obligation.
- `CQLoweringPass.cpp` slot A: "It SHRINKS the taint set and grows nothing" → marked false; the
  conclusion (a plain `propagate` is the whole obligation, pre-guard) kept on the right ground.
- This file: §R2.4's L1 rows (5)/(6) and SLOT A marked inline; §R2.5's "C-reachable customer count
  zero" marked FALSE; §R2.5 marked SUPERSEDED.

## R3.7 L1 stage table, re-asked

| stage | grows taint? | obligation discharged by |
|---|---|---|
| SLOT A drop (+ cone + arm fold) | YES (a `select` on a tainted condition) | its own `propagate` on a true return (pre-guard) |
| by-ref inline, rail bank, bank marks | yes (existing) | their own fixpoint `propagate`s (unchanged) |
| `foldIdentityBitcasts` | no (RAUW to the operand; scrubs its own) | — |
| global volatile fold (+ arm fold, NEW) | YES | `propagate` on a true return (NEW) |
| alloca volatile fold (+ arm fold) | YES | `propagate` on a true return (NEW — bd otam) |
| store erasure (+ cone + arm fold) | YES | `propagate` on a true return (NEW — bd otam) |
| volatile promotion (+ residue + arm fold) | yes | its fixpoint `propagate` (unchanged) |
| SLOT B drop | YES | its own `propagate` on a true return (unchanged) |
| fp80, PredMux, unroll, ctlz | yes (existing) | their fixpoint `propagate`s (unchanged) |
| **window end** | — | **`declineStaleTaintSet`: fresh `propagate` ≠ carried set → DECLINE** |
| `resolvePhantomCloneArgReads` (post-`specialize()`) | no (rewrites an argument to a constant; no new value, no taint change) | — ; it runs after every guard and before `lowerRotations`/`lowerOps`/`uncompute`, whose consumer sets it corrects |

## R3.8 The fenv sentence — for the OWNER (CLAUDE.md not edited)

CLAUDE.md "Scope of the semantic model — `fenv` is OUT" says: *"with **no** enclosing tainted control
flow the dead product IS lowered, uncomputed and freed; inside a PredMux region it is deleted outright.
Both are sound; they are not the same circuit."* Neither half held before bd vsfp round 2, and after it
there is no asymmetry. Counter-examples, all measured by Rule-13 r2B (F-WB-4) on the ORACLE vs the
subject:

- `qjoc` — `int p = b ? 9 : 4; volatile int z = p; …; b = cq_theta(b, .7)` (a dead 4.4 SELECT): the
  ORACLE mints the select's `%out` which-path rail and never discharges it — silent dephasing, no
  warning. Subject: TRACE-IDENT with the program without the volatile line.
- `qjoc_tpl` — `int p = q * 3; volatile int z = p; …; q = cq_theta(q, .7)` (a dead TEMPLATE product
  whose source is later rotated): the ORACLE leaves `mul_i32_hl` DIRTY (a lyyf warning). Subject:
  TRACE-IDENT.
- `f1` — `int p = q * 3; volatile int z = p; … return cq_measure(q)` — the first half is false even
  WITHOUT a later non-diagonal gate: the ORACLE emits `cq_template_mul_i32_hl(h0, 3)` and no `_unc`
  (2b CENSUS `1 left dirty`). Only the ruling fixture's own `fmul r*r` happened to be uncomputed.
- `f5` — `if (b) { volatile int z = q * 3; }` with `b` tainted: the ORACLE DECLINES (`operand predates
  a non-diagonal gate`), not "deleted outright". Subject: TRACE-IDENT.

**r2B's suggested replacement (report only):** *"The erasure deletes the stored value's DEAD CONE by
liveness (`deleteDeadCones`), so the product is deleted whether or not it sits in a PredMux region;
there is no asymmetry. What survives is only what is live for another reason, or a liveness root (a
front-end `cq_*` site, a reserved-namespace or specializer-built call, or a call whose callee body is
not provably side-effect-free and terminating). Before bd vsfp round 2 neither half held: the
no-control-flow product was lowered and in general NOT uncomputed (a Rule-8 wrong unitary once its
source takes a non-diagonal gate, silently for a dead 4.4 select), and the PredMux case could
decline."* The ruling itself is not in question.

## R3.9 Fixtures and e2e

`ls ir-pass/test/*.ll | wc -l`: **2378** (round 2: 2363). Round 3 added **15** fixtures and changed
**8** (a family of 23). Generated by `vsfp_probes/r3/tools/mkfix3.py` (round 2's derivation: the exact
ordered runtime/clone call sequence of the quantum function, SSA names wildcarded; a NEG prefix for
every callee the ORACLE emitted there and the subject does not; the drop census). One added verbatim:
r2A's `fwa1_stale_taint_redgreen.ll` as `lowering_volatile_arm_fold_stale_taint_redgreen.ll` — ⚠ an
INTENTIONAL duplicate body of `lowering_volatile_arm_fold_repropagate.ll` (the L8 duplicate-body scan,
`vsfp_probes/r2/tools/dupscan.py`, finds exactly this pair among round 3's files; both ACCEPT, one pins
the exact stream, the reviewer's pins clone + measure).

**Red-green, measured** (`tools/redgreen3.sh`, the scratch lit site config pointed at each binary),
over the 23-file family: ORACLE 0 PASS / 23 FAIL; ROUND 1 2 / 21; ROUND 2 2 / 21; SUBJECT 23 / 0. The 2
green on rounds 1 and 2 are the two new DECLINE fixtures (`…_unread_{select,template}.ll`), which those
rounds declined with the same string (they are pins of the decline direction against mutant T2, and
RED on the oracle, which accepts them dephased).

Four changed CHECK lines only (`spec_result_classical.ll`, `spec_reseed_theta_source.ll`,
`lowering_classical_mux_phi_onereg_spec_scrubbed_{base_degenerate,elsewhere}.ll`): their clone call's
dead slot now reads `0`; each carries a note. Four phantom fixtures re-derived with new headers
(`theta_source`, `theta_source_inplace_mc`, `classical_slot`, `kept_alive`).

**e2e, 6 new entries**: `e2e-slice-spec-dropped-arg-volatile-global` (2-TU, r2B `k19`, lib
`spec_dropped_arg_volatile_global_lib.c`) + `…-twin` + `e2e-spec-dropped-arg-volatile-global-twin-identical`;
`e2e-slice-volatile-arm-fold-repropagate` (r2A `stale3c`) + `…-twin` +
`e2e-volatile-arm-fold-repropagate-twin-identical`. Both subjects are TRACE-IDENT with their twins on
the SUBJECT (14 and 21 lines); on ROUND 2 the first is 12 lines with a dirty template rail and a
warning and the second 12 lines with no clone and no measure (both RED); on the ORACLE the first is
round 2's wrong stream and the second declines; on ROUND 1 both decline (`tools/mkgold3.py`).

## R3.10 Mutation matrix (full lit per mutant, `lit --timeout 60`)

Brief: mutants ONLY for the new/changed predicates, ≤8, plus a no-op null. `tools/mutants3.py` in the
scratch worktree `mutwt3` (its base build hashed BIT-IDENTICAL to the SUBJECT); anchor found exactly
once or abort; each mutant builds its OWN `cq-opt` and `cq-opt-debugalloc`; a binary equal to the
SUBJECT is refused (stale / compiled away) and a null that is NOT equal aborts. `tools/mutmatrix.sh`
(full lit per mutant through the scratch site config, `lit --timeout 60`, no debugalloc default). The
eight real mutants ran over 2377 fixtures; after the equal-φ fixture was added (below), N0, S2 and O3
ran again over 2378.

| mutant | removes | failed | killed by | verdict |
|---|---|---|---|---|
| N0_null | nothing (a comment); binary = SUBJECT `3cb890ef25187b4b` | 0 / 2377, 0 / 2378 | — | null |
| O1_no_erase_repropagate | the re-`propagate` after the store erasure (bd otam) | 5 | `lowering_volatile_arm_fold_{repropagate,repropagate_addc,repropagate_escape,repropagate_loop,stale_taint_redgreen}` — now through the POSTCONDITION's decline | KILLED |
| O2_no_constfold_repropagate | the re-`propagate` after the alloca fold (bd otam) | 1 | `lowering_volatile_constfold_arm_repropagate` | KILLED |
| O4_round2_stale | both: no erase re-`propagate` AND no postcondition (round 2's behaviour) | 5 | the same five — now as the round-2 MISCOMPILE (no clone, no measure) | KILLED |
| O3_no_postcondition | `declineStaleTaintSet` alone | 0 / 2377, 0 / 2378 | — | **EQUIVALENT by construction**: a backstop, and every stage in the window re-propagates, so no module reaches a stale set; O1 vs O4 shows it is the postcondition that turns the omission into a decline |
| S1_no_globalfold_armfold | the global fold's arm fold (bd stl3) | 4 | `spec_accept_dropped_arg_volatile_global_{arm,expect,phi,oracle}` | KILLED |
| S2_condseed_nophi_only | the condition seed after a fold with φs (round 2's rule) | **0 / 2377 — MISSED**, then 1 / 2378 | `lowering_volatile_globalfold_equal_phi` | KILLED after a new fixture ⚠ |
| T1_no_neutralise | the neutralisation (bd tzfa) | 14 | `spec_accept_phantom_arg_read_template_reader`, `…_measured_record`, the four re-derived phantom fixtures, the four CHECK-line fixtures, and all four decline fixtures (`…_unread_{select,template}`, `…_range_attr`, `…_clone_sweep`: without the rewrite the phantom clone call is itself a "reader", so nothing is declined) | KILLED |
| T2_no_unread_decline | the decline of an unread quantum operand (bd tzfa) | 4 | `spec_reject_phantom_arg_read_{unread_select,unread_template,range_attr,clone_sweep}` | KILLED |

**7 KILLED, 1 EQUIVALENT (argued), 0 MISSED** after one gap was found and closed: **S2 was MISSED
over the whole 2377-fixture suite**. The condition seed looked cosmetic for the dead-argument drop
(a dead compare does not keep a parameter live under liveness), and it is — but in a MODULE-level
tainted diamond it is not: `int r = (q > 3) ? K : 0;` with `K == 0` folds to an equal-incoming φ, and
without the seed the dead TAINTED compare is lowered as a forward template and never uncomputed — a
dirty which-path flag across `Ry(0.7)` on `q` (measured on S2: TRACE-DIFF, 1 dirty template rail, a
warning). `lowering_volatile_globalfold_equal_phi.ll` now pins it (RED on S2, GREEN on the SUBJECT;
the ORACLE and round 2 declined the program, an over-decline). Mutation found a missing fixture,
which is what it is for.

Not mutated (brief ≤8), argued instead: `cloneArgReachesResult`'s record-based test (F-WB-3) — with
the neutralisation in front of it no module-level call passes a value in a recorded-dead slot, so a
`use_empty()` revert is expected EQUIVALENT; its warning-parity pin is the neutralisation's
(`…_measured_record.ll`, killed by T1).

## R3.11 Measurements (commands under `vsfp_probes/r3/tools/`; ⚠ the battery's ROUND 1/2 and ORACLE runs predate the `eqphi` pair)

All on SUBJECT `3cb890ef25187b4b` unless stated. Every A/B ran its null control FIRST on the same list.

**Layers run, literally** (the owner's round-3 scope — no full `ctest -j6` on the branch):
- `cmake --build build -j8` (all targets); `cd build && lit ir-pass/test` → **2378 discovered, 2377
  passed, 1 XFAIL** (56 s).
- `ctest --test-dir build -R "spec|twin-identical|multi|scrub|libm-ld80-next|volatile|free-pairing-selftest|cq-opt-equivalence$|taintset" -j6`
  → **99/99 passed** (every `spec` e2e slice incl. the 6 new entries, all 54 `*-twin-identical`
  gates, the multi-TU slices, the `libm-ld80-next*` slices the volatile stages touch,
  `taintset-scrub-guard` (+ selftest), `ir-pass-scrub-on-delete-selftest-*`,
  `e2e-free-pairing-selftest`, and the SAMPLED `cq-opt-equivalence` — the full sweep was not run).
- `python3 tools/update_code_map.py --check` → clean (regenerated).

**The battery** (`tools/r3bat.py TAG`, 176 rows: round 2's 79 pairs + 5 singles — r1A/r1B vsfp,
r2A_9bhg F-9C-1, hgwx — plus EVERY probe of r2A_vsfp and r2B_vsfp (88 pairs + 4 singles), each against
its hand-inlined or fenv-intended twin; verdicts memoised per (binary, probe) so twins shared by many
pairs are built and run once):

| binary (rows) | TRACE-IDENT | DECL-SAME | ORACLE-SAME | TRACE-DIFF | VERDICT-DIFF | DECL-DIFFSTR | ORACLE-DIFF |
|---|---|---|---|---|---|---|---|
| SUBJECT (176) | **151** | 5 | 6 | 3 | 7 | 1 | 3 |
| ROUND 2 (175) | 122 | 3 | 6 | 17 | 23 | 1 | 3 |
| ROUND 1 (175) | 40 | 4 | 5 | 42 | 74 | 6 | 4 |
| ORACLE (175) | 16 | 2 | 9 | 77 | 65 | 6 | 0 |

The SUBJECT's 19 non-identical rows, each attributed: **identical on ROUND 2, ROUND 1 and the ORACLE
(pre-existing, the same class on all four binaries)** — `g4A/B`, `g5A/B`, `g11A/B` (callee declines at
spec: vector lane / nested call / tainted control flow), `threepred` (r2A: a three-predecessor merge,
safe-direction over-decline), `f6` (DECL-DIFFSTR), `g12A/B` (TRACE-DIFF, `g12B` with a warned dirty
rail — FILED bd `test_C_libtooling-50ho`: the volatile folds do not constant-fold the users of the
folded load); **equivalent by reading** — `k9` (the twin's `-O1` folds `p + 1` into the select's arms,
`select(b, 10, 5)`, where the subject adds 1 in place to `select(b, 9, 4)`; round 2 had a dirty rail
here, round 3 has none); **the twin's own verdict** — `f2`, `loop2`, `stale1`, `stale3a`, `stale7`
(DECL-SAME); **round-2 D→A classified by hand twins in round 2** — the singles `m_s_f32`, `m_s_f80`,
`r1b_v26vsel` (ORACLE-DIFF: the oracle declines; unchanged round 2 → 3).

Named results: r2A `stale3b`, `stale3c`, `stale4`, `stale5` TRACE-IDENT; `stale3a`, `loop2`
DECL-SAME (bd otam). r2B `k8`, `k14`, `k18`, `k19`, `k24` TRACE-IDENT with 0 dirty template rails,
equal to the twin (bd tzfa); `k1`, `g9A/B`, `g13A/B`, `k3`, `k4`, `k12`, `k13` TRACE-IDENT (bd stl3);
`k5`, `d1`, `d4` TRACE-IDENT with 0 warnings (F-WB-3); `k11` TRACE-IDENT with a fully inlined twin
`k11H` (r2B's `k11F` inlines only the first call and keeps an external `h`, so it declines); `d3`, `e5`,
`k15`, `k21` — which r2B recorded as declining on every binary — now TRACE-IDENT (the global fold's
arm fold removes the read that made the clone contain tainted control flow / the loop carry a
tainted value).

**Corpus A/B** (`tools/ab.py`; `tools/buildcorp3.py`), denominator **3440** = lit 2377 + review-probe
modules 633 (every `.c` with its `.lib.c` and every stage-1 `.ll` of `review_r1A_vsfp`,
`review_r1B_vsfp`, `review_r2A_vsfp`, `review_r2B_vsfp`, and bd 9bhg's `review_r2A_9bhg`) + e2e
single-TU 400 + multi-TU 30:

| A → B | movers | A→D | D→A | DIAG | STREAM |
|---|---|---|---|---|---|
| SUBJECT → SUBJECT (null) | **0** | | | | |
| ORACLE → SUBJECT | 369 | 5 (lit) | 177 (lit 11, e2e 1, probes 165) | 16 (lit 2, probes 14) | 171 (lit 48, multi-TU 6, probes 117) |
| ROUND 2 → SUBJECT | 76 | 6 (lit 2, probes 4) | 21 (lit 3, probes 18) | 0 | 49 (lit 15, e2e 1, multi-TU 1, probes 32) |

- **Every lit / e2e / multi-TU mover is a file this branch touched since `main`** (`tools/litmov3.py`
  over `git diff --name-only aee8f4f8` + the working tree: 0 UNTOUCHED).
- **Every one of the 76 ROUND 2 → SUBJECT probe movers is a battery subject or twin**, all TRACE-IDENT
  or DECL-SAME with its twin: the otam exhibits (A→D `stale3a`, `loop2` ×2 each — now the twin's
  decline; STREAM `stale3b/3c/4`, r2A's red-green `.ll`), the stl3/tzfa members, the F-WB-3 warning
  rows (d1/d2/d4/e1–e8 STREAM: the neutralisation removes a clone read), and the literally inlined
  T-twins `k2T`–`k5T`, `k1T`, which now accept TRACE-IDENT with the fenv twins (the global fold's arm
  fold in `main`).
- **The 296 ORACLE → SUBJECT probe movers** (`tools/classify3.py`, mechanical): r2A/r2B_vsfp modules →
  their battery row (81 TRACE-IDENT/DECL-SAME/ORACLE-SAME, `k9` equivalent above, the 3 singles above,
  `purity2.ll` — r2A's body-purity IR probe, trace-identical to round 2 and reviewed by r2A — and
  `m_s_f64H`, a hand twin whose TRACE equals the oracle's); r1A/r1B_vsfp and r2A_9bhg modules that did
  NOT move round 2 → 3 keep round 2's twin classification (a round-2 stream): 187 TRACE-IDENT/DECL-SAME
  (auto or hand) and 12 rows round 2 classified by hand (§R2.9: `v08c/d/e`, `qjoc`, `v01T`, `v02T`,
  `v16b`, `g3C`, `g4C`, `s_f*T`). **0 unclassified.**
- The new decline string (`taint set is stale …`) fires on **0** of 3440 modules (no mover carries it, and the ORACLE cannot emit it, so a module that did would be a mover).

**Red-green** of the 23-file round-3 family (`tools/redgreen3.sh`): ORACLE 0 / 23 PASS, ROUND 1 2 / 23,
ROUND 2 2 / 23, SUBJECT 23 / 23 (the 2 green on rounds 1–2 are the new decline fixtures, which those
rounds declined with the same string).

## R3.12 Per bead

| bead | round-3 result (TRACE-IDENT is against the bead's own twin, on the SUBJECT) |
|---|---|
| **otam** (P1, introduced by round 2) | FIXED: per-stage re-`propagate` + the `declineStaleTaintSet` postcondition. `stale3b/3c/4/5` TRACE-IDENT, `stale3a`/`loop2` DECL-SAME; 7 fixtures + 1 e2e slice (+ twin, + gate) RED on round 2; mutants O1/O2/O4 KILLED, O3 equivalent (a backstop). |
| **tzfa** (P1, re-admitted by round 2) | FIXED: `resolvePhantomCloneArgReads` neutralises every recorded-dead slot, then declines an unread quantum operand. C members `k8/k14/k18/k19/k24` TRACE-IDENT with 0 dirty template rails; IR-only branch-read spellings TRACE-IDENT (`k19/k8/k24/k5/k7/k2`) or DECLINED (`k1`, `k3`: rails the twin never computes — named over-declines). Mutants T1/T2 KILLED. |
| **stl3** (P2) | FIXED: the global fold's arm fold (+ re-propagate) and the condition seed after every fold. `k1`, `g9A/B`, `g13A/B`, `k3`, `k4`, `k12`, `k13` TRACE-IDENT; `d3`, `e5`, `k15`, `k21`, `k11` now accept TRACE-IDENT too. Mutants S1 KILLED, S2 KILLED after a new fixture (`…_globalfold_equal_phi.ll`). |
| **vsfp** (P1) | round 3's changes above; F-WB-3's third "slot unread" spelling routed through the record; all falsified claims corrected at the source. The C route to the phantom-read resolution is now closed as far as measured (the four volatile folds all fold what they empty); what reaches it is IR-only. NOT self-cleared. |
| **50ho** (NEW, P2, pre-existing) | r2B `g12A/B`: the volatile folds do not constant-fold the users of a folded load (`K - 7` survives), so the clone reads a parameter the twin's `-O1` sees as ignored — TRACE-DIFF (g12B with a warned dirty rail), identical on the ORACLE, round 1, round 2 and round 3. |

## R3.13 What a Rule-13 round should attack first

1. **`resolvePhantomCloneArgReads`' neutralisation.** It rewrites an argument AFTER every guard and
   after `specialize()`, relying on the specializer's record being exact for the built clone and on no
   later clone pass adding a read (r2B checked the passes; attack a clone built twice, a clone called
   from another clone's `_unc` twin, a clone whose dead slot feeds an inner clone call, fp-ABI clones).
2. **`userProgramReads`' reader list** — the decline's complement. It counts a control-emitted runtime
   call on a USER value as a reader and skips every runtime call on an EMITTER rail. Attack: a
   runtime call that consumes a user value without keeping it (so a phantom-only value is accepted and
   left dirty), and an emitter rail genuinely read by a later gate (the named over-decline).
3. **`declineStaleTaintSet`'s blind spot**: a stage in the window that reads a stale set BEFORE a
   later stage's re-`propagate` repairs it. Find one reachable from C.
4. **The condition-seed change** (seed after every fold): a condition read by a new `select` must be
   live — check the recursive `deleteDeadCones` never deletes it, including when the select is itself
   dead and later swept.
5. **The global fold's arm fold** runs on EVERY function of the module, tainted or not; a two-entry φ
   under a tainted condition becomes a select that control detection then claims as a 4.4 select —
   check a case where the original `-O1` shape declined for a reason the select does not have.
