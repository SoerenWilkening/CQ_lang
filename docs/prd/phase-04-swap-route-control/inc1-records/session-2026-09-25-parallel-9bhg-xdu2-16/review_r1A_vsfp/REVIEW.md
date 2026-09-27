# Rule-13 round r1A — bd vsfp (+ hgwx): the EARLY REWRITE `dropDeadCallArguments` and the fixture corpus it forced to change

Reviewer: independent agent, session 2026-09-26. Scope: the new early normaliser
(`SpecializeDetect.{h,cpp}` `dropDeadCallArguments` / `deleteDeadOperandCone`, its slot in
`CQLoweringPass.cpp`) and the 29 re-spelled + 1 converted + 20 new fixtures. The backstop
`declinePhantomCloneArgReads`, M-C arm (d0) and the emitted circuits belong to the concurrent
round r1B and are touched here only where a finding of mine goes through them.

| tag | binary | sha-256 prefix |
|---|---|---|
| SUBJECT | `5e56060b`, `<worktree>/build/ir-pass/cq-opt` (read-only, not rebuilt) | `73fd07592c4960dd` |
| ORACLE | `main` `aee8f4f8`, `frozen/cq-opt.main_aee8` | `69250feaf68bbe49` |
| private build of `5e56060b` (build null control) | `rA_vsfp/wt` (scratchpad worktree, removed after) | `73fd07592c4960dd` — bit-identical to SUBJECT |
| mutants (same worktree, one-site edits, mtime-bumped, hashed) | MA `de9300d641e511ee`, MB `c3a0fa460058f0fc`, MC `22d1a4dfbcd75460`, M10 `d78024bfe433810d`, FX1 `93fff4cdf453f6ac` | |

Probes, tools and results: `probes/{src,tools,results,out}`. Tools carry this session's
scratchpad paths. All shell work in bash (`pipe.sh` = the `run_slice_multi.sh` recipe + 2b STRICT
+ link + trace for ORACLE and SUBJECT).

## Verdict: **NOT-CLEAR**

Two P1s, both reachable from plain C, one of them INTRODUCED as a verdict. The corpus side of the
change (the 29 re-spells, the census, the A/B, the mover classification) re-measures clean.

| id | sev | what | status |
|---|---|---|---|
| F-VA-1 | **P1** | the drop rewrites the arguments of a `naked` callee (its asm reads the argument REGISTERS) — classical miscompile at exit 0, and the oracle's correct inline-asm decline becomes a silent accept | **INTRODUCED** · bd `test_C_libtooling-ctz4` |
| F-VA-2 | **P1** | the cone walk keeps dead LLVM **intrinsic** calls (`llvm.smax`/`abs`/`ctpop`/`ctlz`) that `-O1` deletes in the twin; they keep the 4.4 `%out` which-path rail alive → **silent** dephasing, exit 0, 2b STRICT clean. `prov1`: ORACLE declines (3jru), SUBJECT accepts dephased | **INTRODUCED** as a verdict (`prov1`); PRE-EXISTING and NOT CLOSED for the single-function spellings (`bint2`, `bint4`: SUBJECT stream byte-identical to ORACLE) · bd `test_C_libtooling-m1gi` |
| F-VA-3 | P2 | dead PHI CYCLES survive the cone walk: a dead loop-carried register passed only to a dead parameter is still lowered (`dcar1`: SUBJECT == ORACLE, 81 trace lines; twin 50) | PRE-EXISTING stream, class not closed; no wrong distribution demonstrated (noted in `m1gi`) |
| F-VA-4 | P3 | no CFG simplification after the walk: an arm it empties leaves an empty diamond on a tainted condition → `control flow under quantum control` where the twin accepts (`ediam1`, `ediam2`) | decline-string move vs ORACLE (both decline); safe direction (noted in `m1gi`) |
| F-VA-5 | P3 | §9's "M10 equivalent" is false: the intrinsic-site membership skip is LOAD-BEARING (a module that defines `cq_theta_si32` with an unused angle parameter gets `Ry(0)` instead of `Ry(θ)` under M10), and no fixture pins it | unpinned conjunct |
| F-VA-6 | P3 | `spec_result_classical.ll`'s re-scoped `CHECK-NOT: cq_template` now sits between two ADJACENT lines (`%z = add` … `ret`) — vacuous; the header says "the caller-side checks below are unchanged" | fixture weakened |
| F-VA-7 | P2 | five source/record claims falsified by F-VA-1..4 (L7 — fix at the source, in the same change) | falsified claims |

## F-VA-1 (P1, INTRODUCED) — a `naked` callee's arguments are rewritten

`dropDeadCallArguments` asks "does the callee PARAMETER have IR uses?". A `naked` function's
parameters never do: its body is inline asm that reads the argument registers. LLVM's own
`DeadArgumentEliminationPass::removeDeadArgumentsFromCallers` refuses `naked` for exactly this
reason; the drop copies DAE's `hasExactDefinition()` precondition but not this one. Measured that
`clang -O1` keeps the argument of a naked callee in one TU while it removes a non-naked twin's
(`probes/src/dae_ctl.c`), so the header's "IT IS LLVM'S OWN TRANSFORM, APPLIED ACROSS TUs" is false
here.

- `naked1.c` (single TU): `__attribute__((naked, noinline)) int ident(int a) { __asm__("movl %edi, %eax\n\tret"); }`,
  `r = ident(m * 3)` in a module that has a `cq_theta`. argv `5`: ORACLE prints `ident=15`;
  SUBJECT prints **`ident=0`** (`CQ_DEADARG_DBG: drop arg 0 of @ident in @main`). opt exit 0, 2b clean.
  A classical miscompile of the classical part of a quantum program, because the drop is
  taint-agnostic.
- `naked2.c`: `ident(q)` with `q` quantum. ORACLE: loud `cq specialization: callee contains a
  non-reversibilizable construct under quantum lift (inline assembly)`, which is correct. SUBJECT:
  **accepts at exit 0** and the asm receives `0`. A wrong accept.

Fix: `Callee->hasFnAttribute(Attribute::Naked)` → skip (DAE's own conjunct) + a red-green pair.
No other DAE precondition is missing for the int/fp-only, call-site-only form (swifterror /
by-value-copy attributes are pointer-typed and already excluded by the type test and whitelist).

## F-VA-2 (P1) — dead intrinsic calls keep the which-path rail alive

`deleteDeadOperandCone` never deletes a call ("a dead call to a `memory(none)` user function is
kept too so the stage has one rule … `clang -O1` keeps both in the hand-inlined twin as well").
For a CROSS-TU user function that is right (`spec_accept_dropped_arg_pure_call_kept.ll` pins it).
For an LLVM INTRINSIC it is false: `-O1` deletes a dead `llvm.smax`/`llvm.abs`/`llvm.ctpop`/
`llvm.ctlz` call in any TU, and the natural C idioms `a > b ? a : b`, `abs(x)`,
`__builtin_popcount`, and a shift-count loop (which `-O1` turns into `llvm.ctlz`) all produce one.
The kept call is the phantom reader bd vsfp is about, one hop further in.

- **`prov1.c`** (2-TU, lib `int h(int a, int k) { return k + 1; }`) — the bead's own `b10f`
  with a `max` idiom in the dead operand:
  `__attribute__((noinline)) int f(int m, int n) { _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = h(p > n ? p : n, m); b = cq_theta(b, .7); return t + cq_measure(b); }`,
  `main` returns `f(atoi(v[1]), atoi(v[2]))`.
  - ORACLE: exit 1, `cq taint escape: quantum value returned across a function boundary` (3jru).
  - SUBJECT: **exit 0, stderr = the DBG line only (no warning), 2b STRICT `1 verified, 0 violation(s), 0 unproven`**.
    Stream (`probes/out/prov1.SUB.trace`): `cnot(h0,h1)`; `%out` h2 = `alloc(0)` + two
    `cqrt_copy_i32_controlled` (9 / 4); `cqrt_free(h1)`; **`cq_template_smax_i32_hl(h2, 7) -> h5`**;
    `cqrt_ry_i1(h0, 0.7)`; `measure(h0)`. h2 and h5 are never uncomputed.
  - Twin (`t = m + 1`): 4 lines, `Ry(.5) Ry(.7)` on one handle. Analytic as in bd vsfp: P(b=1),
    odd m, 0.8356 dephased vs 0.6812 coherent.
- **`bint4.c`** (same, single function, no `f`) and **`bint2.c`** (`__builtin_abs` → `llvm.abs`):
  the SUBJECT stream is **byte-identical to the ORACLE's** (16 lines each, silent, 2b clean): the
  drop fires and changes nothing. PRE-EXISTING, and a member of exactly the class the change claims
  to close.
- `ctlz1.c`/`ctlz2.c` (`-O1` turns the shift loop into `llvm.ctlz`; `__builtin_popcount`): the dead
  intrinsic's template rail is minted and left dirty (census `1 template rail mint(s) of which 1
  left dirty`; twin 0); `ctlz2` warns (lyyf-(B) template-rail class) and is otherwise ORACLE-identical.

The backstop cannot see any of this: after the drop the call is `h(0, m)`, no clone exists, and the
leftover reader is an intrinsic. So "the TOTAL half … OBSERVES … whatever this predictor missed"
does not hold for bd vsfp's class — it holds for phantom reads THROUGH A CLONE CALL.

**Candidate fix, measured, not landed** (mutant FX1): let the walk delete a trivially-dead
`llvm::IntrinsicInst` (still never a `cq_*` or user call):
`I->use_empty() && (!isa<CallBase>(I) || isa<IntrinsicInst>(I)) && isInstructionTriviallyDead(I)`.
`prov1`, `bint2`, `bint4`, `ctlz1`, `ctlz2`: all five become trace-identical to their twins.
Full lit under FX1: **2328 discovered, 2327 passed, 1 XFAIL** (same as the SUBJECT null run), so
today **no fixture pins this conjunct in either direction**. An accept-direction change on
`prov1`-shaped inputs; owes its own red-green and round.

## F-VA-3 (P2) — dead phi cycles survive the walk

The walk deletes only `use_empty()` instructions, so a loop-carried value whose only exit use was
the dead argument keeps its header-φ/latch cycle. `dcar1.c` (the owner's rolled cascade plus a
second carried register `s`, `if (b0[i]) s -= 7;`, passed only to `h`): the drop fires, the TRACE
is **byte-identical to the ORACLE's** (81 lines; census 3 template rails / 2 dirty, ORACLE 4 / 3) and
the twin's is 50 lines (2 / 1). I could not reach a later non-diagonal gate on the entangled registers without
hitting an unrelated wall (rail-bank reader, `stored to memory`, `control flow`), so no wrong
distribution is demonstrated; `dloop2`/`dloop3`/`dcar5`/`dcar6` decline on both binaries where the
twin accepts (safe). The finding is that the "twin's IR" premise does not hold for this shape and
the class is not closed. (`dloop1`, constant trip, is fully removed by a later stage — fine.)

## F-VA-4 (P3) — no CFG simplification after the walk

`if (q > 3) p = 100 / n;` with `p` only passed to a dead parameter: `-O1` keeps the branch (the
`sdiv` is not speculatable); the walk deletes the φ and the `sdiv` and leaves `br i1 %c, %arm, %merge;
arm: br %merge` on a tainted condition. SUBJECT: `control flow under quantum control`; ORACLE:
`condition predates a non-diagonal gate …` (`ediam1`) / `value-arm swap-route …` (`ediam2`, with a
live constant φ); twin: accepts. Safe-direction over-decline and a string move; noted because it is
the third measured way the post-drop IR differs from the twin's.

## F-VA-5 (P3) — M10 is not an equivalent mutant

§9: "M10 … MISSED — equivalent: intrinsic callees are declarations, excluded by exactness (a
belt)". Counter-example, accepted at exit 0 by both ORACLE and SUBJECT: a lib TU that DEFINES
`int cq_theta_si32(int x, double a) { return x; }`, caller `cq_theta(m & 7, atof(v[2]))`
(`resv2.c`). SUBJECT: `cqrt_ry_i32(h, %8)`. M10: `CQ_DEADARG_DBG: drop arg 1 of @cq_theta_si32`,
**`cqrt_ry_i32(h, 0.0)`** (`probes/out/resv2.M10.s2.ll`). The membership skip is the only thing
protecting the rotation angle here; no fixture pins it. (That the pass silently accepts a user
definition of a reserved front-end symbol is pre-existing and out of this round's scope.)

## F-VA-6 (P3) — one re-spelled fixture's negative check became vacuous

`spec_result_classical.ll`: the whole-file `CHECK-NOT: cq_template` (window `[ret, EOF]`, which
covered the clone body and the declarations) was moved to sit between `CHECK: %Z = add i32 %R, 5`
and `CHECK: ret i32 %Z`, which are consecutive lines of the output — it checks nothing. The header
says "the caller-side checks below are unchanged". Scope it with `CHECK-LABEL: define i32 @example`
… `CHECK-NOT: cq_template` … `CHECK: ret` over the whole caller, or say it is dropped.

## F-VA-7 (P2) — claims to correct at the source (L7)

1. `SpecializeDetect.h`: "IT IS LLVM'S OWN TRANSFORM, APPLIED ACROSS TUs" — not for `naked` (F-VA-1).
2. `SpecializeDetect.cpp` `deleteDeadOperandCone`: "`clang -O1` keeps both in the hand-inlined twin
   as well" — false for LLVM intrinsics (F-VA-2); true for a cross-TU user call only.
3. `CQLoweringPass.cpp` / TRACK §2: "the pre-passes … see the TWIN's IR" — false in three measured
   ways (F-VA-2, -3, -4).
4. TRACK §1 / bead note: "The phantom read is gone at its cause" and the backstop as "TOTAL" — false
   for `prov1`/`bint2`/`bint4` (F-VA-2).
5. TRACK §9: M10 "equivalent" (F-VA-5).

## What re-measured CLEAN (Rule 11)

- **Build null control**: private build of `5e56060b` hashes `73fd07592c4960dd` = SUBJECT.
- **Census** (`CQ_DEADARG_DBG`, SUBJECT, positive control first): current tree **15/2328** fire
  (11 new, the converted live-record fixture, and the three "unchanged but touched"); ORACLE tree
  **33/2308** fire = the 30 changed fixtures + the same three. So the implementer's 33 reproduces and
  nothing was missed. The three unchanged ones still test their property: `spec_reject_arity_64`
  (63 classical args dropped, the tainted arg 0 is used, the arity fence is a callee property);
  the two `control_inplace_ry_reject_rail_round2_*` (the dropped operand is `ext_sink(keep)`'s, the
  `cq_measure` call is kept, the load-bearing classical diamond survives because its call does).
  e2e: my own stage-1 corpus from every `run_slice*.sh` ctest command line, **428 modules (26
  multi-TU)**: **2 fire**, the two new slices; **no libm slice fires**.
- **Re-spells reach their NAMED fence** (bd 46oo class): deleting the `%vsfp.read` line turns
  **29/29** re-spelled fixtures red (the `CHECK-NOT: CQ_DEADARG_DBG` pin is real). With the fence
  itself disabled: MA (`declineFalsifiedMergePhiLifts` off) turns **14/14** d88e declines red; MB
  (`declineScrubbedHandleReads` off) **6/6** l3oi declines; MC (`returnDerivesFromUndef` → false)
  **5/5** ret-poison declines (incl. `control_predmux_reject_selectform_purecallee_retpoison`). Every
  re-spelled decline is pinned by its named owner, not by a same-string neighbour.
- **Duplicate-body scan** (sha-256 over non-comment lines): 13 pre-existing groups, none contains any
  of the 50 changed/added fixtures.
- **Corpus A/B ORACLE → SUBJECT** (null SUBJECT→SUBJECT first, 0 of 2328 / 0 of 428; positive
  control 1 of 1): lit **16 movers**, exactly the implementer's (15 new + the converted one); e2e
  **2 movers**, the two new slices.
- **Probe-corpus mover classification**: seeded sample of **34 of 309** (`probes/results/sample.txt`),
  re-built independently from source: **34/34** mover kinds (A→D/D→A/DIAG/STREAM) as claimed; every
  hand twin (21 of the 34 have one) agrees with the claimed class; a second, independent single-TU
  twin (caller + lib concatenated, `-O1`) agrees with the claimed class on 31/34, and the 3
  differences (`r2A s_f80`, `a_w9`, `a_v1`) come from whole-TU inlining of OTHER callees (`s_f80`'s
  hand twin agrees; `a_w9`/`a_v1` re-checked with drop-only hand twins `aw9`/`av1`: trace-IDENTICAL).
- **User gates are never erased**: `cq_measure(q) * 2 + 1` and `cq_theta(...) + 1` passed only to dead
  parameters — both calls survive and lower, twin-identical (`meas1`).
- **Passthrough**: the drop runs after the check and deletes no call, so `ThetaCalls`/`PhaseCalls`/
  `MeasureCalls` cannot change; a module with no quantum surface is untouched.
- **Monotonicity of "no uses"** across the window: no pre-pass in `ir-pass/src` creates a new
  reference to a function `Argument` (grepped every `getArg`/`args()` site).
- Full lit on the SUBJECT through a private site config: **2328 discovered, 2327 passed, 1 XFAIL**.

## My own instrument failures (L10), both caught

1. The first census printed `FIRED=0` over the full 2328: `timeout` does not exist on this box, every
   run exited 127. Caught by the positive control; v2 uses `perl alarm`, counts `rc>=126` as
   TOOLFAIL and prints the denominator.
2. The first fence-mutant lit run printed nothing: `lit.cfg.py`'s stale-`debugalloc` mtime guard
   fatal'd and my `grep` filtered the fatal away. Caught by the missing denominator.

## What I did NOT attack

- The backstop's own logic, its `cq_theta` exemption, M-C arm (d0), and the emitted circuits
  (round r1B), except where F-VA-2 shows the backstop's reach.
- The libm census itself (Rule 18): no openlibm corpus on this box (`bc/` and `openlibm/` absent).
  Evidence is indirect only: 0 fires over every e2e `slice_libm_*` module.
- The full `ctest -j6` (I ran lit and e2e stage 1–2 only; I did not relink/run every slice).
- `invoke`/`callbr`/C++, `-g` debug-info fidelity of the callee's now-stale `dbg.value` of a dropped
  parameter (DAE RAUWs it to poison; the drop leaves it — a debugger shows `0`, no circuit effect).
- The composition with bd 9bhg (the scratch composed binary was removed).
- A demonstrated wrong distribution for F-VA-3 (I could not reach a trailing non-diagonal gate).
- The second entry point (`runOnFunction`, the dead shim).
- Observation, not a finding: the 13 A→D moves on bd z0re's members pre-empt part of an open owner
  question for the dead-parameter spelling. That is disclosed in TRACK §8 and in
  `spec_reject_dropped_arg_statepred_runtime_seed.ll`'s header, which I read as adequate.
