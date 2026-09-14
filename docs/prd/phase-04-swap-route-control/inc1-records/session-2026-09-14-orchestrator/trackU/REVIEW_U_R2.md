# Track U — ADVERSARIAL REVIEW round 2 (Rule 13), bd `z9t1` — VERDICT

**Reviewer:** independent; did not write the code, did not perform round 1.
**Subject:** `/Users/sorenwilkening/Desktop/CQ_undef`, branch `undef-seed-zero`, tip `4044e49e`.
**Probes:** `$SES/trackU/review_r2_probes/` — 5 drivers, 31 hand probes, and a
**1922-fixture two-mutant corpus sweep with a zero-twin control**.
**Scope:** the shapes round 1 explicitly did not attack — `cq_invert`/`EmitInverse`, the 4.5 `switch`,
depth-2 nests, the 6.5 classical-call arm, QRAM / I-O, multi-function, the rail bank, widths/types.

## 0. Hash gate — PASS (my first act)

```
$ shasum -a 256 <both>/build/ir-pass/cq-opt <both>/build/ir-pass/libCQPass.so
a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff  CQ_undef/build/ir-pass/cq-opt      ← brief
f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc  CQ_lang/build/ir-pass/cq-opt       ← brief
f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d  CQ_lang/build/ir-pass/libCQPass.so ← brief
$ git -C CQ_undef rev-parse HEAD  →  4044e49ea239bd4ce1a70457dbf5d17718714886   ← brief
```
All three match the brief character-for-character; the subject tip matches. Proceeded.
(`CQ_undef/build/ir-pass/libCQPass.so` = `957d2e14…` is not pinned by the brief and is not used by any
measurement below — every `cq-opt` invocation runs the pass built into the `cq-opt` binary itself.)

---

## VERDICT: **CLEAR-WITH-ITEMS**

No over-accept and no silent miscompile found on any surface in the brief's lead list. The central
result is a **closure**, not a spot check:

> **On all 1922 fixtures that contain a `@cq_theta_*` call, `SUBJECT(undef seed)` is
> indistinguishable from `ORACLE(concrete-zero seed)` — 0 real divergences.**

That is the strongest statement this project's methods can produce without a simulator (Rule 2): it says
the rule's *entire observable effect anywhere in the pass* is "the seed denotes the type's zero", across
every shape the corpus encodes — switch, nests, QRAM, I-O tape, the 6.5 arm, loops, `break`, the peel,
F1/F2 and the uncompute spine. Three items follow, none of them a correctness defect in the rule.

| id | claim | severity |
|---|---|---|
| **F-U2-1** | the guard-1 count drop can land on a **SIGABRT**, not only on a silent compile — round 1's F-U1-1 mechanism with a consequence round 1 did not observe | crash-instead-of-loud-decline (**not** a miscompile; pre-existing path, hand-IR only) |
| **F-U2-2** | the record's "**i.e.** only where the object was undefined on BOTH edges" is false, and the false half is load-bearing: it silently disarms `MergePhiPeel`'s **P3b**, a deliberate decline-*keeping* gate | documentation / record + missing retirement trigger |
| **F-U2-3** | round 1's corpus sweep **structurally cannot move** on this change; the clearance it records is narrower than its wording | fixture / record hygiene |

---

## The instrument (read this before the findings)

Round 1 swept the corpus **unmutated**. That sweep cannot move on this change, because the shipped
corpus contains no whole-value `undef` theta seed (F-U2-3). So round 2's instrument **injects** one.

`mutate_core.py` rewrites the arg-0 of every `@cq_theta_<sfx>` **call site** to either `undef` or the
type's **concrete zero**, producing two parallel mutant corpora from the same source. `sweep3.sh` then
takes three verdicts per fixture on the *same* modules:

| | |
|---|---|
| `O_u` | ORACLE on the undef-seed mutant — what HEAD does with an undef seed |
| `S_u` | SUBJECT on the undef-seed mutant — what bd `z9t1` does with it |
| `O_z` | ORACLE on the **zero**-seed mutant — what "the seed **is** zero" means at HEAD |

**The rule's whole claim is `S_u == O_z`, exactly and everywhere.** Any row where they differ is the rule
doing something other than substituting a zero — which is precisely the round-2 question, and it is a
question a verdict-only sweep (round 1's) cannot ask.

```bash
python3 mutate_core.py undefall /tmp/cqu_r2_mall     # 1922 mutants, 0 unknown types
python3 mutate_core.py zeroall  /tmp/cqu_r2_zall     # 1922 mutants, same set
./sweep3.sh /tmp/cqu_r2_mall /tmp/cqu_r2_zall sweep3all.txt 5     # → sweep3all.txt
```

**Two instrument defects I found in my own harness and fixed before trusting it** (Rule 12c — a probe
that pins nothing is worse than no probe):
1. the first mutator rewrote `declare` **prototypes**, producing invalid IR (`declare i32 @cq_theta_si32(undef, double)`);
2. it matched `@cq_theta_` inside **FileCheck comment lines**, then ran the argument scan across newlines
   and joined comments — 27 fixtures reported "mutated" while mutating **nothing**. Both are fenced in
   `mutate_core.py` and the fix is documented in its docstring. A vacuity control now runs over every
   generated mutant (`1 of 1922` equals its source, and that one is
   `control_inplace_ry_reject_stateprep_undef_seed.ll`, which already had an undef seed — correct).

### Result — `S_u` vs `O_z`, 1922 fixtures

| | count | reading |
|---|---|---|
| `EQ` | **1000** | byte-identical output IR, or byte-identical stderr for a decline pair |
| `DIFF` | **915** | **all header-only** (`ModuleID` / `source_filename`, an artefact of the two mutant directories). Re-classified mechanically: **0 of 915 contain a non-header line** — see `sweep3all_diff/MANIFEST.txt` |
| `CLASS` | 4 | the **phi half** of the rule, which the zero-twin control does not emulate (it rewrites only arg-0). All four are `control_inplace_ry_reject_stateprep_{undef,poison}_{seed,incoming}.ll`, where the mutant has an undef seed **and** an undef merge incoming; the subject normalizes both and accepts, the zero twin leaves the incoming undef and F1 declines. Expected and by design |
| `DIFFMSG` | 3 | `control_inplace_ry_reject_stateprep_constexpr_seed.ll` (blast radius **SAME**; only `O_z` moved, because my own zero-mutation rewrote a `ConstantExpr` seed) + the **2 SIGABRT rows of F-U2-1** |

**Real divergence: 0.** Blast radius `O_u → S_u`: 879 SAME, 528 A→A, 391 D→A, 124 D→D, and — the number
that matters for the Prime Directive — **0 A→D anywhere: the rule introduces no over-decline.**

### The brief's lead list, per surface — every one genuinely exercised

`moved_by_rule` = rows where `O_u != S_u`, i.e. where the rule actually changed the verdict, so the
column is not padded by fixtures the rule never touched.

| surface | rows | moved by rule | **not equal to the zero twin** |
|---|---|---|---|
| 4.5 `switch` | 66 | 23 | **0** |
| depth-2 nests | 78 | 31 | **0** |
| QRAM | 88 | 33 | **0** |
| I-O tape | 30 | 25 | **0** |
| `io_` | 41 | 26 | **0** |
| 6.5 classical-call arm | 44 | 20 | **0** |
| `cq_invert` | 11 | 5 | **0** |
| loops | 177 | 74 | **0** |
| `break` | 29 | 8 | **0** |
| `MergePhiPeel` | 42 | 26 | **0** |
| `select` | 301 | 150 | 1 (an F-U2-1 crash row) |
| `measure` | 98 | 60 | **0** |

All twelve theta width suffixes received an undef seed (`si32 i1 f64 f80 f32 sll f16 ui32 si16 si8 si32x ull`).

**Undef surviving into an emitted gate operand on the subject: 2 of 1922** —
`lowering_accept_undef_literal_{single_slot,two_functions}.ll`, and in both the zero twin emits the same
thing. That is the deliberately **blessed** single-slot angle case, not a new one. No new undef reaches
any gate anywhere.

---

## F-U2-1 — the guard-1 count drop can land on a **SIGABRT**, not only on a silent compile

**Claim.** bd `z9t1` removes `undef` literals from gate slots, which drops
`declineUnpairedUndefLiterals` (GUARD 1) below its threshold of two and lets the pass proceed. Round 1's
F-U1-1 recorded the consequence as *"a module the ORACLE declined compiles silently"*. **It is not always
a silent compile: on 2 of 1922 corpus mutants the pass instead runs into a pre-existing broken-module
path and ABORTS (exit 134), where the oracle gave a clean, source-located, exit-1 decline.**

**Probe.** `/tmp/cqu_r2_mall/control_swap_reject_select_stalecond_phi_routed.ll` (and
`…_router_diamond.ll`), regenerable with `python3 mutate_core.py undefall /tmp/cqu_r2_mall`.

```bash
$ CQ_lang/build/ir-pass/cq-opt -passes=cq-lowering -S /tmp/cqu_r2_mall/control_swap_reject_select_stalecond_phi_routed.ll -o /dev/null
error: … cq literal integrity: undef/poison literal reaches two emitted gate operands      → exit 1
$ CQ_undef/build/ir-pass/cq-opt -passes=cq-lowering -S /tmp/cqu_r2_mall/control_swap_reject_select_stalecond_phi_routed.ll -o /dev/null
PHI node operands are not the same type as the result!
  %r = phi double [ %h, %a ], [ %h, %b ]
LLVM ERROR: Broken module found, compilation aborted!                                      → exit 134
$ CQ_lang/build/ir-pass/cq-opt -passes=cq-lowering -S /tmp/cqu_r2_zall/control_swap_reject_select_stalecond_phi_routed.ll -o /dev/null
  … identical abort …                                                                      → exit 134
```

**Both verdicts.** `O_u` = exit 1, loud house decline. `S_u` = exit 134, `VerifierPass` `report_fatal_error`.
`O_z` = exit 134, **identical**.

**Reading, stated precisely so it is not over- or under-claimed.**
* The broken-module path is **PRE-EXISTING at HEAD**: the oracle aborts on the concrete-zero twin. The
  defect is that the tainted-value RAUW-to-handle leaves a **dead tainted `double` router phi** ill-typed
  (`%r = phi double [%h,…]` with an `i32` handle) — the f64/angle cross-type-RAUW family. **bd `z9t1` is
  not its author.**
* What bd `z9t1` contributes is a **new route into it**: the undef spelling previously stopped at guard 1.
  This is CLAUDE.md's own distinction (bd `1m5p`): *"'pre-existing' is true of the defect and FALSE of its
  population"*.
* **Not reachable from C.** I attempted it (`c1_dead_fp_router.c`): `clang -O1` deletes the dead router
  phi — measured `phi double` count in stage 1 = **0**, and the subject compiles it at exit 0. The shape
  exists in hand IR only, which is the fixture layer, not the C pipeline. **Oracle-on-undef D134 across
  the whole sweep: 0; subject-on-undef: 2; oracle-on-zero: 2.**

**Severity.** Crash-instead-of-loud-decline (Rule 1: *"decline loudly, never crash"*), **not** a
miscompile and **not** an over-accept: nothing wrong is emitted, `opt` exits non-zero either way.

**Minimal fix.** **None inside `z9t1`** — adding an arg-1/guard-1 conjunct is explicitly an owner ruling
and the implementation comment forbids doing it on developer judgement. Two actions instead:
1. **Carry this to the owner with the F-U1-1 disposition**, which is already open. The four measurements
   F-U1-1 was held on describe a *silent compile*; this adds a fifth outcome — an abort — to the same
   mechanism, and it is the kind of fact that can change a ruling.
2. **File the real defect separately** (a `bd` issue against the RAUW-to-handle path): a tainted fp phi
   with no remaining tainted user is RAUW'd to an `i32` handle and reaches the verifier ill-typed. It
   should be a loud decline, not an abort.

---

## F-U2-2 — "**i.e.** only where the object was undefined on BOTH edges" is false, and it silently disarms P3b

**Claim.** `RotationLowering.cpp` states the phi clause's scope as:

> *"A phi incoming is normalized ONLY when that phi carries THIS theta's result as another incoming —
> i.e. only where the object was undefined on BOTH edges."*

The **"i.e." is a false equivalence.** "Carries the theta's result" does **not** imply "undefined on both
edges", and the code implements the former. Round 1's F-U1-2 already recorded that *"ONE OBJECT, READ
TWICE is a C-level story the IR cannot carry"*; **what is new here is a measured consequence with a name
attached** — the gap flips a shipped, deliberately decline-*keeping* gate.

**Probe.** `pC_peel_p3b_carrier.ll` + its zero twin, driven by `./pdrive.sh pC_peel_p3b_carrier`. It is the
shipped P3b negative shape (`ir-pass/test/control_peel_reject_undef_incoming.ll`) with one change: the
undef-carrying merge phi also carries the theta's result, and the seed is undef.

```llvm
  %1 = tail call i32 @cq_theta_si32(i32 noundef undef, double noundef 5.000000e-01)
  …
  %6 = phi i32 [ %1, %3 ], [ undef, %0 ]    ; a DIFFERENT C object; undefined on ONE edge
```

**Both verdicts.**
```
oracle (undef)     : cq controlled lowering: control flow under quantum control                      [P3b REFUSED the peel]
subject(undef)     : cq controlled lowering: state prep seed is proven equal to the condition register [peel FIRED, F2 declined]
oracle (zero twin) : cq controlled lowering: state prep seed is proven equal to the condition register [identical]
```

**Reading.** `MergePhiPeel`'s P3b (`MergePhiPeel.cpp:238-261`) refuses to peel a phi with an
`undef`/`poison` incoming, and its own comment calls this *"the decline-keeping option"* on the ground
that a peel would put the literal into **two emitted gate slots** (the controlled copy and its `_unc`) —
i.e. guard 1's population. bd `z9t1` rewrites exactly those incomings, so **P3b stops firing for every
phi that carries a normalized theta's result.**

**This is sound, and that is why it is a documentation item and not a correctness one.** P3b's hazard is a
literal read as *two different values*; after normalization the incoming is a concrete `i32 0`, which is
single-valued — the same reason the fixture header gives for why `freeze` **is** peeled. And the measured
behaviour is byte-equal to the zero twin. But the argument is nowhere in the tree, the interaction is
unrecorded, and the record positively asserts a scope that does not describe the code.

**Severity.** Documentation / record, plus a **missing retirement trigger** (CLAUDE.md standing lesson
L8 — *"write RETIREMENT TRIGGERS into fixture headers; they work"*).

**Minimal fix** (three edits, no code):
1. In `RotationLowering.cpp`, replace the false "i.e." with what the code does: *"…when that phi carries
   THIS theta's result as another incoming. That is a SUPERSET of 'the same object read twice': a phi
   `[%theta, arm], [undef, pred]` is a different C object undefined on ONE edge, and its incoming is
   rewritten too. Each rewrite is independently a refinement of an `undef`, so the widening is sound —
   but it is a widening, not the narrow one-object rule."*
2. Add the P3b interaction to that paragraph, naming `MergePhiPeel.cpp`'s P3b clause and why the
   normalized incoming satisfies P3b's own single-valuedness argument.
3. Add a retirement trigger to `control_peel_reject_undef_incoming.ll` and
   `control_peel_reject_poison_incoming.ll`: *"this fixture's phi does NOT carry a theta result, which is
   the only reason bd `z9t1` leaves it alone. Make the phi carry one and P3b stops firing — see
   `review_r2_probes/pC_peel_p3b_carrier.ll`. Do not delete it; re-derive it."*

---

## F-U2-3 — round 1's corpus sweep structurally cannot move on this change

**Claim.** `corpus_u.sh` runs the **unmutated** corpus through both binaries. The shipped corpus contains
**no whole-value `undef` theta seed** except the three fixtures the subject's own commit added or edited,
so that sweep's population is one whose verdicts the rule cannot change. It is a sound *regression*
question ("did anything shipped move?") and a weak *clearance* one, and round 1's write-up reads as the
latter.

**Probe / measurement.** `python3 mutate_core.py undefall …` reports **1922 of 1928** fixtures contain a
theta call; a constant-seed census gives **509**, and the remaining 1413 seed from SSA. Running the
sweep on constant seeds alone left the brief's own lead list barely touched — **switch 4/66, QRAM 4/88,
`io_` 1/41, 6.5 arm 1/44, `break` 0/29** — because those fixtures seed from `%u0`. Extending the mutation
to SSA seeds (`undefall`) is what lifted coverage to the table above.

**Severity.** Fixture / record hygiene — the same class as CLAUDE.md's *"a number that measures the wrong
program"*.

**Minimal fix.** Commit the round-2 instrument with the increment (`mutate_core.py` + `sweep3.sh` +
`sweep3all.txt`) and state in `IMPL_U.md` which question each sweep answers: the round-1 corpus sweep
answers *"nothing shipped moved"*; the zero-twin injection sweep answers *"the rule is exactly
`undef ⇒ zero`"*. Neither substitutes for the other.

---

## What I attacked and found CLEAN — the positive record

A clearance with no attack record is worth nothing (brief), so this is the evidence, not a summary.

**1. `cq_invert` / `EmitInverse` — the brief's start point. Clean, with a structural reason.**
`cqrt_alloc_<W>` is **not in `isInverseEmittable`'s accept set** (`EmitInverse.cpp`: uncontrolled and
controlled `cqrt_ry_/rz_`, `cqrt_x`, `cqrt_cswap`, `cqrt_toffoli`, `cqrt_cnot`, `@__cq_q_*`). **No adjoint
ever re-emits a seed**, so the seed occupies exactly one emitted slot and there is no forward/adjoint
pairing for the rule to break. Measured, not just read: `v01_invert_escape` (escape over a normalized
uncontrolled prep), `v02_invert_chained` (a chained theta on a normalized rail — its SSA arg-0 is
correctly untouched), `v03_invert_region_arm` (a region arm's normalized theta). All three: the only IR
difference against the oracle is the alloc seed, and the **emitted gate stream is identical to the
zero twin**:
```
v01: cqrt_alloc_i32(i32 0) / cqrt_ry_i32(%h, 5.0e-01) / cqrt_addc_i32(%h, 3)     GATE STREAM IDENTICAL
v03: cqrt_alloc_i1(i1 false) / cqrt_ry_i1(%h, 5.0e-01) / cq_template_zext_i1_to_i32(%h)  GATE STREAM IDENTICAL
```
The 11 `invert` corpus fixtures (5 moved by the rule) are all `S_u == O_z`.
Note for the record: the pass has **no** `__cq_invert_begin/_end` recognizer (`starts_with("cq_invert_")`
does not match `__cq_invert_begin`), so Phase-8 manual inversion is not built; only the `cq_invert_*`
**escape prefix** exists today, and that is what I probed.

**2. Rule 2 — I read STREAMS, and I linked and RAN.** Nine end-to-end probes through the full pipeline
(stage 1 → subject lowering → stage 2b `free_pairing_check.py` → link → run), each against an
explicit-zero twin C program compiled through the **oracle**:

| probe | result |
|---|---|
| `t1_uncontrolled` `bool b; b=cq_theta(b,.5)` | trace **byte-identical** to twin, 3 lines |
| `t2_in_region` (the second ruled spelling) | **byte-identical**, 3 lines |
| `t3_f64`, `t5_f80` | **byte-identical**; `cqrt_alloc_f64(0x0p+0)` / `cqrt_alloc_f80(0x0p+0)` |
| `t4_cascade` (the owner's two-bool shape) | **byte-identical**, 29 lines, STRICT 2b `8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven` |
| `a1_uncompute_spine` (arithmetic on a normalized rail) | **byte-identical**, 7 lines |
| `m1/m2/m3` multi-function | **byte-identical** (see 4) |

I read the 29-line cascade stream against the invariants CLAUDE.md §4b states for it: `h0`/`h1` are read
**only as `cqrt_cnot` controls** and measured once — never `cqrt_x`-bracketed, never freed; the four
`cqrt_x` sit on the ancillas `h2`/`h7`, whose `x ⊕ x = 0` return is what makes their two `cqrt_free`
proven-`|0⟩`; the `cqrt_ry_i1_controlled(h0,h1,-0x1p-1)` negated prep is present. Nothing about the
stream changes when the seed is uninitialized rather than written `= 0`.

**3. The 124 D→D decline-message movers — every one lands exactly on the zero twin.** I read all 16 from
the constant-seed sweep by hand. They move `state prep seed does not match the merge incoming` into
`state prep merged with a quantum register`, `control flow inside a loop body`, `condition measured
before the control route`, `control flow`, and — the one that answers the brief's lead 4 directly —
`state prep seed is proven equal to the condition register`
(`control_inplace_ry_reject_stateprep_nonwire_still_collides.ll`, `…second_cmp_onwire_{merge,pred}.ll`,
`…zext_flag_i32seed.ll`, `control_peel_reject_fp_stateprep.ll`, `…handwritten_clone_i1.ll`). **So F2 is
not disarmed by the rule — it is handed a concrete value and it still fires.** The record's claim that
the rule "can only ever produce a FRESH prep" is therefore *not* load-bearing for safety: even where a
normalized zero does collide with a live value, F2 declines exactly as it does for a written `0`.
(One row, `control_inplace_ry_reject_stateprep_cond_qq.ll`, shows an empty message in the tally only
because its diagnostic — `no template for opcode 'icmp i1' in tainted context` — has no `cq ` prefix and
escaped my tag regex. It is a loud house decline, not a crash, and `S_u == O_z ==` the shipped fixture's
own verdict. PROTOCOL S3's "the shared tag regex hides things" warning, hit again.)

**4. Multi-function, inlining, dead code (lead 5).** `m1_noinline_callee` (theta with an undef seed in a
`noinline` callee called twice), `m2_alwaysinline`, `m3_dead_function` (an undef-seeded theta in a
function nothing calls, beside a live one). All three: trace **byte-identical** to the zero twin, 2b
clean. `m1`'s trace legitimately carries no `cqrt_measure_` line — taint does not cross the `noinline`
return, so `cq_measure` in `main` is the bd `21mg` never-quantum path — and the oracle does exactly the
same, so it is HEAD behaviour, not this rule. Round 1's F-U1-3 argument (`SpecializeReject::scanBody`
rejects rotation-bearing bodies; duplication is monotone) is consistent with what I measured.

**5. The phi half, attacked directly** — `pA_peel_p3b.ll`, `pB_phi_three_edges.ll` (a 3-incoming phi with
undef on **two** edges, which the rule rewrites wholesale), `pC_peel_p3b_carrier.ll`. All decline
identically to their zero twins (`control flow`, `tainted value muxed by a classical-condition phi`, and
F2 respectively). The widening is real (F-U2-2) and its outcome is the zero twin's, everywhere I could
reach it.

**6. Widths and exotic types (lead 7).** All 12 theta suffixes exercised by the sweep including `f80` and
`f16`; `t3`/`t5` link-and-run at `f64`/`f80`. A vector (`<2 x double>`), an `i128` and a `ptr` theta
(`ty1`/`ty2`/`ty3`) are adjudicated by `declMatchesPrototype` — `cq rotation lowering: unsupported
declared prototype` — **identically on both binaries**, so `Constant::getNullValue` is never asked for a
type where its value would be non-obvious. The implementation comment's precondition holds.

**7. The rail bank (lead 6).** `r1_rail_bank.c` (`bool b[2]` uninitialized, rolled loop) declines
`cq taint escape: tainted value stored to memory` on **both** binaries, at the same source column — Track
L's recorded wall, unchanged. **Composition statement for when bd `xdu2` L-1a lands:** an uninitialized
`bool b[N]` reaches the theta through a **load from an `alloca`**, not as a whole-value `undef` operand,
so `valueCarriesUndef`/`isa<UndefValue>` are both false and **bd `z9t1`'s rule does not reach it**. The
bank will need its own decision about an uninitialized element, and it cannot inherit this ruling by
analogy — the ruling is about a `Constant` operand at a call site.

**8. Ruling clause 4 holds.** `a2_measure_undef.c` — `cq_measure` of a never-quantum `undef` still
declines on the subject, byte-identical message to the oracle (`cq_measure_<sfx> operand is an
undef/poison literal; a classical measurement needs a defined …`). The asymmetry the ruling requires is
intact.

**9. Rule-11 spot-check (my one permitted fixture re-run, ×2).** The subject's own new fixtures
`lowering_accept_undef_theta_seed_zero.ll` and `control_accept_undef_theta_seed_stateprep.ll` piped
through the **subject** binary and `FileCheck`: both **PASS**. They are not vacuous.

**10. L1 / round-2 fixpoint (lead 3), from source.** The normalizer neither creates values nor grows the
taint set — it calls `setArgOperand` and `setIncomingValue` on operands of an already-tainted theta and
its already-tainted phi users — so it is **not a taint-GROWTH event** and owes `adjudicateTaintDelta`
nothing. It mutates no instruction list, so `collectAndSeed`'s iteration stays valid. Being inside
`propagate` it re-runs at every fixpoint round and is idempotent (a rewritten operand is no longer an
`UndefValue`). I found no stage between the last `propagate` and `lowerRotations` that re-introduces an
undef seed, consistent with round 1's F-U1-3.

---

## What I did NOT examine — stated plainly

* **No build and no suite** (brief). Every number above is a two- or three-binary measurement on the
  prebuilt binaries, plus `FileCheck` on 2 fixtures. **Nothing here is a claim that `ctest` is green.**
* **The mutation is SEED-ONLY.** I did not inject undef **angles**; that is round 1's F-U1-1 territory and
  the brief excluded re-litigating it. F-U2-1 is reported as new because its *consequence* (an abort) is
  new, not because its mechanism is.
* **The phi half is the least-measured clause.** It has 4 corpus rows and 3 hand probes. I did **not**
  build a phi-incoming injection sweep — synthesizing a well-typed undef incoming on a
  theta-carrying phi mechanically, across 1922 fixtures, is not something I could do soundly in this
  round. If the owner wants a round 3, **this is the one surface that would justify it.**
* **No simulation, no statevector** (Rule 2, owner decision 2026-06-10). Every correctness claim rests on
  the zero-twin equivalence plus stream reading — i.e. "the rule computes what a written `0` computes" —
  never on a physics argument.
* **Track F's parallel φ-descendant F2 conjunct.** I measured the **Track U binary only**, as instructed.
  **Interaction the merge gate must test:** Track U makes a seed a *concrete constant, earlier*, and I
  measured that F2 still fires on normalized zeros (see 3 above). A φ-descendant conjunct added in Track F
  will therefore see an F2 seed population that now contains values it never saw at HEAD. The merge gate
  should re-run the whole F2 fixture family **with both changes present**, not either alone.
* **QRAM / I-O** were covered by the corpus sweep (88 + 30 + 41 rows, 84 moved, 0 divergences) but by **no
  hand-written QRAM or output-tape probe** and by no linked-and-run QRAM slice.
* **`cq_invert_begin/_end`** (the `CQ.h` bracket macros) — not recognized by the pass at all, so there was
  nothing to attack; I probed the `cq_invert_*` escape prefix instead.
* **Phase-6 specialization clones** were reasoned about from source and from round 1's F-U1-3, not
  re-probed directly.
* **I did not re-litigate F-U1-1**, per the brief. F-U2-1 is filed as a new composition with its own probe.

---

## Round 3: **NOT WARRANTED** on this surface — with one narrow exception

CLAUDE.md's measured hit rate says the next round finds something, and I take that seriously. The reason
I still say "not warranted" is that the decisive instrument here is a **closure over the whole corpus**,
not a sample: `S_u == O_z` on 1922 fixtures says the rule's entire observable effect is the substitution
it claims, on every shape the tree encodes. A further round attacking *more shapes* is attacking a
question that has already been answered uniformly.

**The exception is the phi clause.** It is the half the zero twin cannot emulate, it is the half whose
recorded scope is wrong (F-U2-2), and it is measured on 7 modules rather than 1922. A **narrow** round 3
over an injected-phi-incoming corpus would be defensible, and I would scope it to exactly that.

**Before the merge gate**, regardless of a round 3: the two documentation edits in F-U2-2, the record edit
in F-U2-3, and **F-U2-1 in front of the owner alongside the open F-U1-1 disposition** — the ruling was
held on four measurements that all describe a silent compile, and there is now a fifth outcome.
