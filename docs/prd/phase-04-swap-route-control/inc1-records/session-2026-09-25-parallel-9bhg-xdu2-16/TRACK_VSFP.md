# Track vsfp — a callee parameter with no uses is not an argument (bd vsfp + bd hgwx)

Session 2026-09-26. bd `test_C_libtooling-vsfp` (P1 SILENT DEPHASING, pre-existing, population
grown by bd 9bhg) and its warned sibling bd `test_C_libtooling-hgwx`. Found by the bd 9bhg Rule-13
round r2A (`review_r2A_9bhg/REVIEW.md` F-9C-1) and, for hgwx, bd d88e's r1B (F-DB-1).

- Worktree branch: `worktree-agent-abf65d7dcfbff38c8`, based on `main` `aee8f4f8`.
- **NOT self-cleared.** This is a Rule-13 change (TaintPropagation-adjacent orchestration, M-C's
  G7, a new post-`specialize()` decline). §10 is the attack list for the rounds.

Binaries (sha-256 prefixes):

| tag | what | `cq-opt` |
|---|---|---|
| ORACLE | `main` `aee8f4f8`, frozen (`frozen/cq-opt.main_aee8`) | `69250feaf68bbe49` |
| SUBJECT | this branch, final | `73fd07592c4960dd` (`libCQPass.so` `11e9c571a4314fcf`, `cq-opt-debugalloc` `c8b735ca1c9e3e52`) |
| COMPOSED | this branch merged with bd 9bhg `f2148d0a` (scratch, removed) | `e29f68ce5298dedc` |

Build null control: a fresh build of the unmodified worktree hashed BIT-IDENTICAL to the frozen
ORACLE before any edit, and the mutation worktree's comment-only null mutant M0 rebuilt to the
SUBJECT's exact hash.

Probes, fixture sources, scripts and results are under `vsfp_probes/` (`src/{own,fx,ll}`, `tools/`,
`results/`). The scripts carry this session's scratchpad paths and say so; `tools/h.py` is the
harness (2-TU = the `run_slice_multi.sh` recipe).

## 1. Headline

- **The phantom read is gone at its cause.** A new normaliser, `dropDeadCallArguments`
  (`SpecializeDetect.{h,cpp}`), runs FIRST in both entry points (right after the passthrough
  early-out): every integer/fp argument of a direct call to an exact, non-vararg definition whose
  parameter has NO USES becomes `Constant::getNullValue`, and the operand's now-dead cone is
  deleted (non-call instructions only), to a fixpoint. That is what `clang -O1` does to the
  hand-inlined twin — and what `-O1`'s own dead-argument elimination already does within one TU;
  CQ is the first stage that sees both TUs.
- **Every F-9C-1 member is now twin-identical or declines with the twin's verdict**, on this
  branch AND composed with bd 9bhg (§7). hgwx's measured members (`j02C`, `e02C`, `j01C`) are
  TRACE-IDENTICAL to their twins with 0 warnings and a 0-dirty census.
- **A TOTAL backstop, `declinePhantomCloneArgReads`** (`Specialization.{h,cpp}`), OBSERVES the built
  clones after `specialize()`: a module-level call that passes a tainted operand to a parameter the
  built clone never reads declines loudly (`cq specialization: quantum argument to a parameter the
  lifted callee never reads`), unless the operand is a `cq_theta` result (the user's own register;
  exempt, §4). It is C-reachable: a callee whose read of the parameter the CLONE pipeline removes
  (`volatile int z = a;`, erased by the fenv-ruled store elimination) is a phantom read the
  predictor cannot see.
- **hgwx's residual needed one more line: M-C `priorUseIsSettled` arm (d0)** (`ArithLowering.cpp`):
  a call that passes `P` only in slots whose callee parameter has no uses does not read `P`, and
  neither can its `_unc` twin. It moved 0 of 5421 modules and fixes the C-reachable
  volatile-callee spelling of hgwx (§5).
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
  volatile folds, fp80, PredMux, unroll, ctlz) then see the TWIN's IR, so their verdicts are the
  twin's. The drop needs taint only for the intrinsic-site membership skip; it SHRINKS taint and
  grows nothing, and the full re-`propagate` after it is exactly the restart every fixpoint below
  performs (the call result's taint came from the dropped operand), so it owes no
  `adjudicateTaintDelta`.
- Is "no uses" monotone across the window? No pre-pass adds a use of an unused parameter (they
  clone, fold and delete); callee bodies are untainted at module level, so the taint-driven
  pre-passes do not touch them. A use the CLONE pipeline later removes is the backstop's (§4).

**What the drop will not do** (each is a conjunct; §9 says which are pinned):
pointer/vector/aggregate arguments; constant operands (load-bearing for TERMINATION, §9); callees
that may be interposed (`!hasExactDefinition()` — LLVM DAE's own precondition and the specializer's
`scanBody` one); vararg callees; a call whose function type differs from the callee's; a parameter
or call-site argument carrying any attribute but `noundef`/`signext`/`zeroext`/`inreg`; and it never
DELETES A CALL (a dead `cq_theta` is the user's gate; `-O1` keeps it in the twin too).

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
gates are RED on the oracle (measured: the oracle's 2-TU boolsel trace carries the 11-line `%out`
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

**Slot** (both entry points): LAST in the post-`specialize()` decline chain — after the d88e lift
re-ask, the 2qyz re-sweep, the l3oi fence, the 3d8q stale-reader backstop, s82e's and tu9q's loop
re-asks; before `lowerRotations` (which RAUWs `cq_theta` results to handles). Composed with bd 9bhg
the order is d88e → 2qyz → l3oi → 9bhg's late 3jru → 3d8q → s82e → tu9q → vsfp. Why last: the twin
never computes the phantom operand, so any other owner that fires also fires on the twin and must
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
| M10 | the intrinsic-site membership skip | MISSED — equivalent: intrinsic callees are declarations, excluded by exactness (a belt) |
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
