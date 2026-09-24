# Track C — bd `xdu2.8`: the arm-guarded classical runtime-VLA read

Session 2026-09-24, rail-bank parallel session, Track C. Branch
`worktree-agent-a9b52024d1b43d9cd`, based on `d0720cb1`. Implementation commit
`30ed0f64`; Rule-13 round-1 fixes in the follow-up commit (final subject
`cq-opt` `43ab3ad5bd28a8e9`). Oracle `cq-opt` `c6f61f80a5d524c6` (the `d0720cb1` build); subject
`cq-opt` `c5b256d3298ce04a` (rebuilt after the comment-only L7 edits and
bit-identical, which doubles as a build null control).

## 1. Headline — read this before flipping anything

**Row 13 of `tests/e2e/railbank_dynamic_matrix.c` does NOT move D→A.** It still
declines with the same string, `cq controlled lowering: control flow under
quantum control`, but at a different owner:

| binary | PredMux E4 | first decline |
|---|---|---|
| oracle | `gate=E4-gep` (the load cannot be speculated) | PredMux leaves the region; ControlDetect declines the branch |
| subject | admitted, no E4 leave line | `SelectClassify::classifySelectRegion`, untainted-leaf gate, on `select i1 (and (m == n), (q != 0)), i32 …` |

**The bead's program has TWO walls, and the brief expected one.** The second is the
4.4 DATA select over a hybrid classical∧quantum condition. `SelectClassify.cpp`
records it as "a hybrid classical∧quantum conjunction is out of scope this
increment", and the same comment says it is **load-bearing for bd `q2wk`'s E6
rule (B)**. It is **pre-existing and not specific to VLAs**. Measured on the
ORACLE with a `static const int tbl[8]` table in place of the VLA
(`tc_scratch/p1.c` in the track worktree): PredMux flattens (a fixed table is
provable at the hoist point) and the data select then declines at the same gate.
**Any** arm-local classical guard is, by construction, a classical conjunct of the
arm's condition, so it always produces this hybrid condition. For `int`
accumulators this is unavoidable.

**Question for the owner (Rule 17).** I did not lift the hybrid-leaf gate. It is a
control-emitter widening in the Rule-13 core. It carries an explicit dependency
(q2wk's rule-(B) taint argument must be re-derived first), and the realization
itself has to be chosen. The physically valid options I can see:
(a) lower `c ∧ f_q` with a classical `c` through the existing `and_i1_hl` template,
so `c` stays in the `_hl` literal slot, which §5.2 sanctions, and hand the select a
template-minted flag. The 4.4 select does not take such a flag today.
(b) emit a classically controlled merge (`if (c)` around the controlled copies).
(c) for additive arms only, fold the guard into the classical operand
(`a + (c ? v : 0)`).
I brought this back instead of choosing. A separate bead for "hybrid
classical∧quantum condition in the 4.4 data select" seems right. xdu2.8's E4 half
is its prerequisite, but that bead is not in xdu2.8's scope.

## 2. What landed

- **`ir-pass/src/GuardedClassicalRead.cpp`, `ir-pass/include/GuardedClassicalRead.h`** (new).
  This file handles obligation (A), admission. The load must be a runtime-VLA
  read. The shape half of `classicalRuntimeAllocaReadIsInBounds` is CALLED, not
  re-derived. The load must carry no `!range`/`!nonnull`/`!align`/`!dereferenceable*`.
  A CLASSICAL compare fact must then prove the index in bounds. The fact is taken
  from an `and`/`or`/`select`/`not` decomposition of a conditional branch INSIDE the
  region whose taken edge DOMINATES the load's block. The compare must be
  untainted now and after the flatten, and integer-typed. There are two proofs:
  - **(T)**: `trips == extent`, or `extent ≥ trips`, through a common cast chain
    (zext only for orders). Here `trips` is the unit counter's exact trip count.
  - **(I)**: `index < extent`, strictly, through a zext chain.
  A signed order also requires its smaller side to be non-negative.

  Obligation (B), emission, is `guardSpeculatedClassicalRead`:
  `select (freeze idx <u zext(freeze extent)), gep T base fidx, @cq.guarded.read.zero`.
  The global is a private, unnamed_addr zero constant. The read is in bounds on
  every path by construction, so (B) does not depend on the fact at all. That is
  why no poison or undef reasoning about the guard is needed.
- **`PredMuxFlatten.cpp`**: E4 arm **(1d)** is the last resort in
  `classicalTableReadIsSpeculatable`, after every existing fence (simple, classical
  now and after the flatten, not QROM-shaped, a template width). A (1d) admission
  is recorded in `PredMuxRegion::GuardedLoads`, following the `MaskLoads`
  precedent: it is discarded with `R` on any later `leave`. `RegionFlattener::run()`
  then rewrites each recorded load after `moveBody`. The replaced gep is `track`ed,
  so the dead sweep removes it only if nothing else reads it (it is classical).
- **`QramLowering.{h,cpp}`**: `classicalRuntimeAllocaReadIsInBounds` is split into
  `runtimeAllocaReadShape` + `unitCounterTrips` + its own equality proof (Rule 14:
  one spelling for both callers). **Its answer is unchanged**, and this is pinned.
  The six pre-existing `control_predmux_reject_runtime_vla_*` fixtures are in my
  lit filter and stay green. Mutant M26 (drop the stackrestore liveness clause from
  the shared shape) is killed by `…_dead_storage_stackrestore.ll`.
- **L7 edits in the same change**: the `QramLowering.h` contract ("Failure to prove
  any conjunct leaves PredMux's existing loud E4 decline in place" is now qualified),
  PredMux's E4 ruling paragraph and its call-site comment, and a cross-reference at
  SelectClassify's untainted-leaf gate naming its new measured customer (comment
  only).

**Customers that ACCEPT (subject) and DECLINE (oracle).** All five merge into
`_Bool`, through PredMux's boolean-algebra path, where the classical leaf occupies
an `and_i1_hl` literal slot:
matrix CASEs 1, 2, 3 and 5, the slice, and the hand-built `not`-guard fixture.
CASE 15 is the hand-written twin: the source performs the guarded read itself, so
nothing is speculated. It accepts on both binaries, and CASE 1's trace is
byte-identical to it with the index both in bounds and out of bounds (the two
`twins` entries).

## 3. Owned tests (quoted, subject `c5b256d3`)

```
$ cd build && lit ir-pass/test --filter 'predmux_guarded_vla|runtime_vla'
Total Discovered Tests: 2187
  Excluded: 2164 (98.95%)
  Passed  :   23 (1.05%)

$ ctest --test-dir build -R '^e2e-railbank-guarded-vla-matrix$|^e2e-slice-predmux-guarded-vla$'
1/2 Test #487: e2e-railbank-guarded-vla-matrix ...   Passed   14.95 sec
2/2 Test #488: e2e-slice-predmux-guarded-vla .....   Passed    1.08 sec
100% tests passed, 0 tests failed out of 2

railbank_guarded_vla_matrix: 18 case(s): 5 accept, 13 decline; 2 twin(s); 0 failure(s)
```

**Red on the oracle.** On `c6f61f80`, 4 lit fixtures FAIL: the three clang-derived
accepts and `…_reject_row13_hybrid_select.ll`, whose `CHECK-NOT: gate=E4` is the
owner-move witness. The `not`-guard accept was added after this red run, and its
kill is recorded as M11. The matrix gives `18 case(s) … 7 failure(s)`: 4 accept
rows, CASE 4's diagnostic, and 2 twins that cannot link.

The e2e slice runs STRICT stage 2b:
`1 rail mint(s) of which 1 left allocated, 4 template rail mint(s) of which 0 left
dirty, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`. The golden (26
lines) pins both activations. With `k=1<3` the literals are the real cell
(`4>4=0`, `4<9=1`). With `k=6≥3` the guard is false and the zero cell is read
(`0>4=0`, `0<9=1`).

## 4. Mutation matrix (source injection, owned tests only)

`tc_scratch/mutate.py` applies one mutant, rebuilds both targets, runs the owned lit
filter and the two owned ctest entries, and restores. The NULL mutant ran first
(pass 1: `lit pass=21 fail=0`; pass 2: `lit pass=23 fail=0`), and 0 tests moved
both times. The restored build is `c5b256d3` both times.

**Denominator: 26 real mutants. Final: 20 KILLED, 6 MISSED** (pass 1 19/7, then
M9 and M11 killed by two new fixtures in pass 2, and M4 killed in pass 3 after
round 1 showed it was NOT shadowed; each pass ran the null mutant first, 0 movers).

| mutant | verdict | killed by |
|---|---|---|
| M1 metadata conjunct | KILLED | `…_reject_range_metadata.ll` |
| M2 load-in-region | MISSED | shadowed: the E4 walk only visits region blocks |
| M3 load-not-in-Entry | MISSED | shadowed: the E4 walk skips `Entry` (`if (B == E) continue`) |
| M4 flat single-index gep form | KILLED (pass 3) | `…_reject_arraydecay_gep.ll`. My "shadowed" claim was FALSE (round 1 P3-1): `matchAddressGep` admits a two-index `[4 x i32]` decay gep over a scalar runtime alloca, and this conjunct alone stands between it and the emitter |
| M5 extent ≤ index width | MISSED | shadowed: clang's VLA extent is `i64` and the shape forces an address-width index |
| M6 edge dominance | KILLED | `…_reject_else_arm_read.ll`, matrix |
| M7 fact taint / will-taint | MISSED | shadowed: a tainted compare cannot be SCEV-equal to the classical trip/extent/index expressions. The only construction I can see (a region φ with identical incomings, which SCEV folds) would be a numerically TRUE fact, so this conjunct is conservative, not load-bearing |
| M8 integer-typed fact | MISSED | shadowed: a pointer compare has no SCEV match against integer trip/extent |
| M9 `and` decomposed on a false edge | KILLED (pass 2) | `…_reject_and_false_edge.ll` (hand-mutated: clang turns every C spelling into an `or` on the true edge) |
| M10 `or` on a false edge not decomposed | KILLED | `…_accept_trip_ge_guard.ll`, matrix |
| M11 `not` polarity | KILLED (pass 2) | `…_accept_not_guard.ll` (hand-mutated) |
| M12 equality proof | KILLED | `…_reject_row13_hybrid_select.ll`, matrix |
| M13 gt/ge canonicalisation | KILLED | flipped + trip-ge accepts, matrix |
| M14 `ne` exclusion | KILLED | `…_reject_ne_guard_swapped.ll` |
| M15 signed non-negativity | KILLED | `…_reject_signed_guard_unsigned_index.ll`, matrix |
| M16 proof (T) | KILLED | `…_accept_trip_ge_guard.ll`, matrix |
| M17 proof (I) strictness | KILLED | `…_reject_nonstrict_guard.ll`, matrix |
| M18 proof (I) | KILLED | idx accepts, matrix, slice |
| M19 emission without the select | KILLED | 3 accept fixtures, matrix twins |
| M20 emission `ule` | KILLED | 3 accept fixtures |
| M21 emission without freeze | KILLED | 3 accept fixtures |
| M22 no record at E4 | KILLED | 4 accept fixtures, matrix |
| M23 `NeedsGuard` not set | KILLED | 4 accept fixtures, matrix |
| M24 no rewrite in `run()` | KILLED | 4 accept fixtures, matrix (the `LOAD-NOT` whole-file prefix) |
| M25 order facts through sext/trunc | MISSED | shadowed CONTINGENTLY (round 1 P3-6): an i128 order fact is needed and E6's leaf grammar refuses it first. Retirement trigger written at `sameCastChain` |
| M26 shared-shape stackrestore clause | KILLED | pre-existing `control_predmux_reject_runtime_vla_dead_storage_stackrestore.ll` |

Caveat: pass 1 regenerated the fixture set during mutants M21 to M26, which added
the two hand-mutated fixtures. Those six rows ran against 23 fixtures, not 21. They
were all KILLED by fixtures that existed before the regeneration, so their verdicts
stand. M19 did not fail the e2e slice: its out-of-bounds read of stack garbage
happened to produce the golden's literals. It was killed elsewhere. The slice alone
is therefore not a witness for the select.

## 5. Other measured findings

- **Matrix CASE 4 (`q && m == n` in a loop, per-trip `_Bool`s) declines at a
  PRE-EXISTING wall**, `cq loop lowering: hoisted invariant rail admitted for in-loop
  discharge was not discharged`. `-O1` LICM-hoists the hybrid `and` into the
  preheader. A const-table twin (`tc_scratch/p4.c`) declines identically on the
  oracle. CASE 5 (`m >= n`) accepts only because its arm is on the FALSE edge of an
  `or`, which the flatten re-materialises in the body by De Morgan. This is an
  over-decline independent of xdu2.8, and I have not filed it.
- A signed `k < m` guarding a signed index (CASE 8) and guarding a
  `(unsigned)k` index (CASE 17) both decline, correctly: `k < 0` is out of bounds.
  An `unsigned` index is the accepting spelling.

## 6. What I did NOT test

- No full `ctest`, no unfiltered `lit`, no `cq-opt-equivalence`, no corpus A/B, and
  no `e2e-loop-twin-matrix` (forbidden inside a track). No run of
  `e2e-railbank-dynamic-admission-matrix` either (not owned). From CASE 6, I expect
  row 13 there to keep its expectation unchanged.
- No composition with a rail bank in the same function. `free_pairing_check.py`'s
  bank-address confinement has not seen a load through a pointer `select`.
- Clone mode (`lowerCloneControl` / `ClaimAll`) is reached by the same code but was
  not exercised.
- No `+Asserts` build.
- An in-loop proof (I) with a loop-variant guard and `_Bool` merges was not
  separately built from C. CASE 4's hoisting wall is in front of the in-loop
  equality variant.
- Rule 13: see §7. One independent round was run inside the track. Clearance at the
  merge gate is still the orchestrator's.

## 7. Rule-13 round 1 (independent reviewer, inside the track)

Verdict: **CLEAR-WITH-ITEMS. 0 P1, 1 P2, 8 P3.** The reviewer ran only the frozen
subject and oracle binaries. The probes are in the track worktree's
`tc_scratch/review/` (untracked). The central argument for no P1 is its own: the
emission makes every well-defined program correct regardless of admission. Where
the arm runs, a well-defined source has `idx < extent`, so the select reads the
real cell. The fact collection therefore only decides which programs get in.

| finding | disposition |
|---|---|
| **P2-1** A `select c, %p, %p` gep base: admission (`walkPtrOrigin`) sees through it, the emission re-derived the allocation with `getUnderlyingObject`, and `report_fatal_error` fired (exit 134) where the oracle declined. That is two spellings of one derivation (Rule 14), in the §4f (P4) crash class. Not reachable from C at `-O1` | **FIXED**: the proved extent is carried in `GuardedLoads` and the emission derives nothing. Pinned by `…_accept_select_base_no_abort.ll`, which is red on `30ed0f64` (`LLVM ERROR: cq: guarded classical read lost its allocation`) and green now |
| P3-1 M4 is not shadowed | **FIXED**: `…_reject_arraydecay_gep.ll` checks the leave line and the string. M4 is now KILLED |
| P3-2 `_Bool` VLAs over-decline on the blanket `!range` refusal (clang tags `!range [0,2)` + `!noundef`) | OPEN, not fixed. Narrowing it is an ACCEPT-direction change and must drop `!noundef` too. Filed here for the orchestrator |
| P3-3 The round-2 (L1) closure is contingent: an index that becomes tainted in round 2 taints the flatten's own pointer select, and SelectClassify declines it (`control flow`). It is loud and safe, but it is not a named fence | RECORDED here, not fenced |
| P3-4 `!noundef`/`!invariant.load` survive speculation (the `moveBody` class, pre-existing for all of E4) | RECORDED. This change adds population |
| P3-5 The zero cell can feed `ctlz(0, true)`, which is poison. The `_hl` literal is then garbage, but it is materialised once, so the forward and `_unc` agree (pre-existing class, more population) | RECORDED |
| P3-6 M25 is contingent on E6's grammar | retirement trigger written at `sameCastChain` |
| P3-7 The `sameCastChain` comment said zext was "the only" order-preserving cast; sext is one too | **FIXED at the source** (L7) |
| P3-8 Whether a nested pair accepts depends on claim order: an outer claim leaves `gate=E4-gep at %cq.gr.cell`, the change's own output | RECORDED. A safe over-decline |

After the fixes (subject `43ab3ad5`): owned lit `Passed : 25`, owned ctest 2/2,
matrix `18 case(s) … 0 failure(s)`, CODE_MAP `--check` clean. **Round 1 did NOT
attack:** clone mode (unreached), switch-terminated regions, non-zero address
spaces or non-64-bit index widths, multi-function modules, a user global named
`cq.guarded.read.zero`, or the corpus. A second round is the orchestrator's call.
The Rule-13 budget in CLAUDE.md suggests one.

## 8. Rule-13 round 2 (orchestrator-run, on `d505873f`) — fixes

Verdict: **CLEAR-WITH-ITEMS, 0 P1, 1 P2, 2 P3.** Final subject `cq-opt`
`e5a2ad88d1f28bc1`.

| finding | disposition |
|---|---|
| **P2** An alloca in a non-zero address space (datalayout `-A5`). The zero cell is in space 0, so the address `select` is ill-typed and `opt` ABORTED (exit 134, "Invalid operands for select instruction! … Broken module"). The oracle declined cleanly | **FIXED at admission**: a guarded read whose pointer is not in address space 0 is refused. `…_reject_addrspace.ll` pins the leave line with three `CHECK-NOT`s (select / Broken module / LLVM ERROR), which is what tells a decline from an abort. It is red on `d505873f` |
| **Sweep (requested): a THIRD abort, found by the sweep.** With a datalayout whose DEFAULT GLOBALS space is non-zero (`-G1`), the `GlobalVariable` constructor put the zero cell in `addrspace(1)` while the load stayed in space 0. It was the same ill-typed select | **FIXED**: the cell is created with address space 0 explicitly. `…_accept_globals_addrspace.ll` is red on `d505873f` |
| Sweep, the rest, enumerated at the admission site: load TYPE (scalar int/fp equal to the cell type, from the shape half, so `getNullValue` is a defined zero; no vector or pointer); volatile/atomic (`isSimple`); ALIGNMENT (the cell is created or reused at an alignment ≥ the load's); index/extent widths (address-width index; the extent is no wider, so the `zext` is well-formed) | no further mismatch found. Each item is written as a comment at the admission site |
| **P3** `zeroCellFor` reused any private zero constant whose NAME started with the prefix, and RAISED its alignment (a user's align 1 became align 4) | **FIXED**: reuse is keyed on the pass's own `!cq.guarded.read.zero` metadata marker. The cell must also have the same type, space 0, and alignment ≥ the load's; alignment is never raised. The false "a user global is left alone" comment is replaced. Fixtures: `…_accept_user_zero_global.ll` (the reviewer's align-1 probe; red on `d505873f`), `…_accept_user_zero_global_aligned.ll` (align 16, so only the marker tells it apart; red on `d505873f`), and `…_accept_two_alignments.ll` (an align-1 and an align-4 guarded read need two cells; red on `d505873f`) |
| **P3** Round-2 taint growth: an index that becomes tainted only in round 2 (reviewer probe `r2g.c`, the merge `%out` of a 6.5 classical-call arm) taints the flatten's own `%cq.gr.addr` select. It declines LOUDLY only because `SelectClassify` has no data-select shape for a tainted POINTER select. `flattenPredMuxRegions` runs only before round 1, and nothing re-asks (1d) | **RECORDED, with a RETIREMENT TRIGGER at the (1d) admission site** in `PredMuxFlatten.cpp`: the day any consumer admits a tainted pointer select, or a round-2 QROM carve reads through one, this read needs a named post-fixpoint re-ask of "is the index still classical at FINAL taint" |

**Mutation delta.** Null control first in both passes (pass 4: `lit pass=28 fail=0`;
pass 5: `lit pass=30 fail=0`). There are 4 new mutants:
- M27, the address-space admission: KILLED by `…_reject_addrspace.ll`.
- M28, the zero cell created in the default globals space: KILLED by
  `…_accept_globals_addrspace.ll`.
- M29, reuse by name: MISSED in pass 4, because the align-1 user global shadowed it.
  KILLED in pass 5 by `…_accept_user_zero_global_aligned.ll`.
- M30, reuse ignoring alignment: MISSED in pass 4, with only one guarded read. KILLED
  in pass 5 by `…_accept_two_alignments.ll`.

**Cumulative: 30 real mutants, 24 KILLED, 6 MISSED.** The six are M2, M3, M5, M7 and
M8, all shadowed, and M25, which is contingent. Owned lit `Passed : 30`, owned ctest
2/2, and `update_code_map.py --check` clean.

## 9. Rule-13 round 3 (orchestrator-run, on `c9802fa7`) — fix and a note

Verdict: **CLEAR-WITH-ITEMS, 0 P1, 0 P2** (76 C sources plus hand IR, no aborts). One
P3 fixed and one note recorded. Final subject `cq-opt` `82b7656eb4f42b6f`.

**P3 (fixed): §8's metadata-keyed reuse was itself trust in the module.**
`zeroCellFor` reused any global carrying `!cq.guarded.read.zero` with a matching
type, address space and alignment. It never checked linkage, initializer,
constness or TLS. The reviewer's probes:
- An `extern_weak` forgery compiled, and its out-of-bounds run SEGFAULTED (exit
  139) where the oracle declined.
- Forgeries on a mutable global initialised to 7, a `thread_local` global, and a
  global written by another function also compiled.

**Choice: no reuse at all, rather than a stricter reuse predicate.** Every guarded
read gets a fresh `private unnamed_addr constant` zero cell, in address space 0, at
exactly the load's alignment. Nothing in the pass ever looks a cell up, and the
marker is no longer emitted. Why this instead of the alternatives:
- A stricter reuse predicate (private or internal, constant, definitive null
  initializer, not TLS, not externally initialised) would be the third
  module-trusting spelling in three rounds.
- A pass-local map would need state threaded through several
  `flattenPredMuxRegions` invocations for a saving of a few bytes per read.
- **A forged marker gets no reserved-name decline.** The xdu2.4 forged-seed
  decline exists because that marker is READ. This one is never read, so a forgery
  is inert. Declining it would refuse a valid program over a name.

Round 2's "reuse keyed on the pass's own marker" is therefore **superseded**.

**Fixtures.**
- Three new ones from the reviewer's probes, all red on `c9802fa7`:
  `…_accept_forged_marker_{extern_weak,mutable,tls}.ll`. Each asserts that the
  select reads a fresh private constant zero cell and never the forged global.
- The four fixtures that checked the retired marker now end their cell pattern at
  `align N{{$}}`. Their headers are updated.

**Mutation delta (pass 6: null control first, `lit pass=33 fail=0`, 0 movers).**
M29 and M30 targeted code that no longer exists and are retired. Four mutants ran,
four KILLED:

| mutant | killed by |
|---|---|
| M31: reuse by name prefix | 4 fixtures |
| M32: reuse any private null constant of the type, ignoring alignment | two-alignments + both user-global fixtures |
| M33: reuse any marked global | all three forged-marker fixtures |
| M28: zero cell in the default globals space (re-run) | `…_globals_addrspace.ll` |

Cumulative: **31 real mutants, 25 killed, 6 missed**. The six are M2, M3, M5, M7 and
M8, all shadowed, and M25, which is contingent.

Owned tests on `82b7656e`:
- lit (`predmux_guarded_vla|runtime_vla`): `Passed : 33`
- owned ctest: 2/2
- `update_code_map.py --check`: clean

**N-1 (recorded for any future twin): a twin must spell the EMITTED select, not the
guard.**
- The emitted address is `idx <u extent ? &p[idx] : &zero`. It is NOT `guard ?
  &p[idx] : &zero`.
- Where the guard is false but the index is in bounds (for example proof (T)'s
  `m == n` false, with `i < m`), the flattened program reads the REAL cell. That
  value then goes into speculated arithmetic that a |0⟩ predicate discards.
- So the unitary equals a guard-spelled twin's, but the `_hl` literals in the trace
  do not. A byte-identity twin must spell `i <u m ? p[i] : 0`.
- Matrix CASE 15 is safe as written: its guard IS `k <u m`, so the two spellings
  coincide. A proof-(T) twin would not be.
