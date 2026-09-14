# Track D — ADVERSARIAL REVIEW round 2 (Rule 13), bd `3d8q` — the STALE-READER fence

**Reviewer:** independent; did not write the code and did not perform round 1.
**Round:** 2 of a ≥3-round budget. **Subject:** branch `stale-reader-fence`, tip `bc24b009`.

**Verdict: NOT CLEAR.** One over-ACCEPT in the unforgivable class (F-D2-1): a measured, live
exploit of a gap `WireWalk.h` itself documents, measured as *"NOT EXPLOITABLE"* on 2026-09-04, and
guards with a written retirement trigger that says **"WIDEN THE VOCABULARY (or fence the caller) IN
THE SAME CHANGE."** `readerStalesItself` is the new granting caller that trigger names; it was added
in this change and the trigger was neither honoured nor noted. Two probe programs that differ by
**one operand of one φ** emit **byte-identical traces**, which is bd `3d8q`'s own definition of the
defect. Four further findings below.

**The landed predicate itself is correct and moves nothing it should not** — the verbatim leg-2 split
is byte-verified, the four fixture conversions are right, 373 e2e slices are unmoved, and the four
round-1 carry-overs are properly disposed (one of them is now *measured* rather than read off a
header). The failure is in what the new caller was allowed to lean on.

---

## 0. First act — binary identity (the brief's STOP condition)

```
shasum -a 256 /Users/sorenwilkening/Desktop/CQ_3d8q/build/ir-pass/{cq-opt,libCQPass.so}
shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}
```

| | measured | brief |
|---|---|---|
| SUBJECT `cq-opt` | `0f3d512529c5d1066fc82b38f21444efbe17088fe344a4c83f67cd2eee93c672` | **match** |
| SUBJECT `libCQPass.so` | `4dc93cff90b658f2721b1c3fb1c5da6f6bf3575c360cba17bc26b9bb44a5964a` | **match** (prefix) |
| ORACLE `cq-opt` | `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc` | **match** |
| ORACLE `libCQPass.so` | `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d` | **match** |

All four match; `git log -1` on the worktree is `bc24b009`. Proceeded. Every ORACLE-vs-SUBJECT row
below is a statement about the edits alone.

Probes: `trackD/review_r2_probes/` — `m.sh` (stage 1 generated ONCE per probe, the SAME `.ll` fed to
both binaries, **zero-byte modules refused**), `src/` (78 modules, 45 new this round), `s1/`,
`ORACLE/`, `SUBJECT/`, plus `e2e_sweep.sh`/`.txt`, `scan_r5.py`, `post_measure_scan.py`,
`vh_probe.cpp`. No probe was skipped for the zero-byte reason.

---

## F-D2-1 — OVER-ACCEPT / SILENT MISCOMPILE. `readerStalesItself` is the third GRANTING caller of `phiTracksWire`, and it makes the documented dtzb vocabulary gap live. Two different programs, one circuit

**Severity: over-ACCEPT / silent miscompile — the unforgivable class.** Present on the ORACLE too, so
it is not a *regression*; but the increment is what put a caller in front of it, against a written
instruction, and the in-tree justification for the gap is now false.

### The probe pair

`review_r2_probes/src/oa1_phitracks_inplace_add.c` and `…/oa1t_alias_twin.c`:

```c
/* oa1  */ for (i<3) { int a = cq_theta(q,0.1); int d = a+1; s += cq_measure(d); q = a; }
/* oa1t */ for (i<3) { q = cq_theta(q,0.1);     q = q+1;     s += cq_measure(q);        }
```

`oa1` carries the **pre-add** name forward; `oa1t` carries the **post-add** name. After `clang -O1`
the two stage-1 modules differ in **exactly one operand of one φ** (`review_r2_probes/s1/`):

```
oa1 : %4 = phi i32 [ %1, %0 ], [ %7, %3 ]      ; carries %7 — the THETA result, PRE-add
oa1t: %6 = phi i32 [ %1, %0 ], [ %8, %3 ]      ; carries %8 — the ADD result,   POST-add
```

### Commands and both verdicts

```
cd $SES/trackD/review_r2_probes && ./m.sh src/oa1_phitracks_inplace_add.c src/oa1t_alias_twin.c \
                                          src/oa1s_straightline_analogue.c src/oa1v_noloopcarry.c
```
```
oa1_phitracks_inplace_add  | O=A[trace=11] | S=A[trace=11] |
oa1t_alias_twin            | O=A[trace=11] | S=A[trace=11] |
diff SUBJECT/oa1_phitracks_inplace_add.trace SUBJECT/oa1t_alias_twin.trace
*** TRACES BYTE-IDENTICAL ***
```

The emitted stream (both, SUBJECT), per trip:

```
cqrt_ry_i32(h0, 0x1.999999999999ap-4)    ; the .1 rotation
cqrt_addc_i32(h0, 1)                     ; THE ADD IS IN PLACE — h0's label is relabelled
cqrt_measure_i32(h0) -> 0
```

`cqrt_addc_<W>` is the in-place rail op (`runtime/cq_runtime.h:413`: *"h := (h + imm) mod 2^W"*), and
only ONE handle exists. So trip 2's `cqrt_ry_i32(h0,.1)` fires on the **post-add** register — which is
`oa1t`'s circuit. `oa1` says trip 2 rotates the state `a` denotes, i.e. the **pre-add** one.
**Two different well-formed programs, one circuit, `opt` exit 0, verify-clean.**

### The compiler already gets the straight-line twin RIGHT, which is what makes this a defect and not a semantics question

`oa1s_straightline_analogue.c` has the identical data-flow property (`a` used after the add site),
spelled without a loop:

```
cqrt_ry_i32(h0, 0x1.999999999999ap-4)
cq_template_add_i32_hl(h0, 1) -> h1       ; OUT OF PLACE — a FRESH rail for `d`
cqrt_measure_i32(h1) -> 0
cqrt_ry_i32(h0, 0x1.999999999999ap-3)     ; `a`'s rail, untouched.  CORRECT.
```

`ArithLowering::classifyInPlaceReassignment` cannot be the in-loop owner — it returns `false` for any
site inside a loop (`ArithLowering.cpp:695`) — so the in-place conversion came from the loop path, and
its "later use" clause **does not count the rail φ's latch incoming**. Localised by two controls:

| probe | shape | verdict |
|---|---|---|
| `oa1u_inbody_later_use` | the later use of `a` is **in the body** | **D** `cq loop lowering: loop-carried rail has multiple in-place consumers` — the clause exists and fires |
| `oa1` | the later use of `a` is **through the back edge** (the φ's latch incoming) | **A**, in place — the same clause does not fire |
| `oa1v_noloopcarry` | no loop carry at all | **A**, `cq_template_add_i32_hl` out of place (correct) |

So the loop path converts in place **precisely because the rail is loop-carried** — and the loop carry
IS the later use that should refuse it. It assumes the φ carries the op's RESULT; when it carries the
op's OPERAND, nothing checks.

### Why this is THIS increment's finding and not merely a pre-existing one

`ir-pass/include/WireWalk.h:223-243`, verbatim, above `phiTracksWire`:

> *"THE VOCABULARY THAT MAKES THAT MATTER: this predicate is spelled over `thetaOnPathTo`, which
> counts a `cq_theta` as a staler and does NOT count the dtzb in-place `add`/`xor` … So in the
> GRANTING direction **a φ whose wire moved only by a dtzb `add` between its incoming and its edge
> would be granted a refresh it did not earn.** MEASURED 2026-09-04 (5 probes, HEAD): **NOT
> EXPLOITABLE** …"*
> *"Any third caller must state which direction it uses before relying on the sentence above."*
> *"RETIREMENT TRIGGER, THREE WAYS: … Any of the three makes this predicate the only wall, and the
> dtzb gap becomes live — **WIDEN THE VOCABULARY (or fence the caller) IN THE SAME CHANGE.**"*

`oa1` **is** that sentence's shape, word for word, and it **is** exploitable. The 2026-09-04
"NOT EXPLOITABLE" argument rests on two walls that stand in front of the two *then-existing* callers —
`ArmClassify`'s R6 phi-edge read-position rule and `collapseRailPhisIn`'s loop-carried guard. Neither
stands in front of `readerStalesItself`: `oa1` has no control region for R6 to refuse and it passes
`kMsgCrossIter` (it accepts). **This increment added the third granting caller the header warned
about, the gap became live in the same change, and neither the widening nor the caller-fence the
header prescribes was made — nor is the new caller's reliance on the granting direction stated.**

Traced on `oa1`, against the code as landed — the accept depends **entirely** on the grant:

* reader `%7 = cq_theta(%4,.1)`, record `%4` (the rail φ).
* `readerStalesItself(%7,%4)`: leg 1 `reachesWithoutBarrier(%7,%7,{})` → **true** (the cycle).
* leg 2 `recordBarrierCutsPath(%7,%7,%4,{%4})` opens `if (auto *SeedPhi = dyn_cast<PHINode>(SeedDef))
  if (!phiTracksWire(SeedPhi)) return false;` — **so a `false` here is a DECLINE.**
* `phiTracksWire(%4)`: latch incoming `%7`; `thetaOnPathTo(%7, latch-term)` sees only `%8` (the
  `add`), `%9` (the measure) and the IV arithmetic — **no `cq_theta`** → `false` → **tracks** →
  barrier `{%4}` → the back edge crosses it → `recordBarrierCutsPath` = true →
  `readerStalesItself` = **false** → exemption GRANTED → ACCEPT.

### Minimal fix — the header's own first option, and the probe pair validates it exactly

Widen `thetaOnPathTo`'s `Stales` predicate (`WireWalk.cpp:162-167`) to count a dtzb in-place
`add`/`xor` on the wire as a relabelling event, which is what `LoopLowering::collectRailGates` and
`CLAUDE.md` CORRECTNESS RISK §2 already count. Hand-traced on the pair:

| module | φ's latch incoming | is a relabeller after it? | `phiTracksWire` | verdict |
|---|---|---|---|---|
| `oa1` | `%7` (theta) | **yes** — `%8`, the in-place `add` | **false** | **DECLINE** ✔ |
| `oa1t` | `%8` (the add) | no (only the measure) | true | **ACCEPT** ✔ |

The widened vocabulary separates them exactly, which is the property any fix must have.
⚠ **Two caveats the implementer must carry.** (i) `thetaOnPathTo` feeds `phiTracksWire`, which has
other callers **in the granting direction** (`ArmClassify::recordLivePerActivation` R6) and in
`recordBarrierCutsPath`'s general path — the header says so, and widening it moves an ACCEPT-direction
predicate, so it needs its own Rule-13 round and a re-measurement of the 12
`control_inplace_ry_inloop_*` and `control_inplace_ry_reject_inloop_frozen_dtzb_carry.ll`.
(ii) The header offers **"or fence the caller"**, which is the narrower change: have
`readerStalesItself` refuse the φ grant when a marked in-place rail op lies between the latch incoming
and the edge. Either is acceptable; doing neither is not.
**I could not build (brief), so this fix is traced, not measured.**

### Relationship to what is already filed

Not a duplicate of either open bead, and it sharpens one:

* bd `0njv` is the **straight-line** version (a record consumed past an in-place non-diagonal gate).
  Measured here, the straight-line spelling of *this* shape is **handled correctly** (`oa1s`,
  out-of-place) — so this is a distinct, loop-only defect.
* bd `a3z7` records the same structural fact (*"the FLAT twin lowers the add OUT of place … rolled
  emits `cqrt_addc` in place (**the better circuit**)"*) as a **P3 quarantined divergence** and an
  efficiency judgement. `oa1`/`oa1t` shows the rolled form is not "the better circuit" but a
  **different program's** circuit whenever the rail φ carries the OPERAND. a3z7 should be re-raised
  to P1 with this pair attached, or a new P1 filed and a3z7 cross-referenced.

---

## F-D2-2 — OVER-DECLINE, NEW IN THIS SESSION, and OUTSIDE the 2026-09-14 ruling's own rationale

**Severity: over-decline (a defect under the owner's standing ruling), safe direction.**

```c
/* ob1_reader_runs_once_in_loop.c */
int q=cq_theta(0,0.3); int s=0;
for (int i=0;i<3;i++){ if (i==0){ int b=cq_theta(q,0.1); s+=cq_measure(b); } else s+=1; }
```

```
ob1_reader_runs_once_in_loop | O=A[trace=4] | S=D[cq opcode lowering: rotation/measure operand predates a non-diagonal gate]
ob1b_first_iteration_flag    | O=A[trace=4] | S=D[same]          (the `int first=1;` idiom)
ob1d_guarded_runtime_cond    | O=A[trace=4] | S=D[same]          (the CONTROL — correctly declined)
```

`-O1` keeps the reader in block `%7`, guarded by `%6 = icmp eq %5, 0`, and `%7` is inside the cycle
(`s1/ob1_reader_runs_once_in_loop.ll`). Leg 1 sees the cycle, leg 2's barrier `%1` is outside it, and
the exemption is withheld. **But the reader executes exactly once**, so there is no second instance to
stale it, and the ORACLE emitted the *correct* circuit — `alloc; ry(.3); ry(.1); measure`, one
rotation.

**This matters more than an ordinary conservative decline because the ruling does not cover it.** The
2026-09-14 ruling declined the in-loop invariant re-read on the ground that *"the source admits TWO
realizable circuits … and names neither."* `ob1` admits exactly **one** — the reader runs once, so the
chain reading and the re-preparation reading coincide. The ruling's own justification is absent here,
and the decline is therefore not covered by it.

`ob1d` (a genuinely repeatable guard) declines correctly and the fence cannot tell it from `ob1`, so
this is Prime-Directive-shaped and the decline is **safe**. Disposition: it is an item, not a
blocker — but it needs (a) a filed over-decline bead with this probe, and (b) a widening of the
retirement trigger already written into
`lowering_reject_stale_reader_inloop_invariant_seed.ll`, which today says *"the day the pass can prove
a loop **body** executes at most once"*. The body here executes three times; it is the **reader's own
block** that executes once. Written as "body", the trigger will not fire for this program.

Two further spellings measured and **not** over-declines: `ob9_breaking_loop_single_read` (a `break`
after the read) and `ob7_reader_in_guarded_exit` both ACCEPT unchanged.

---

## F-D2-3 — OVER-DECLINE under the owner's §14 ruling of 2026-09-14, and the fence cannot see the difference

**Severity: over-decline (defect under the standing ruling); introduced by this increment.** Full
measurement, streams and build cost in **§14** below. In one line: three programs the ruling makes
legal now decline, and their illegal twin declines with the *same message*, because `cq_measure` is
not modelled as a wire event at all.

```
m14b_measure_theta_measure_parent | O=A[trace=6] | S=D[… operand predates a non-diagonal gate]
m14c_measure_then_inloop_reuse    | O=A[trace=9] | S=D[same]
m14d_measure_then_two_siblings    | O=A[trace=7] | S=D[same]
m14e_unmeasured_two_siblings      | O=A[trace=6] | S=D[same]   <-- the ILLEGAL control, same string
```

`m14d` and `m14e` differ by one line (`int m=cq_measure(q);`) and are indistinguishable to the fence.
`m14c` is the ruled r5 shape and came from `bc24b009`; `m14b`/`m14d` are straight-line and came from
the base fence `e7d6efe2`. All three declines are **SAFE** — they refuse the chain circuit, which is
genuinely wrong for those programs — so this is a capability gap, not a miscompile.

---

## F-D2-4 — FIXTURE HYGIENE. One positive stream pin is genuinely lost, as disclosed

**Severity: fixture hygiene (Rule 12).** Disclosed by the implementer and filed; I verified it rather
than restating it.

`control_phase_kickback_mixed_claim_across_loops_leak_control.ll` carried a 13-directive positive
**stream** pin (`fix`'s `[check]` block, lines 105-124: the `and_hl` / `icmp_eq_hl` / `cqrt_x` /
`cqrt_rz_i1` / `_unc` / `cqrt_free` sequence) for the F-C1B-2 per-loop `ClaimedRailRoots` **refusal**
direction. It is now a decline fixture and that stream pin is gone. The discriminating ACCEPT half
(`…_claim_across_loops_accept_control.ll`) still accepts (measured), so the *accept* direction is
still pinned; the *refusal* direction has no positive stream pin anywhere now.

Everything else about the four conversions checks out, and each was verified rather than assumed:

| fixture | verified |
|---|---|
| `control_phase_kickback_mixed_onward_deadgate_leak_control.ll` | the module IS the ruled shape — `%20 = cq_theta(%3,.1)` in body block `%19`, `%3 = cq_theta(%0,.3)` in ENTRY, loop-invariant. **D** on SUBJECT. Its one-token CARRIED sibling `…_onward_inloop.ll` still **ACCEPTS**. |
| `control_phase_kickback_mixed_claim_across_loops_leak_control.ll` | `%27 = cq_theta(%9,.2)` in the SECOND loop, `%9 = cq_theta(%7,.1)` in the FIRST. **D** on SUBJECT. `…_accept_control.ll` still **ACCEPTS**. |
| `lowering_uncompute_loop_backedge.ll` | **D**, message moved. **The uncompute string is NOT left unpinned:** `lowering_reject_loop_nested_quantum.ll` and `lowering_uncompute_leak_irreducible_dead_spine.ll` both still decline at `cq uncompute: tainted handle live range crosses a loop backedge`, each with a **live positive `CHECK:`** on line 25 / 40 and exactly one RUN line. Measured, not cited. |
| `lowering_uncompute_loop_backedge_irreducible.ll` | same, irreducible CFG. |

Neutering hygiene is clean in both converted files: exactly **one** `RUN:` and **one** live `CHECK:`
each, 14 neutered `[check]` directives each, **no** `--check-prefix` on the RUN lines, and no stray
literal `CHECK:` directive anywhere (grep over every line, not just line starts). Each carries an L8
retirement trigger naming the ruling by date and pairing its inversion with the new decline fixture.

---

## F-D2-5 — RECORD ACCURACY (minor). "17 call sites of `gateIsHarmless`" conflates two counts

`FIX_D_R1.md` says *"`gateIsHarmless` keeps its exact previous behaviour and every one of its 17 call
sites is byte-unchanged."* Measured: **`gateIsHarmless` has exactly ONE call site**
(`WireWalk.cpp:629`, inside `walkNonDiagonalWireGates`). The **17** is the pre-existing count of call
sites of the two public walker faces — 18 external call sites of
`findNonDiagonalWireGate`/`collectNonDiagonalWireGates`, one of which is this increment's own new
reader call. **The substance is correct and I verified it independently**; only the attribution of the
number is wrong, and a future agent grepping for "17 `gateIsHarmless` call sites" will find one.

---

## Non-findings — the brief's items I verified rather than restated (Rule 11)

| # | claim | how I checked | result |
|---|---|---|---|
| 1 | leg 2 was split out **verbatim** | extracted the pre-fix `gateIsHarmless` body from `git show 78b8b35f:…` minus its two leg-1 lines, and `recordBarrierCutsPath`'s body from the tip; `diff` | **VERIFIED — byte-identical.** `gateIsHarmless` is therefore behaviourally unchanged (dominance + leg 1 + a call to the moved body). |
| 1 | `gateIsHarmless` and the 17 call sites byte-unchanged | `git diff 28eac7d2..bc24b009 --` on `ArmClassify/RegionTreeDetect/SelectClassify/SwitchArmProve/SwitchClassify/LoopLowering` | **VERIFIED — empty diff.** Untouched across the *whole* increment, not just the fix round. |
| 1 | leg 1's `std::next(R)` start is non-degenerate | 4 hand-IR probes: a **single-block** loop both ways, an **irreducible** two-entry cycle, an **`indirectbr`** back edge | **VERIFIED.** `L1a` (single-block, φ-carried) **A** and byte-identical to the ORACLE with a correctly ROLLED in-place `ry`; `L1b` (single-block, invariant) **D**; `L1c` (irreducible) **D**; `L1d` (`indirectbr`) **D**. The `From`-block-not-pre-marked rule holds under all four. |
| 1 | leg 1's *"no cycle ⇒ at most once"* is sound interprocedurally | `rec1_recursive_reader` (a `noinline` recursive reader) and `rec2_called_twice` (a `noinline` helper called twice on the same tainted name) | **CLOSED by an earlier owner.** Both decline on **both** binaries at `cq specialization: callee contains a quantum primitive (cq_*)`. The recursion route is not exploitable. |
| 3 | no ACCEPT fixture contains the ruled shape | `scan_r5.py` — a text-level CFG/SCC scan of all 1940 fixtures for a `cq_theta` inside a cycle whose arg-0 is defined outside it — then **every hit measured on both binaries** | **11 hits: 4 are the converted fixtures, 6 decline at other fences, 1 is a taint false positive** (`control_phase_kickback_rail_inloop_iterlocal_invariant_seed.ll`: arg-0 is the CLASSICAL `icmp ne (and %0,1), 0`, so the theta is a per-trip SOURCE mint, correctly accepted). **No shipped ACCEPT fixture holds the shape.** |
| 3 | the landed change moves nothing in e2e | **all 391** `tests/e2e/*.c` through both binaries: verdict + sha-256 of the lowered IR (header-stripped) for accepts, md5 of stderr for declines (`e2e_sweep.sh`) | **0 movers of 373 measurable** (350 A byte-identical, 23 D stderr-identical). The 18 non-measurable are all `*_lib.c` — the second TU of multi-TU slices, with no `main`. Not a sample this time: the whole standalone corpus. |
| 3 | no over-decline in the well-formed direction | 21 further hand-built well-formed programs (`od1`–`od10`, `ob2`–`ob9`, `r5f/g/i/t`) incl. two and three independent φ-carried chains in one loop **in both orders**, `continue`, guarded inner blocks, nested loops, a 2-deep in-loop chain, an in-place add carry, and the rolled Grover customer | **20/21 unchanged A/A.** `phiTracksWire` is wire-AWARE (`thetaOnPathTo` runs a second, `collectWireValues`-scoped pass), so multi-rail loops do not over-decline and the verdict is **not** order-dependent. The one mover is F-D2-2. |
| 5 | the `WeakVH` three-outcome drain | **MEASURED, not read off the header** — `vh_probe.cpp`, a 25-line standalone linked against libLLVM-19 (19.1.7) that attaches both handle kinds and RAUWs to an Instruction and to a Constant | **`WeakVH` does NOT follow RAUW** (stays on the original; nulls only on destruction); **`WeakTrackingVH` does** (moves to the instruction, and to the constant). ⇒ the implementer's handle swap **closes F-D1-2 exactly as claimed**: a RAUW'd reader takes outcome (1) and still declines; outcome (3) is genuinely unreachable and is loud rather than silent. Round 1's reasoning was right *for the handle then in use*. |
| 5 | `diagnosePreLoopCommitStale` vacuity | per-file positive/negative directive count over the 8 fixtures carrying the string | **UNCHANGED and as disclosed: 8 files, 0 positive, 8 negative.** No pin was restored; the (b)/(c) enumeration is recorded honestly as NOT subsumed. |
| 5 | the `declineClassicalMuxes` coupling | read `TaintPropagation.h:432-436` | **RECORDED** with the L3 retirement trigger, and cross-referenced at the `Delta` filter. |
| — | the two new ruling fixtures pin what they claim | my **one permitted lit invocation**: `lit -v ir-pass/test --filter 'stale_reader'` in the subject build | **12/12 PASS** (4 accepts, 8 declines) on the binary under review, 3.57 s. |
| — | the r5 family and the must-not-move table | 24 round-1 probes re-run on both binaries | reproduced exactly as `FIX_D_R1.md` records: `r5/r5a/r5b/r5c/r5d/r5e/r5h` **D**, `r5f/r5g/r5i/r5t` **A**, `r1–r4/r6–r8/r11/r13` **A** unchanged, `r9` D, `r9b` D on the ORACLE too. |

---

## §14 — `cq_measure` as a wire event: measurement for a BUILD, after the owner's ruling

The coordinator's mid-review ruling: *"so using cq_theta after measurement is completely fine, it
just requires a c_alloc again."* Read as: after `cq_measure(q)` the name `q` denotes a **definite basis
state**, which is classical and therefore **reproducible**, so re-use is legal and lowers as a fresh
`cqrt_alloc_<W>` seeded from the outcome. Measured, not fixed. Streams inline.

### (1) What the pass emits TODAY — it CHAINS

`m14a_measure_then_theta.c` = `int q=cq_theta(0,.3); int m=cq_measure(q); int a=cq_theta(q,.5);`

```llvm
%h  = call i32 @cqrt_alloc_i32(i32 0)
call void @cqrt_ry_i32(i32 %h, double 3.000000e-01)
%m  = call i32 @cqrt_measure_i32(i32 %h)
call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)     ; <-- SAME HANDLE. No second alloc.
%m1 = call i32 @cqrt_measure_i32(i32 %h)
```
```
cqrt_alloc_i32(0) -> h0 / cqrt_ry_i32(h0, .3) / cqrt_measure_i32(h0) -> 0
cqrt_ry_i32(h0, .5) / cqrt_measure_i32(h0) -> 0
```

**It chains on the existing rail handle.** Stated explicitly, as asked: that is the delta the ruling
has to close. Identical on the ORACLE.

### (2) Are "chain on the measured rail" and "fresh alloc seeded from the outcome" the same circuit?

**For the state, yes — and this is the part that changes the shape of the build.** A projective
computational-basis measurement of the whole register leaves it in `|m⟩`, *unentangled* (the
correlation is transferred to whatever it was entangled with, as that partner's conditional state).
So `Ry(θ)` on the measured rail gives `Ry(θ)|m⟩`, and `alloc(m)` + `Ry(θ)` gives `Ry(θ)|m⟩` on a new
rail. The only difference is a **spectator qubit in a known basis state** — the old rail, still
holding `|m⟩`, which Rule 6 will **leave allocated** (it is not provably `|0⟩`, since `m` is a runtime
value). So the literal reading costs **one leaked qubit per post-measure re-use** and buys no state
change.

`m14g_entangled_then_measure_reuse.c` (a `cq_theta` under quantum control of `q`, then measure and
re-use `q`) accepts unchanged on both binaries at 12 lines, and the argument above is why: the
measurement is exactly the event that disentangles `q`. **In this runtime the distinction is
observable in the emitted STREAM (an extra `cqrt_alloc` and a different handle) and in nothing else** —
there is no simulator, so no state difference could be witnessed at any ABI (Rule 2).

**Where the two readings genuinely differ, and it is not where one would guess:** not in the
*re-use*, but in a **later read of the measured name**.

* `m14b` = `m=cq_measure(q); a=cq_theta(q,.5); m2=cq_measure(q);` — under the chain, `q` after the
  rotation denotes the **rotated** rail and `m2` samples the rotated distribution. Under fresh-alloc,
  `q` still denotes `|m⟩` and `m2` returns `m` deterministically. **Different, and the chain is
  wrong.** Today: **DECLINE** (safe).
* `m14d` = two siblings off a measured name — chain gives `ry(.5); ry(.9)` on one rail (the 3d8q
  defect); fresh-alloc gives two independent rails each seeded `|m⟩`. **Different.** Today:
  **DECLINE** (safe).
* `m14c` = the in-loop re-use — chain gives a 3-deep chain; fresh-alloc gives 3 i.i.d. rails.
  **Different**, and it is the exact conditional-probability argument the 2026-09-14 stale-reader
  ruling was made on. Today: **DECLINE** (safe).
* `m14a`, and every shape where the measured name is read **once**: **identical up to the spectator**,
  and the chain is strictly cheaper.

**The sub-question for the owner, named rather than resolved:** does *"it just requires a c_alloc
again"* mean **(a)** narrowly, a re-rotation of a measured name allocates a fresh rail seeded from the
outcome — in which case the existing single-read accepts (`m14a`, and every in-loop
measure-and-continue) would each gain a leaked qubit for no state change; or **(b)** broadly,
**taint STOPS at `cq_measure`**, so every use of the name positioned after the measurement is
CLASSICAL and a later `cq_theta` on it is an ordinary SOURCE theta? Reading (b) is simpler, subsumes
(a), is the natural completion of bd `21mg` (*a `cq_measure` of a never-quantum value lowers to the
classical value*), and makes bd `3d8q`'s whole class vanish for measured names by construction — no
taint, no reader, no stale record, no fence. Its implementation difficulty is stated in (3) below.

### (3) The seed, concretely — the ABI already takes it, with **no new symbol**

`runtime/cq_runtime.h:94-102` declares the seven allocators as taking *a value*
(`int32_t cqrt_alloc_i32(int32_t value)`), not a literal, and the pass already emits one with a
runtime operand — measured, `m14h_runtime_seed_alloc.c`:

```llvm
%h = call i32 @cqrt_alloc_i32(i32 %0)        ; %0 is `argc`
```

So `cqrt_alloc_<W>(<the cq_measure result>)` needs **no ABI change, no new frozen symbol, no
`gen_templates.py` regeneration** (Rule 15 untouched). **Width rule:** `cq_measure_<sfx>` returns the
register's own type, so for the same-variable re-use the measured width and the rotated width match by
construction and the seed goes straight in. A cross-width re-use is an ordinary **classical** cast on
the seed, which `CastLowering` already owns — the seed is classical by the ruling's own argument, so
this never becomes a quantum cast.

**The implementation difficulty, stated because it is the real cost and it is not in the ABI:** `q`
before the measurement and `q` after it are the **same SSA value**. Reading (b) therefore needs a
*position-aware taint kill* — "uses of `%q` that are provably after `%m = cq_measure(%q)` are
classical" — not a set removal. The machinery for that already exists and is this very fence's:
`provablyBefore` / `provablyBeforePerActivation` / `reachesWithoutBarrier`, with the `cq_measure` as
the barrier. That is the natural home for the work and it is the same walk `readerStalesItself`
already runs.

### (4) The population — the cost of building it

Two different populations, both measured:

* **Shapes the ruling would newly ACCEPT: 0 shipped.** No fixture, slice or golden contains one.
  `ir-pass-lit` is green at the tip (1940 fixtures, `GATES.md`), my e2e sweep is **0 movers of 373**,
  and `scan_r5.py` found no ACCEPT fixture holding the shape. So closing F-D2-3 is **pure capability
  gain with no regression surface**.
* **Existing accepts whose STREAM would change under the literal reading (a) or under (b): 2 of 367
  goldens.** `post_measure_scan.py` parses every committed `tests/e2e/*.expected.log` and reports any
  handle acted on again after its `cqrt_measure` (a re-measure is excluded — it is idempotent; a
  `cqrt_free` is excluded — it is not a re-use of the state):

```
# 2 of 367 goldens contain a post-measure re-use
slice_control_select_bool_round2_window.expected.log | 1 handle, 1 post-measure op | h2 -> cq_template_icmp_ne_i32_hl
slice_control_select_cmp_round2_window.expected.log  | 1 handle, 2 post-measure ops | h2 -> cq_template_icmp_ne_i32_hl
```

⚠ **The scanner's first version was VACUOUS and I caught it by self-test, not by re-reading it** — the
measure line's return is `-> 0`, not `-> hN`, so the anchored regex never matched and it reported
`0 of 367` for the wrong reason. Re-run against 37 probe traces with known positives it now reports 12
hits including `r1`, `r5t`, `od1` and `ob4`. Rule 12(c), on my own instrument.

Both survivors are `int keep = cq_measure(y); int x = (y != 0);` — a **pure op** on a measured rail,
lowered today as a quantum `cq_template_icmp_ne_i32_hl` with an `_unc` strip and a `cqrt_free`. Under
reading (b) that whole block becomes classical and disappears. So (b)'s shipped cost is **exactly two
goldens**, both of which get *shorter*.

### (5) Does the ruling interact with this fence? **Yes — it DECLINES three legal programs**

Asked and answered directly, per the coordinator's item 5. The fence **declines** them; it does not
accept them and it does not fail to see them:

| program | ORACLE | SUBJECT | legal under the ruling? |
|---|---|---|---|
| `m14a` measure → rotate (read once) | A 5 | **A 5** | yes — accepted, but CHAINS (see (1)) |
| `m14b` measure → rotate → **re-measure the name** | A 6 | **D** | **yes — OVER-DECLINE** |
| `m14c` measure → **in-loop** re-use | A 9 | **D** | **yes — OVER-DECLINE** |
| `m14d` measure → **two siblings** | A 7 | **D** | **yes — OVER-DECLINE** |
| `m14e` the same two siblings with **no** measurement | A 6 | **D** | **no — correct decline** |
| `m14f` measure → rotate → **pure op** on the name | D | D | yes — declines on the ORACLE too (pre-existing, `declineStaleRecordOps`) |

**`m14d` and `m14e` differ by exactly one line and get the same diagnostic.** That is the honest shape
of the interaction: the fence has no vocabulary for measurement at all, so it cannot separate the
legal re-use from the illegal one, and it refuses both. All three declines are **SAFE** (each refuses
a chain circuit that is genuinely wrong for that program), so this is a **capability gap, not a
miscompile** — which is why it is F-D2-3 and not a blocker in its own right.

**Recommended order for the build, on these measurements:** implement reading (b) — taint stops at
`cq_measure`, position-aware — because it costs 2 goldens, needs no ABI or symbol, subsumes (a), and
retires F-D2-3 *and* a share of bd `3d8q`'s remaining population by construction rather than by a new
fence.

---

## What I did NOT examine

* **No build of any kind, no full suite, no corpus sweep, no twin matrix, one lit invocation** (brief).
  Every fix I propose is **traced, not measured**. F-D2-1's minimal fix in particular must be
  re-measured against the 12 `control_inplace_ry_inloop_*`, the
  `control_inplace_ry_reject_inloop_frozen_dtzb_carry.ll` discriminator, and `ArmClassify`'s R6
  callers, because it moves an ACCEPT-direction predicate.
* I did **not** re-verify the B8-era cited figures (the 3093-row corpus sweep, the 43 movers, the
  injection matrices, the duplicate-body scan). They are correctly labelled `cited(B8 only)` in
  `GATES.md` and are **void for this tip**; the group gate still owes `cq-opt-equivalence-full`, which
  this track moved an analysis site for.
* My **e2e sweep compares the lowered IR and stderr, not the linked trace** — it cannot see a defect
  that survives into a byte-identical module, and it did not link or run the 373 slices.
* `scan_r5.py` is a **text-level** CFG scan and is deliberately crude: it is taint-blind (one false
  positive, identified), it cannot follow an arg-0 chain through a template or a `select`, and it does
  not model `-O1`'s rotations. It is a lower bound on the ruled shape's fixture population, not a
  census.
* The **Delta / round-2 routing sub-case** (round 1's F-D1-5) is still unprobed by anyone: my
  attempts, like round 1's and the implementer's, die at an earlier owner. I add one structural
  observation I could not falsify: `recordStaleQuantumReaders`' round-1 call runs at
  `CQLoweringPass.cpp:365`, **before** `lowerLoops` (:393), the peel (:471) and `detectControlRegions`
  (:475), while the delta call (`TaintPropagation.cpp:1657`) runs **after** `MergePhiPeel` and, in
  `repropagateControlMerges`, after `RegionFlatten` has linearised diamonds — so a Delta-scoped reader
  is adjudicated on a CFG where two formerly exclusive arms are **sequential**, and
  `gateIsHarmless`' leg 1 (`isPotentiallyReachable`) means something different there. Unfalsified, and
  a candidate for round 3.
* **`runOnFunction` twin-pipeline parity** checked only by reading (`recordStaleQuantumReaders` at
  :365 and :976; the drain at :689 and its twin) — not executed.
* F-D2-1's **owner attribution** is localised by three controls but not confirmed in the source: I did
  not read the loop-side in-place marking path (`commitOutOfLoopInPlaceOps` / `markIfRailLocal`) to the
  point of naming the missing clause. The implementer should do that before choosing between the two
  minimal fixes.

---

## Verdict and round budget

**NOT CLEAR.**

| # | severity | one line |
|---|---|---|
| **F-D2-1** | **over-ACCEPT / silent miscompile** | `readerStalesItself` is the third GRANTING caller of `phiTracksWire`; it makes the documented dtzb `add`/`xor` vocabulary gap live, against that header's own *"WIDEN THE VOCABULARY (or fence the caller) IN THE SAME CHANGE"*. Two programs differing in ONE φ operand emit BYTE-IDENTICAL traces; the straight-line twin is handled correctly. |
| **F-D2-2** | over-DECLINE (new) | a reader whose own BLOCK executes once inside a loop declines, though there is only ONE realizable circuit — so the 2026-09-14 ruling's *"two circuits, names neither"* rationale does not cover it; the existing retirement trigger says "body" and will not fire. |
| **F-D2-3** | over-DECLINE (new, under the §14 ruling) | three programs the owner just ruled legal decline, with the SAME diagnostic as their illegal one-line-different twin. |
| **F-D2-4** | fixture hygiene | the F-C1B-2 refusal direction's only positive STREAM pin is genuinely gone (disclosed, filed, verified). |
| **F-D2-5** | record accuracy | `gateIsHarmless` has ONE call site, not 17; the 17 belongs to the walker's public faces. |

F-D2-1 alone is disqualifying, for the same reason round 1's F-D1-1 was: it is the unforgivable class,
it is bd `3d8q`'s own signature (two programs, one circuit), and it is not an unknown — the file the
increment edited **names this exact shape, calls it "NOT EXPLOITABLE", and instructs the next caller
to widen or fence in the same change.** A third granting caller arrived, the argument behind "NOT
EXPLOITABLE" does not reach it, and no one noticed. That the outcome is also reachable on the ORACLE
is mitigation for the *severity of the regression*, not for the clearance: L3 is precisely
*"when a set is NARROWED, ask what OTHER predicate names the same gate"*, and this is its mirror —
when you add a CALLER, ask what its callee's written trigger says.

**The increment is otherwise in good shape, and I want that on the record as measured, not as
courtesy.** The leg-2 split is byte-verified verbatim; all 17 pre-existing walker call sites and both
control/switch/loop modules are untouched across the whole increment; leg 1's `std::next(R)` start is
correct on single-block, irreducible and `indirectbr` cycles, and its "no cycle" grant is not
exploitable interprocedurally (an earlier owner claims recursion and repeated calls); the four fixture
conversions are each correct on the module, hygienically neutered, and the two fences they vacated are
still positively pinned elsewhere; **0 movers across all 373 measurable e2e slices**; 12/12 on the
`stale_reader` lit family; 20 of 21 further well-formed programs unchanged; and F-D1-2 is not merely
fixed but now **measured** — `WeakVH` provably does not track RAUW in LLVM 19.1.7, which is what the
last two rounds could only read off a header.

**Round 3 is WARRANTED, on five things:**
1. **F-D2-1's fix and its re-measurement** — the widening (or the caller-fence), plus a new decline
   fixture for `oa1` and an ACCEPT fixture for `oa1t` (**neither disposition is pinned today**, which
   is how this shipped), plus the 12 in-loop rotation fixtures, the frozen-dtzb discriminator, and the
   `^e2e-loop-twin-matrix`, since this moves an in-loop in-place disposition. Re-raise or supersede
   bd `a3z7`, which records the same structural fact as a P3 efficiency divergence.
2. **F-D2-2's disposition** — file it, and widen the fixture's retirement trigger from "body" to
   "the reader's own block".
3. **The §14 build** — reading (a) vs (b) is an owner decision; the measurements are in §14 and the
   cost of (b) is two goldens.
4. **The Delta / round-2 routing sub-case**, now with the CFG-linearisation observation above, by
   someone who can build.
5. **A re-run of the whole `review_r2_probes` set after any fix** — `oa1` must move and `oa1t`,
   `oa1s`, `oa1v`, `L1a`, `od1`–`od10`, `ob2`–`ob9`, `r5f/g/i/t` and `r1`–`r13` must not.

Given the measured hit rate this codebase records, and that F-D2-1 sat behind a comment that predicted
it by name, **budget round 4 as well, and expect the F-D2-1 fix itself to need one** — it moves an
ACCEPT-direction predicate with three callers, which is the configuration round 1's rejected fix
failed on.
