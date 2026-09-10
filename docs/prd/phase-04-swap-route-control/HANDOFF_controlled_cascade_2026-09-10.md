# HANDOFF — a quantum-controlled CASCADE that the owner could not write (2026-09-06 → 2026-09-10)

**Purpose.** Basis for the next session's discussion. The owner, using `example/grover/grover_oracle_uncompute.c` as a
scratch file right after the eqpx landing (`main` b731015), tried to write a small quantum-controlled program four
different ways and every one of them declined. None of the declines is a wrong unitary; all four are coverage limits or
deliberate fences, and the fourth — the one the owner actually wanted — is expressible today with a one-line change.
But the experience is the point: **a user writing the most natural spelling of a controlled cascade hits four different
walls in a row, and none of the diagnostics says what to write instead.** Every claim below is measured on `main`
b731015; reproducers and their verdicts are in
`inc1-records/session-7bbdb89e/cascade_reproducers/` (README has the table).

## 0. What the owner wanted

A cascade: prepare a register under a condition, branch on it, prepare the next register under the new state, branch
again — each step's condition depending on the previous step's outcome.

```c
int a = 5; int b0 = 1; int b1 = 1;
if (a >= 3) b0 = cq_theta(b0, 0.5);     /* controlled state prep of b0            */
if (b0 == 0) a -= 3;                    /* value arm on a, controlled by b0        */
if (a >= 3) b1 = cq_theta(b1, 0.5);     /* controlled prep of b1, condition reads the NEW a */
if (b1 == 0) a -= 3;
return cq_measure(a) + cq_measure(b0);
```

## 1. The four walls, in the order they were hit

| # | spelling | what the pass received (stage-1 `-O1` IR) | verdict | which fence / issue | root cause class |
|---|---|---|---|---|---|
| 1 | `int b = 0; a = θ(a); if (a == 0) b = θ(b); return measure(a);` | the arm's `cq_theta(0, .5)` survives (opaque call) but has **no user and no merge phi** — `b` is dead | `control flow under quantum control` | `ControlDetect`'s generic refusal (no classifier claims a diamond whose arm is an unused call) | **coverage**: a dead state-prep arm has no accept shape |
| 2 | same, `b` read: `return measure(a) + measure(b);` | `cq_theta(i32 0, .5)` in the arm on the `a == 0` edge; phi `[%4, arm], [0, pred]` | `state prep seed is proven equal to the condition register` | drbq Inc-4 fence **F2** (PRD §14.11 Q1; bd drbq.14) | **information lost in the frontend**: on the `a == 0` edge `-O1` replaces `a` by `0`, so `cq_theta(b, θ)` with seed 0 and `cq_theta(a, θ)` (a rotation of the condition's own wire — a wrong unitary) are byte-identical; F2 refuses both |
| 3 | `int a = 5; bool b0 = 1; if (a >= 3) b0 = θ(b0); if (b0 == 0) a -= 3;` | `a >= 3` folds away (`a` is the constant 5); `%1 = cq_theta_i1(true, .5)`; `select i1 %1, i32 5, i32 2` — the select's condition is the **bare tainted `i1` register**, no compare | `control flow under quantum control` | bd **3qlq.4** (open, P2): bare tainted `i1` condition — every emitter mints its flag FROM A COMPARE into a fresh `|0⟩` rail and strips it with that compare's `_unc`; a register that IS the flag has no mint and must not be freed | **coverage**: the `bool` type; `int b0` compiles (14 lines) |
| 4 | the cascade of §0 with `int b0` | `-O1` proves `a >= 3 ⇔ b0 != 0` (a ∈ {5, 2}) and **fuses the second `if` into the first diamond**: ONE region on `b0 == 0`, a TWO-instruction arm (`b1 = θ(1)` + `icmp eq b1, 0`), TWO merge phis (`a`: `[5, arm], [2, pred]`; flag: `[%cmp, arm], [false, pred]`), then `select flag, a-3, a` | `control flow under quantum control` | three declines at once, no single issue: multi-phi merge (switch-matrix C1), multi-instruction arm (drbq R1), select on a merged `i1` (3qlq.4 again) | **`-O1` restructuring of a classical-constant driver**: the program's meaning is preserved, but the shape no emitter recognizes is manufactured by the frontend |

Stage-1 IR of wall 4 (`c4_cascade.c`), verbatim:

```llvm
  %1 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01)
  %2 = icmp eq i32 %1, 0
  br i1 %2, label %6, label %3
3:
  %4 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01)
  %5 = icmp eq i32 %4, 0
  br label %6
6:
  %7 = phi i32 [ 5, %3 ], [ 2, %0 ]
  %8 = phi i1 [ %5, %3 ], [ false, %0 ]
  %9 = add nsw i32 %7, -3
  %10 = select i1 %8, i32 %9, i32 %7
```

## 2. The decisive measurement: the cascade compiles when the driving register is quantum

`c4b_cascade_a_quantum.c` — the cascade of §0 with `int a = cq_theta(a0, 0.2)` — **ACCEPTS, 33 trace lines**, as
two ONWARD regions (round-2 control), each step exactly as intended:

```
cqrt_alloc_i32(5) -> h0 ; cqrt_ry_i32(h0, 0.2)                       a
cq_template_icmp_sgt_i32_hl(h0, 2) -> h1                             a >= 3
cqrt_alloc_i32(1) -> h2 ; cqrt_ry_i32_controlled(h1, h2, 0.5)        controlled prep of b0
icmp_sgt_unc ; free(h1)
cq_template_add_i32_hl(h0, -3) -> h3                                 a - 3
cq_template_icmp_eq_i32_hl(h2, 0) -> h4                              b0 == 0
alloc(0) -> h5 ; copy_controlled(h4, h3, h5) ; x ; copy_controlled(h4, h0, h5) ; x   a' = b0==0 ? a-3 : a  (4.4 merge)
icmp_eq_unc ; free(h4)
cq_template_icmp_sgt_i32_hl(h5, 2) -> h6                             a' >= 3   (ONWARD: reads the merge %out)
alloc(1) -> h7 ; cqrt_ry_i32_controlled(h6, h7, 0.5)                 controlled prep of b1
… the same again for b1 …
cqrt_measure_i32(h10) ; cqrt_measure_i32(h2) ; cqrt_measure_i32(h7)
```

And `c4c_cascade_a_rail_zero_angle.c` — `int a = cq_theta(5, 0.0)`, everything else as the owner wrote it — ACCEPTS
with a trace identical to `c4b` modulo the first Ry angle. So **the capability exists; what breaks it is `a` being a
classical constant**, which lets `-O1` constant-fold the dependency between the two steps into one nested region.

## 3. What this says about the compiler, honestly

1. **The onward-control path is real and works for a two-step dependent cascade** (round-2 detection over a 4.4
   merge `%out`, controlled state prep, value merge; 33 lines, STRICT 2b clean). This is not a missing feature.
2. **A classical-constant driver is the trap.** `int a = 5` is the natural way to write "start at 5", and it is exactly
   the case where `clang -O1` can prove `a >= 3 ⇔ b0 != 0` and rewrite the CFG. The pass cannot undo that fold (Rules 4
   and 9: stock `-O1` IR is the input; no parser). The resulting fused shape hits three unrelated over-declines at once.
3. **The diagnostics do not help the user.** Three of the four walls print the generic `control flow under quantum
   control`, which says nothing about dead arms, `bool` conditions, or fused cascades. Only F2 names its reason, and its
   reason ("seed equals the condition register") is opaque to someone who wrote `b`, not `a`.
4. **F2 is the one wall that is a real design limit.** The information that would disambiguate (`b` vs `a`) is gone
   before the pass runs; the only carrier at `-O1` would be debug metadata, which the design has never relied on. The
   cost is a genuine prep whose seed equals the equality constant; the workaround is any other seed.

## 4. Questions for the owner (the discussion this document is for)

- **Q1 — the idiom.** Document and, if wanted, enforce: *a register that drives a quantum-controlled chain should be a
  quantum register from the start* (`int a = cq_theta(5, 0.0)` — a rail carrying 5 under an identity rotation — is the
  minimal spelling, measured). Is an identity-angle `cq_theta` acceptable as the documented way to "make a register
  quantum", or does the surface want a clearer spelling (e.g. a `cq_ry`-style statement macro; **no new intrinsic** —
  Rule 4, owner D3)? Note this changes the circuit: the classical `5 | 2` mux becomes a real rail with two controlled
  copies, which is the physically honest reading of the cascade anyway.
- **Q2 — the fused shape (wall 4).** Should an emitter accept it, or should it stay a loud decline with a better message?
  Analytic sketch of an accept (UNMEASURED, unbuilt): the fused region is the outer condition `c0 = (b0 != 0)` with
  (i) a state prep of `b1` under `c0` (exists: drbq Inc 4), (ii) an `i32` phi over constants under `c0` (exists: the
  4.4 / 4.5 data mux), (iii) an `i1` phi `[%cmp, arm], [false, pred]` which is `c0 AND (b1 == 0)` — a `CondTreeEmit`
  AND node over two compare leaves (exists for phase arms and for the 4.4 data select's condition tree), and (iv) the
  `select` as a 4.4 copy merge under that compound flag (exists). What does NOT exist is the recognizer that reads a
  multi-phi merge + a two-instruction arm as that composition. Cost: a new classifier in the Rule-13 core, with the
  full adversarial budget (this is the family that produced nine findings over seven rounds). Benefit: only programs
  whose driver is a classical constant, which Q1's idiom already covers. **Recommendation: decline with a specific
  message, document the idiom, do not build the emitter.**
- **Q3 — bd 3qlq.4 (bare `i1`).** `bool` is the natural type for a qubit and it fails today at the first `if`. Move
  3qlq.4 from P2 to the front of the queue? Its scope note says the gate belongs directly on the register's rail (no
  mint, no strip, and the rail is the user's — it must not be freed). One-lens increment.
- **Q4 — the dead arm (wall 1).** A state prep whose result is never read: delete it (it is unobservable, like the fenv
  ruling's dead multiply) or decline it with a message that says "the arm's result is never read"? Today it is the
  generic decline. Deleting is a Rule-5/6 question only if the prep were on an existing register; for a fresh seed it
  allocates nothing observable. Owner's call; a specific message is the minimum.
- **Q5 — diagnostics.** Three of four walls print the same generic string. Should `ControlDetect` name WHY it could not
  classify (dead arm / bare-`i1` condition / multi-phi merge / multi-instruction arm)? Pure UX; no accept-set change;
  cheap; and it would have answered every "why does it decline now??" of 2026-09-07 without a session.
- **Q6 — F2 (wall 2).** Accept the cost (recommended: the twin it guards is a wrong unitary and byte-identical), or scope
  a debug-metadata disambiguation (new design surface, fragile under optimization, not recommended).

## 5. What is NOT in the open queue

Checked 2026-09-09 (`bd list --status open`): no issue covers wall 4 or the cascade idiom. Nearest: **3qlq.4** (wall 3,
P2), **1dky** (onward-control widening on `%out`: sequential same-source siblings + deeper nests, P3 — assumes the second
region survives as a region, which the fold prevents), **drbq.8** (two rotation regions under one condition register,
P3), **drbq.14** (F2's owner rulings, P2), **drbq.15** (post-region arithmetic on a prepped register, P3). Proposed new
items, pending the discussion: (a) P2 "controlled-cascade idiom: document + a specific decline for the `-O1`-fused
shape" (Q1/Q2/Q5); (b) P3 "dead state-prep arm: specific message or deletion" (Q4).

## 6. Where things are

- Reproducers + verdict table: `inc1-records/session-7bbdb89e/cascade_reproducers/` (11 files + README).
- The `example/grover/` directory is **git-excluded locally** (`.git/info/exclude`); the README row for
  `grover_oracle_uncompute.c` describes an earlier `for`-loop body, and the file has been a scratch file since
  2026-09-06. `user_file_as_of_2026-09-10.c` is the committed snapshot.
- The controlled-Ry mechanism the cascade uses: `docs/prd/phase-04-swap-route-control/control-in-place-PRD.md` §4 (flat
  diamond), §13 (in-loop), §14 (state prep, F1/F2); the onward path: `TaintPropagation.cpp` `repropagateControlMerges`
  → `detectAndLowerOnwardControl`; the 4.4 merge: `SelectMergeEmit.cpp`; the condition tree: `CondTreeEmit.cpp`.
- Session record of the eqpx landing (the binary all of this was measured on): `inc1-records/session-7bbdb89e/README.md`.
