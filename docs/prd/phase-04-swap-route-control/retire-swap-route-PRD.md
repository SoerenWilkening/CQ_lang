# PRD — Retire the swap route: register-free `cq_phi` (branch phase by kickback) + value arms by controlled-copy merge

> **Status:** owner-scoped 2026-09-05 (seven decisions, §2, settled in
> one owner conversation and recorded here verbatim in substance). **Increments 0
> and 1 are IMPLEMENTED and Rule-13-reviewed on branch `3qlq-inc1` (2026-09-05) but
> NOT ON MAIN: the clearance review's verdict was BLOCK on finding C-1 (a mixed loop —
> invariant root register with D4's per-bit condition PLUS a second loop-carried
> register — leaks its `and` rails per activation where the hand-unrolled twin and the
> pre-3qlq oracle both discharge them; `inc1-records/session-0a61aa31/clearance.md`).
> One bounded fix round + re-clearance is owed before landing. Increment 2 (§7) is
> implemented + round-1 reviewed on branch `3qlq-inc2`, not landed.** ⚠ READ
> **§0 ERRATA FIRST** — the sections below are left as WRITTEN so design and
> implementation can be diffed, and where they disagree the errata block wins.
> Extends Phase 4
> (`ArmClassify` / `SwapRouteEmit` / `NestedRouteEmit` — since DELETED by Inc 1 —
> / `SwitchRouteEmit` /
> `SwitchValueEmit` / `AngleSelectEmit`), the 8h7d.5 rolled in-loop path and the
> drbq control-in-place epic. **A Rule-13 core change** in every increment.
> **Adds NO runtime symbol** (§5) — the emitted set SHRINKS. **Changes the
> frontend surface** (`CQ.h`: `cq_phi` loses its register argument and its 15-width
> family, §4). Implementing epic: bd `test_C_libtooling-3qlq` (children `.1`–`.3`
> = Inc 0–2, plus filed follow-ons).

## 0. ERRATA — what implementation and review measured differently (2026-09-05)

> **This block is dated and additive. The sections below are left as WRITTEN, so
> that what was designed and what was built can be diffed; where they disagree,
> THIS BLOCK WINS.** Reproducers and full arguments:
> `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §1 (adversarial round 1, eight lenses) and §2
> (round 2, two lenses + the "what else runs once before round 2" stage table).
>
> **Shipping status.** Increment 0 (docs + `cq_ry`) and **Increment 1** (the
> register-free `cq_phi` by kickback, parts A and B) are implemented on branch
> `3qlq-inc1` — **NOT on main** (clearance BLOCK on C-1, see the Status header). **Increment
> 2 (value arms by controlled-copy merge, §7) is NOT** — every §7 sentence is a
> plan, and `cqrt_cswap` is still minted at HEAD by the value-arm path and by the
> 7.2 `AbortParkEmit`.

**E1 — §3's and §7.1's "`t`, `f` freed clean" is FALSE for `t`** (Inc-2 lens
F-V1-4). In the value-arm controlled-copy merge the chain-final rail `t = R(p)` is
**not** `_unc`-reversed and **not** freed: it is left ALLOCATED and ENTANGLED with
`out`. That is physically sound while `p` is retained — nothing is freed dirty, so
Rule 6 holds — but it is not what the sentence says, and the difference matters to
anyone reasoning about ancilla cost or about a later `cq_invert`. Read §3's value-arm
paragraph and §7.1 as "`f` freed clean; `t` left allocated". A consequence worth
carrying: bd `3qlq.5` (freeing the value-arm SOURCE) is **unsound by default** under
this leak class.

**E2 — §9's per-bit idiom row was measured FALSE, then FIXED, and is TRUE again.**
The row pins D4's register-wide Z as `and(h,1<<i) → icmp eq 0 → x → rz_i1 → x →
2 _unc → 2 free`. At the Increment-1a hand-back that held at **K = 1 only**: from
K = 2 upward the `and` rail was never uncomputed and never freed (measured: 32 mints,
**0** `_unc`, at K = 32), so each activation stranded one BIT of `q` — a which-path
record — and the diffusion that makes a phase useful ran over K live records. Rolled
and hand-unrolled were different unitaries. That was graded a **CONFIRMED miscompile**
(F-L7-2 / F-L5-1 / F-L2-1b) and fixed by `LoopLowering::invariantRegisterRoots`; the
row is now correct, MEASURED in the committed goldens —
`slice_control_phase_perbit_loop.expected.log`: 4 `and_i32_hl` / 4 `and_i32_hl_unc` /
8 `cqrt_free` at K = 4, and the K = 32 golden 32 / 32 / 64 — with
`e2e-phase-perbit-loop-twin-identical` gating rolled == hand-unrolled.

⚠ **AT THE RULE-13 CLEARANCE (2026-09-05) THIS PARAGRAPH SAID "TWO THINGS THE FIX DOES
NOT COVER". THERE WERE THREE, AND THE THIRD WAS THE BLOCK.** Finding **C-1**: add ONE
ancilla rotation to the body — `for (i…) { if ((q>>i)&1) cq_phi(θ); r = cq_theta(r,.1); }`
— and the SAME loop returns `Collapsed` from `collapseRailPhisIn` instead of
`NotClaimed`, so `invariantRegisterRoots` was never asked and `markIfRailLocal` refused
on `q` at its "accumulating loop-invariant tainted input" clause. Nothing was marked and
all K bit rails leaked again: MEASURED at 542d588 **3 mints / 0 `_unc`** against **3/3**
hand-unrolled and **3/3** on the pre-3qlq oracle's register-surface twin, at `opt` exit
0, verify-clean and STRICT stage 2b `0 violation(s)`. Same defect as F-L5-1, one
dispatch precondition over, inside D4's own idiom — a wrong unitary, not a leak, because
the post-loop diffusion interferes branches carrying distinct which-path labels (Rule 8).
**FIXED in the C-1 fix round (2026-09-06):** on the `Collapsed` branch
`collapseFlattenedLoopRails` now ALSO collects the loop-invariant roots — into a
SEPARATE set, unioned into the carried `Roots` only on success — and
`invariantRegisterRoots` SKIPS any candidate the collapse already owns (its
`CarriedRoots` parameter; without that skip the body's own `r = cq_theta(r,.1)` trips
clause (iii) and takes the whole extension down). **The proof is clause (ii)'s own (I1)
argument, unwidened**: a root mint lowers to `cqrt_alloc_<W>` and fails
`ChainWalk::isInteriorTerminalHandle` clause (I1), so no adjoint `At` can ever be placed
for it in the K-times body — a property of the ROOT, not of whether some other register
crosses the back edge. WITNESS: the rolled trace is BYTE-IDENTICAL to the hand-unrolled
twin's (37 = 37, gated by `e2e-phase-perbit-loop-mixed-twin-identical`), pinned in lit by
`control_phase_kickback_mixed_invariant_carried_inloop.ll`, and the matrix gained its
first second-CARRIED-register axis (`loop_twin_matrix.py` sub-grid F).

⚠ **The other two are UNCHANGED and both remain Prime-Directive refusals rather than
proofs.** (i) A hoisted loop-invariant **TEMPLATE** rail read by the body's condition is
still refused and still leaks — **and the disclosure is now "ANY loop-invariant TEMPLATE
rail", not only `q * 3`**: the clearance re-measured the class over a `sext` rail
(`long long p = q;`), a Q+Q rail (`p = q + r`) and an ONWARD hoisted `mul`, and all three
leak identically (Q-R1-1). Its rolled trace is BYTE-UNCHANGED across the C-1 fix, pinned
by `control_phase_kickback_mixed_hoisted_template_leak_control.ll`. (ii) A loop whose
CONDITION REGISTER is loop-INVARIANT **and compared DIRECTLY** — `for (…) if (q == k)
cq_phi(θ);` with `q` untouched in the body — **declines** `condition predates a
non-diagonal gate`, because `-O1` LICM-hoists the compare out of the loop (bd `drbq.12`,
arm-class-independent; the workaround is a body gate on `q` or an opaque threshold).
Note (ii) is why D4's idiom uses a DERIVED per-bit condition: `(q>>i)&1` is loop-VARIANT
even when `q` is not.

**E3 — §6.3's "an arm with N>1 `cq_phi` calls" decline is NARROWED: the DIAMOND
spelling ACCEPTS.** N calls in one arm emit **N `cqrt_rz_i1` gates on the one flag**,
in source order, with one mint / strip / free and one `cqrt_x` bracket pair. Nothing
is summed at compile time — each angle passes through verbatim and
`P(φ₁)·P(φ₂) = P(φ₁+φ₂)` happens in the hardware — so §6.3's stated rationale ("summing
angles is the 2b rounding class again") **has no subject on the Rz stem**; it is a
Ry-stem reason, and declining would also have regressed four shipped accepts. Pinned by
`control_phase_kickback_two_calls.ll` (2 `cqrt_rz_i1`, 0 `cqrt_x`, 1 `cqrt_free`).
⚠ **Both `if/else` spellings still DECLINE** with ≥2 calls per arm (`-O1` emits either
two angle selects on one compare, or a diamond with two merge-tail phis). So N-per-arm
is a property of the DIAMOND spelling, not of the construct — loud and safe; widening
means accepting multiple selects / tail phis on one flag, which is the same mechanism.

**E4 — §6.2 row P5 (homogeneous phase `switch`) has NO plain-C `-O1` customer, and it
ships hand-IR only.** Measured over seven spellings: a phase arm's entire body is one
`call void @cq_phi(double)`, so every arm's suffix is identical modulo one operand and
SimplifyCFG's common-code sinking ALWAYS applies — dense case values become a
`@switch.table` of angles with ONE shared call, sparse ones a cascade joined by a
`phi double`. N-gate arms sink too (measured at 1/2/3 and 4/3/2 gates). The table's
tainted-index load makes the angle tainted, so both `-O1` outcomes are pinned as loud
declines (including `control_phase_switch_reject_table_fold.ll`, which carries the
verbatim `-O1` module). P5 therefore lowers on the IR `switch` only (3 accept + 7
decline fixtures), `tests/e2e/slice_control_switch_phase.c` is kept in the tree
**UNREGISTERED** with the measurement in its header, and its ctest entry was removed.
Owner choice: accept P5 as hand-IR-only (the footing the `if/else` kickback arm has had
since part A), or commission a TABLE-FOLD RECOGNIZER as its own increment — the table
is `private unnamed_addr constant` with `ConstantFP` entries, so the N angles are
statically known and the lowering is P5 with the case values read from the table. That
recognizer is what would give P5 a real customer.

**E5 — §6.2 row P6 does not reach P2: an ANGLE SELECT inside a rolled loop DECLINES**
(`condition predates a non-diagonal gate`), although P6 lists P1–P3 as in-loop accepts.
Pinned by `control_angle_select_phase_reject_in_loop.ll` and filed rather than fixed
(Q-R1-2 / OQ-19). P1 and P3 in-loop are unaffected and are gated by
`e2e-phase-grover-loop-twin-identical` and `e2e-phase-perbit-loop-twin-identical`.

**E6 — three §6.3 rows moved, and one moved LAYER.** The **bare tainted `i1` condition**
(Q4, filed as "Inc 1b") stayed a decline in Increment 1. The **Q+Q compare condition**
was declining in the OPCODE layer (`no template for opcode 'icmp i1' in tainted context`)
rather than the control layer — a Rule-1 "wrong layer" finding, since a fence that holds
because a template is absent downstream is the weakest kind; it now declines in the
CONTROL layer, per leaf, for P1 and P4 (P5 is structurally exempt). The **compound
condition** row gained a recorded asymmetry: `collectCondTree`'s `AllowLogicalSelect` is
ON for the branch phase and OFF for the 4.4 data select, so `if (q==5 && r==3) cq_phi(θ)`
lowers while `int x = (q==5 && r==3) ? a : b;` declines — one grammar, two verdicts,
decided by a flag. Safe direction, recorded rather than left implicit; the emitter
already handles the widened case.

**E7 — §6.4's migration estimate, re-measured against the tree.** The design figure was
"540 of 1582 lit fixtures reference `cq_phi`". What actually happened, MEASURED with
`git diff --name-status 52d7764 HEAD -- ir-pass/test`: **473 MODIFIED, 91 ADDED, 17
REMOVED** (corpus 1582 → 1656), of which 104 were re-derived from the pass output, 143
re-spelled, 16 swapped to `cq_theta` and 6 retired. **12 fixtures flipped DECLINE →
ACCEPT** and were sent to their own adversarial lens (0 over-accepts: 8 legitimate, 4
retired). ⚠ THREE fixtures LOST THEIR SUBJECT — they were built on
`cq_phi(i32 CLASSICAL, θ)`, which is an ill-formed CQ program but a well-formed LLVM
module, so no oracle comparison could see it; a mechanical re-spell would have left them
green while pinning nothing. On the slice side: 66 `.c` files touched, every changed slice run
through the full pipeline with **STRICT** stage 2b, and **30 `.c` REWRITTEN under an
explicit disposition** (each with a `⚠ REWRITTEN PROGRAM` header naming the measurement).
The ctest layer moved **+15 / −3** — MEASURED by `comm` over the two `ctest -N` name
lists, this tree against the pre-3qlq oracle build — so 327 → 339 entries, `^e2e-` 317 →
329, `^e2e-slice-` 293 → 302, over 304 committed goldens. The `--epic 3qlq` golden audit
classified the 72 changed goldens as **29 substitution-only · 1 ambiguous-d · 1
ambiguous-ca · 11 new-file · 30 FINDING**, and the 30 FINDINGs are exactly the 30
rewritten programs (`comm` empty both ways; `--selftest` PASS, 0 survivors). *(The audit
figures are prep-b2's final run; the ctest and golden counts are re-measured here.)*

**E8 — the §12 owner questions were proceeded on as ASSUMED, and two of the assumptions
were exercised.** Q3 (run-time angle arms admitted for the Rz stem) is load-bearing for
one shipped accept fixture and is sound for the reason §3 gives — the Rz stem performs no
subtraction, so the Ry stem's IEEE-rounding fence has no subject. Q1 (delete the unemitted
`cqrt_rz_<W>` / `_controlled` declarations at the freeze, not now) is why those symbols are
still declared; the freeze-gate decision is in `ROADMAP.md` Phase 11. Q4 (bare `i1`
condition is Inc 1b) held. Q2 (no remark on deleting an uncontrolled `cq_phi`) held.

**E9 — three CONFIRMED silent miscompiles were found IN Increment 1 by adversarial review
and none by the 1656-fixture suite**, all `opt` exit 0, verify-clean and STRICT-stage-2b
clean: the uncompute spine adjointing the kickback gate on a shared flag and cancelling
the user's phase exactly (fixed by the `!cq.branchphase` membership record, refused by
three spine predicates, recorded at all six emission sites); P7's D2 deletion running
BEFORE the second round of control detection, so a branch phase under an onward tainted
branch was deleted and its orphaned angle then lowered as quantum fp DATA (fixed by moving
the stage after the round-2 fixpoint); and a stale-header retired `@cq_phi_<sfx>` call that
was neither lowered nor declined (fixed by a reserved-name decline on any USE plus a loud
end-of-pass survivor postcondition). Round 2 added a fourth of the same family — a
once-running rail-collapse stage whose premise the second round falsifies. **Budget a
third round on any successor increment**, and read the §2 stage table as a method.

## 1. Motivation — the shipped Grover goldens are the identity

Measured 2026-09-05 at HEAD `52d7764`. The runtime ABI pins `cqrt_rz_<W>` as
**tensored** — "Rz on each qubit of the register" (`docs/backend.md:995`,
`docs/frontend.md:192`). The flagship customer program therefore lowers to a gate
that is not an oracle:

```
if (q == 5) q = cq_phi(q, PI);            // slice_control_seq_grover.c:142  "oracle: mark |5>"
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_rz_i32_controlled(h1, h0, 0x1.921fb54442d18p+1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)
```

On the marked branch the phase is `e^{iπ·popcount(5)} = +1` (under EITHER Rz
convention the marked phase is `(−1)^popcount(target)`). The reflection
`if (q == 0) q = cq_phi(q, PI)` is worse: a per-qubit diagonal gate fixes
`|0…0⟩`, so it can never put `−1` there. **Every `slice_control_*grover*` golden is
a self-consistent trace of the identity on `q`.** Rule 2 says exactly why nothing
caught it: the golden byte-diff proves every symbol resolves and signature-matches;
it does not witness the unitary, and there is no simulator (owner decision
2026-06-10).

The explicit-ancilla spelling — `bool m = (q == 5); m = cq_phi(m, PI);` with `m`
then dead — is the physically correct kickback and **declines** at HEAD in both
measured spellings with `cq uncompute: dead chain would free a measured register`
(the spine walks the dead `icmp→rz` chain back to the measured source). So Grover
is not expressible at HEAD by any spelling.

## 2. Owner decisions (2026-09-05)

| # | decision |
|---|---|
| **D1** | `cq_phi` becomes **register-free**: `void cq_phi(double θ)` = "multiply the amplitude of the CURRENT BRANCH by `e^{iθ}`". Under tainted control it lowers by **kickback**: flag mint → **uncontrolled** `cqrt_rz_i1(flag, θ)` → the ordinary `_unc` strip → `cqrt_free`. The flag returns to `|0⟩` on every branch (§3). |
| **D2** | An uncontrolled or classically-controlled `cq_phi` is a global phase and is **deleted**. This is a documented semantic, not a diagnostic. |
| **D3** | **No new runtime symbol.** The two frontend concepts (per-qubit Rz, branch phase) would be redundant; only the branch phase survives. The emitted Rz set shrinks to `cqrt_rz_i1`. |
| **D4** | **No multi-bit Rz.** The documented idiom for a register-wide Z rotation is a classical loop, `for (i…) if ((q >> i) & 1) cq_phi(θ)` (measured: lowers ROLLED at K=4 and K=32 today, IR size independent of K). "Rz directly on qubit `i`" is a **backend** peephole over a fixed gate idiom; the width-only ABI cannot address a qubit and gets no symbol for it (Rule 15). |
| **D5** | `cq_theta` keeps `a = cq_theta(a, θ)`. `a = cq_theta(θ)` is impossible: after mem2reg there is no variable `a`, and a register-free theta is byte-identical to today's fresh-register state prep (measured, §4.2). The rule "no different integers in the expression" is enforced in its **semantic** form — after a rotation, the pre-gate SSA value has no use that executes after the gate — stated ONCE in `frontend.md`; `cq_ry(x, θ)` becomes the documented statement-macro surface. Strict single-use is rejected: it would decline Grover (the compare and the rotation both read `q`). |
| **D6** | **Value arms leave the cswap route** for the controlled-copy merge: hoist the arm's pure out-of-place chain into the pred, two `cqrt_copy_<W>_controlled` into a fresh `|0⟩` rail, chain `_unc`, strip. This is the 4.4 `SelectMergeEmit` mechanism applied to the diamond (Rule 14); the `?:` select twin is the byte-identity oracle. Measured saving per arm: ~`2W` Toffoli + `9W` CNOT and one W-bit rail (§7). |
| **D7** | Increments in this order: **Inc 0** docs + `cq_ry` macro (no pass change) · **Inc 1** register-free `cq_phi` (the Grover fix, the smaller change) · **Inc 2** value arms. |

## 3. Physics, stated once

**Kickback.** With `f = c(x)` minted into a `|0⟩` ancilla, the state is
`Σ a_x |x⟩|c(x)⟩`. `P(θ) = diag(1, e^{iθ})` on the ancilla gives
`Σ a_x e^{iθ c(x)} |x⟩|c(x)⟩`; the compare `_unc` (a permutation
`|x, c(x)⟩ → |x, 0⟩`) gives `Σ a_x e^{iθ c(x)} |x⟩|0⟩`. The ancilla is provably
`|0⟩` on every branch (Rule 6) and the phase is on the branch. Under
`Rz(θ) = diag(e^{−iθ/2}, e^{iθ/2})` the difference from `P(θ)` is a global phase,
so `cqrt_rz_i1` is the gate either way. A `¬flag` arm is `x(f)·P(θ)·x(f)`; the
sign-fold `x·P(θ)·x = e^{iθ}·P(−θ)` is a valid peephole but the shipped form keeps
the `cqrt_x` bracket, matching every existing `¬flag` emission.

**Why neither route is needed for a phase arm.** The cswap route (`cswap; Rz(w);
cswap`) and the controlled-copy route (`w ^= f·q; Rz(w); w ^= f·q`) are BOTH
junk-free for a diagonal gate — the first because a swap moves and `Rz|0⟩ = |0⟩`,
the second because a diagonal gate does not change the label the second copy
un-copies. They cost `2W` Fredkin and `2W` Toffoli respectively; the kickback
costs ONE single-qubit gate and no work rail. Both routes fail for non-diagonal
gates, which is why value arms are method-B and Ry arms are controlled-in-place.

**Compound conditions.** `-O1` folds `if (a) { if (b) cq_phi(θ); }` and
`if (a && b) cq_phi(θ)` into ONE branch on `select i1 %a, i1 %b, false`
(measured, §6.1). The flag is the conjunction `cqrt_toffoli(f_a, f_b) → f_ab`,
`P(θ)` on `f_ab`, LIFO uncompute (toffoli first, then each leaf strip). This is
what `tools/opcode_table.yaml:46` has always said nesting does ("combines flags
via cqrt_toffoli, PRD §2.7").

**Angle select.** `-O1` sinks `if (c) cq_phi(A); else cq_phi(B);` into one call
on `select i1 %c, double A, double B` (measured). Lowering: `x(f); rz_i1(f, B);
x(f); rz_i1(f, A)` — `P(A)` on `f=1`, `P(B)` on `f=0`, **exact, no subtraction**.
The 2b by-difference form and its `2^-40` rounding fence are RETIRED for the Rz
stem, and a run-time arm is admissible for Rz (nothing is computed from the
angles). The Ry stem is untouched (constant arms only, 2b clearance F-11).

**Value arm by controlled copy** (Bennett, keep-source-live):
`t = R(p)` out of place on the ORIGINAL `p`, unconditionally; `out = |0⟩`;
`out ^= f ? t : 0`; `out ^= ¬f ? p : 0`; `t` uncomputed by `_unc` (a function of
the unchanged `p`); strip `f`. `out = f ? R(p) : p`; `t`, `f` freed clean; `p`
stays allocated and entangled with `out` — exactly as the swap route leaves it.
Speculating `R` is sound because every arm op is a pure TOTAL template and the
§3c clobber decline already refuses an arm that rewrites a register the
condition reads; the 6.5 classical-call arm hoisted on the same argument.

## 4. Surface change (`CQ.h`, `frontend.md`)

### 4.1 `cq_phi`

- `void cq_phi(double angle);` — ONE extern. The 15-width `cq_phi_<sfx>(x, θ)`
  family and its `_Generic` dispatch are **removed**. A program using the old
  spelling fails to compile against the header; nothing needs a migration shim.
- `frontend.md` §3.3 rewritten: branch phase; uncontrolled = global phase =
  deleted; the per-bit loop idiom (D4); the Grover oracle and the `|0⟩`
  reflection as the two worked examples.
- The taint model is unchanged: `cq_theta` remains the sole source and
  `cq_measure` the sole sink. `cq_phi` no longer propagates anything — it has no
  data operand. It is ordered by the block it sits in, not by taint.

### 4.2 `cq_theta` / `cq_ry` (Inc 0, docs + macro only)

- `#define cq_ry(x, angle) ((x) = cq_theta((x), (angle)))` — the documented
  statement surface. `cq_theta` stays declared (state prep `r = cq_theta(5, θ)`;
  `int r = 5; cq_ry(r, θ)` is the same IR after `-O1`).
- `frontend.md` gains the **linear rule** as language semantics: "a rotation
  consumes the old name; a read of the pre-gate value that the compiler cannot
  prove executes before the gate is refused". `R6`, `staleRailRecordRead` and
  `declineStaleRecordOps` are named as the three SITES of that one rule. No
  disposition changes in Inc 0; a `frontend-lit` check pins that `cq_ry`
  survives `-O1` as the same IR as the spelled-out form.
- Measured refutation of `a = cq_theta(θ)`, kept for the record: with
  `int cq_theta_noreg(double)`, `q = cq_theta(q,.3); q = cq_theta_noreg(.7);`
  arrives as two unrelated calls; nothing ties `%4` to `%2`.

## 5. ABI — no new symbol; the emitted set shrinks

| symbol family | before | after |
|---|---|---|
| `cqrt_rz_i1` | emitted | emitted (the ONLY Rz) |
| `cqrt_rz_{i8,i16,i32,i64,f16,f32,f64,f80}` | emitted (uncontrolled phi) | **not emitted** |
| `cqrt_rz_<W>_controlled[_inv]` ×9 | emitted (2a flat path, 2b Rz stem) | **not emitted** |
| `cqrt_cswap` | phase route (nest, switch), value route (flat, switch), 7.2 abort-park | **7.2 abort-park only** |
| `cqrt_copy_<W>_controlled` | 4.4 select merge, 6.5 arm | + value arms (Inc 2) |
| `cqrt_toffoli` | nest flags | + compound-condition flags |
| `cq_template_*_controlled` (532) | unemitted reserve | unemitted reserve (unchanged) |

Declarations are NOT deleted by this epic (owner question Q1, §12). `ROADMAP.md`'s
freeze list loses `cqrt_rz_<W>_controlled` as a *live* family; the note records
"declared, unemitted since 3qlq". A `_controlled` in-place permutation
(`cqrt_addc_<W>_controlled`) was considered for in-place value arms and is
REJECTED by D3; value arms stay keep-source-live.

## 6. Increment 1 — register-free `cq_phi`

### 6.1 Measured `-O1` shapes (2026-09-05, `void cq_phase(double)` stand-in)

| source | arrives as |
|---|---|
| `if (q == 5) cq_phi(A);` | diamond, arm = one void call, **no merge φ** |
| `if (q == 5) cq_phi(A); else cq_phi(B);` | ONE call on `select i1 %c, double A, double B` |
| `if (q == 5) { if (r == 3) cq_phi(A); }` | ONE branch on `select i1 %a, i1 %b, false` (the nest is FOLDED) |
| `if (q == 5 && r == 3) cq_phi(A);` | identical to the row above |
| `if (c) cq_phi(A);` (classical `c`) | classical diamond |
| `cq_phi(A);` | straight-line call |
| `for (…) { if (q == 5) cq_phi(A); q = cq_theta(q,.2); }` | the 8h7d.5 in-loop diamond, no merge φ |

A nest whose inner block carries more than a cheap compare survives as a genuine
nest (SimplifyCFG's fold threshold); both forms are in scope.

### 6.2 Accept shapes

| # | shape | mechanism |
|---|---|---|
| P1 | flat diamond, single-compare tainted condition, arm = ONE `cq_phi` | mint → `rz_i1(f, θ)` (`x`-bracketed for `¬f`) → strip → free. The 2a `emitInPlaceRotationRegion` Rz path is REPLACED; no RAUW convention exists (no φ). |
| P2 | angle select (if/else folded) | two gates on the flag, exact (§3); `AngleSelectEmit` Rz stem rewritten; run-time arms ADMITTED for Rz; Ry stem byte-for-byte unchanged |
| P3 | compound condition tree (`and`/`or`/`xor` over tainted compare leaves, the `select i1` spellings) | leaf flags via the existing mint; combine via `cqrt_toffoli` / the OR and XOR node emissions `SelectMergeEmit` already has (reuse `collectCondTree`, Rule 14); `P(θ)` on the root flag; LIFO uncompute |
| P4 | genuine depth-2 nest (4.3 `RegionTreeDetect`) | DETECTION kept; `NestedRouteEmit`'s route replaced by P3's conjunction flag |
| P5 | switch, homogeneous phase (4.5) | per-case eq-flag → `P(θ_i)` on it → strip. The §5 **const-fold re-anchor scrub** is RETIRED: there is no arg-0 to fold |
| P6 | in-loop rolled (8h7d.5), P1–P3 inside a classically-bounded loop | as today's phase-region path; `collapseFlattenedLoopRails` has nothing to collapse for a phase arm (no gate on `q`), and every "Rz is diagonal and exempt" clause becomes vacuous rather than deleted |
| P7 | uncontrolled / classically-controlled `cq_phi` | deleted AFTER `detectControl` has claimed or declined every tainted `br` (Rule 1: no third path, so a surviving `cq_phi` under an unclaimed tainted `br` is an assert, never a delete) |

### 6.3 Decline partition (loud, `DiagnosticInfoUnsupported`)

- an arm with N>1 `cq_phi` calls (summing angles is the 2b rounding class again;
  follow-on, not this increment)
- mixed arms: `cq_phi` beside a value op or an Ry in the same arm
- a bare tainted `i1` condition with no compare (`_Bool b = cq_theta(b0,θ); if (b) cq_phi(θ)`)
  — the gate belongs on `b`'s rail with no mint; filed as **Inc 1b** (Q4)
- a Q+Q compare condition (pre-existing: the flag mint passes no Q+Q width)
- a multi-block arm (`cq_phi` under a classical branch inside a tainted arm)
- `cq_phi` inside a value (method-B) region, a loop with a quantum-bounded exit,
  an irreducible or multi-latch loop, a nested loop — all as today

### 6.4 Migration cost (measured 2026-09-05)

| population | count | treatment |
|---|---|---|
| lit fixtures referencing `cq_phi` | **540 of 1582** | a migration tool `tools/migrate_phi_fixtures.py`: an UNCONTROLLED `%r = call T @cq_phi_<sfx>(T %x, double θ)` becomes RAUW `%r → %x` + delete (D2); a call inside a tainted arm becomes `call void @cq_phi(double θ)` with its merge φ dissolved to the pred incoming. Every CHECK line is then **re-derived from the pass output**, never hand-edited (the Inc-4 handle-name lesson). Fixtures whose PURPOSE was the per-register Rz (`lowering_phi_*`, the 2a peephole family, the 2b Rz-stem family) are rewritten or deleted by hand, each with the decision in its header. |
| e2e `.c` slices using `cq_phi` | **66** | rewritten to the new surface; the Grover slices' "oracle: mark \|5>" headers become TRUE |
| e2e goldens containing `cqrt_rz` | **63** (30 with `_controlled`) | regenerated; the diff is audited (§10.2) |

### 6.5 Fixtures, slices, gates

- Red-green per Rule 12: every row of §6.2 gets an accept fixture and every row
  of §6.3 a `RUN: not` decline mirroring the string.
- New slices: `slice_control_phase_grover{,_loop,_loop_unrolled}` (the correct
  oracle), `slice_control_phase_perbit_loop{,_unrolled}` (D4's idiom, K=4 and
  K=32 — the replacement for a deleted capability), `slice_control_phase_nest`
  vs `slice_control_phase_andcond` (byte-identical by construction),
  `slice_control_phase_angle_select{,_runtime_arms}`.
- Twin gates (`cmp`): rolled vs unrolled for the loop pairs; nest vs `&&`.
- `e2e-loop-twin-matrix`, `inplace_twin_matrix`, `angle_select_twin_matrix`
  re-run; cells whose Rz stem changes are regenerated with the pre/post tables
  committed as a PAIR (the Inc-4 precedent).

## 7. Increment 2 — value arms by controlled-copy merge

### 7.1 The shipped stream, and the replacement

`slice_control_value_diamond` (`if (q > 5) { p = p+3; p = p*5; p = p^9; p = p+1;
p = p*7; p = p^2; }`), per arm today: `alloc w; cswap(f,p,w); 6 ops on w;
cswap(f,p,h9); alloc out; copy(p,out); cswap; 6 _unc; cswap; free w; strip; free f`
— **4 `cswap_W` (= 4W Toffoli + 8W CNOT), 1 `copy_W` (W CNOT), one work rail**.

After: `6 ops on p → h9; alloc out; copy_controlled(f, h9, out); x(f);
copy_controlled(f, p, out); x(f); 6 _unc; strip; free f` — **2 `copy_controlled_W`
(2W Toffoli), no work rail**. The arm's ops run twice in both.

The tree already does this INCONSISTENTLY: `-O1` speculates a short pure arm into
a `select` itself, so a one-op arm takes `SelectMergeEmit` and a six-op arm takes
the swap route — same source semantics, two mechanisms, chosen by SimplifyCFG's
cost threshold.

### 7.2 Accept shapes

| # | shape | mechanism |
|---|---|---|
| V1 | flat value diamond (`if (c) p = R(p)`), derived bases included | hoist chain to pred; two controlled copies; `_unc`; strip |
| V2 | if/else value arms (`R1` / `R2`) | both chains hoisted; `out ^= f?R1(p):0; out ^= ¬f?R2(p):0` |
| V3 | switch, homogeneous value (4.5) | preload `copy(p, out)`; per case `d_i = R_i(p) ^ p` (QQ xor), `copy_controlled(f_i, d_i, out)`, uncompute `d_i`, `R_i` — the 4.5 data-mux "preload + XOR-delta" precedent, no conjunction flag |

`SwapRouteEmit`'s value path and `SwitchValueEmit`'s route are replaced;
`cqrt_cswap` is then minted only by `AbortParkEmit` (7.2).

### 7.3 Unchanged preconditions and declines

§3c clobber (arm rewrites a register the condition reads); arm ops restricted to
the pure total template set (no calls, no memory); in-loop value arms keep the
loop decline (follow-on); mixed arms decline.

### 7.4 Witness

**Byte identity with the `?:` twin**: `p = c ? R(p) : p` (with `R` an inline
function so the chain is straight-line) arrives as a `select` and lowers through
the Rule-13-cleared `SelectMergeEmit`; the diamond form must emit the identical
stream. `cmp` twin gates on ≥3 pairs (one-op, six-op, if/else). Goldens
touched: `slice_control_value_diamond`, `slice_control_switch_value` and every
other value-arm golden (measure with `grep -l cqrt_cswap tests/e2e/*.expected.log`
minus the abort and phase ones — 2 at HEAD); lit fixtures mentioning `cqrt_cswap`:
227 at HEAD, most of them declines or prose; re-derive rather than hand-edit.

## 8. Increment 0 — docs + `cq_ry` (no pass change)

`CQ.h` macro; `frontend.md` §3.2/§3.3/§7 rewritten (linear rule, branch phase,
per-bit idiom, Grover as the worked example); `docs/backend.md` Rz row; a
`frontend-lit` fixture for `cq_ry`. `CLAUDE.md` gains the Grover finding in the
Correctness-Risk section and drops "Rz|0⟩ = |0⟩ for free" as a load-bearing
argument (it becomes history). Ships before Inc 1 so the semantics are written
down before the lowering exists (Rule 16).

## 9. Deferred / out of scope (with re-opening condition)

| item | re-open when |
|---|---|
| Inc 1b: bare tainted `i1` condition (gate on the rail, no mint) | after Inc 1 clearance; a one-lens review |
| N `cq_phi` calls in one arm (angle sum) | an owner ruling on the rounding fence for sums |
| Q+Q compare condition mint | pre-existing; unchanged by this epic |
| freeing the value-arm SOURCE (`p ^= f ? R⁻¹(out) : out` with the flag alive past the merge — all existing symbols) | a customer that runs out of qubits |
| in-loop value arms | after Inc 2; the 8h7d.5 record says budget ≥3 rounds |
| deletion of the unemitted `cqrt_rz_<W>`/`_controlled` declarations | the Phase-11 freeze (Q1) |
| "Rz on qubit `i`" for the per-bit idiom | Phase-9 backend peephole over the fixed idiom `and(h,1<<i) → icmp eq 0 → x → rz_i1 → x → 2 _unc → 2 free` |
| a `-Rpass` remark when an uncontrolled `cq_phi` is deleted | Q2 |

## 10. Verification plan

### 10.1 Layers (Rule 19)
`ir-pass-lit` while iterating on the pass; the touched slices and twin gates for
goldens; the FULL suite before every commit (Rule-13 core, accept/decline
predicates change, templates untouched).

### 10.2 The golden audit (Inc 1)
Extend `tools/golden_multiset_audit.py` (the Inc-2a instrument): for each of the
63 regenerated goldens the diff must be EXACTLY one of — (a) the flat 2a
substitution `cqrt_rz_<W>_controlled(f, h, θ)` → `cqrt_rz_i1(f, θ)`; (b) the
routed quintuple `alloc(0)→w; cswap; rz_<W>(w,θ); cswap; free w` → the one
`rz_i1` line; (c) an uncontrolled `cqrt_rz_<W>(h, θ)` line DELETED; (d) the 2b
`rz(h,B); rz_controlled(f,h,A−B)` pair → the exact two-gate form — and nothing
else, handle renumbering aside. Any other diff is a finding.

### 10.3 Rule-13 lenses (per increment, ≥3 rounds budgeted)
The record for this file's neighbours is 4-for-4 on "the first adversarial round
finds a confirmed silent miscompile", and F2 took FOUR generations. Lenses:

1. **Kickback polarity** — `¬f` arms, the `select i1` spellings of NOT
   (`xor i1 %c, true`, swapped successors after `-O1` canonicalisation, Rule 9).
2. **Strip after a diagonal gate on the flag** — the compare `_unc` reads its
   OPERAND registers, which no phase arm touches; prove no path relabels them
   between mint and strip (a value op between is a mixed arm → decline).
3. **Compound-flag LIFO** — toffoli uncompute BEFORE leaf strips; an OR/XOR node
   minted onto a fresh ancilla must be freed after its uncompute, never before.
4. **P7's boundary** — a `cq_phi` that is neither claimed nor declined must be
   impossible; probe: `cq_phi` under a tainted `br` that `detectControl` declines
   (opt must exit non-zero, the call must NOT be deleted first).
5. **Angle select run-time arms (Rz only)** — the two stems now have DIFFERENT
   dispositions in one classifier; pin both directions (Ry run-time arm still
   declines; Rz run-time arm accepts; a `double` `ConstantExpr` arm still refused).
6. **In-loop per-activation** — the phase arm no longer relabels `q`; check that
   removing the rail collapse for phase arms does not silently widen the loop
   accept for MIXED loops (an Ry arm elsewhere in the same body).
7. **Migration audit** — a sample of ≥50 migrated fixtures re-derived from the
   pass, plus the `cq_opt_equivalence` full sweep; every deleted fixture's
   purpose recorded.
8. **Inc 2** — speculation totality (`sdiv`/`srem` by a tainted operand that is
   zero on the inactive branch: the template must be total; pin it), §3c
   coverage under the hoist, the select-twin byte identity, the switch XOR-delta
   with overlapping case values (impossible by `switch` semantics — assert).

## 11. Risks

- **The migration hides a semantic change.** 540 fixtures change meaning
  (an uncontrolled `cq_phi` used to be a gate that kept taint flowing and is now
  nothing). A fixture that was pinning a *lowering* of Rz keeps passing after the
  gate vanishes if its CHECKs are weak; hence "re-derive, never hand-edit" and
  the whole-file `NOROUTE`-style negatives.
- **Compound conditions are NEW core** for `br` regions (today they decline). P3
  is the largest new surface in Inc 1 and gets its own lens rounds.
- **The old goldens' story must be recorded, not erased**: the pre-3qlq Grover
  goldens encoded a controlled tensored Rz. Their `.c` headers get the finding;
  the `inc-records/` pair keeps the before/after tables.
- **Two RAUW conventions become one** (`drbq.10`): the Rz stem's M-α leaves
  `SwapRouteEmit`; only M-β (Ry) remains — a simplification that must be
  re-verified, not assumed.

## 12. Questions for the owner

- **Q1** — delete the unemitted `cqrt_rz_<W>` (W>1) / `cqrt_rz_<W>_controlled[_inv]`
  declarations now, or at the freeze? (PRD assumes: at the freeze.)
- **Q2** — emit an optimisation remark when an uncontrolled `cq_phi` is deleted?
  (PRD assumes: no diagnostic, documented semantic.)
- **Q3** — confirm run-time angle arms are ADMITTED for the Rz stem of the
  angle select, since no arithmetic is performed on them. (PRD assumes: yes.)
- **Q4** — bare-`i1` condition in Inc 1 or as Inc 1b? (PRD assumes: 1b.)
