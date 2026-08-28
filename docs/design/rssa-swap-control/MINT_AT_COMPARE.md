# Mint-at-compare — the chained-Ry stale-condition shape (design-of-record)

**Status:** investigated and **resolved 2026-06-10** (test_C_libtooling-ee5;
statevector oracle `investigation_mint_at_compare.py`, all probes exact).
**Verdict: the conservative decline STANDS, permanently** — and is hardened
from a positional scan to an SSA wire-walk (§4). Mint-at-compare is *not* a
lift: it fixes arm selection but **no flag-freeing compilation of this shape
is source-exact** (§2, a theorem, not a search result). The only exact
compilation leaks the entangled flag rail; that is rejected as a silent
default (§3).

## 0. The shape

```c
q = cq_theta(u0, gamma);   // Ry — taint source
c = (q > 5);               // compare: predicate of the PRE-Ry basis
q = cq_theta(q, t2);       // chained, in-place, NON-diagonal Ry
if (c) { q = cq_phi(q, a); }   // phase arm on the STALE predicate
```

Declined today by `ArmClassify::condWireDisposition` (was `nonDiagonalGateBeforeBranch`
until bd lom0 Inc 4, 2026-08-28)
(`"condition predates a non-diagonal gate"`), fixture
`control_swap_reject_stalecond_chained_theta.ll`. The emitter mints the flag
at the **branch** (`SwapRouteEmit` step 1), so without the guard the mint
reads the post-Ry basis while the source's `%c` reads the pre-Ry SSA value —
wrong-arm selection with a clean flag: stream-vs-stream fidelity
`cos²(t2/2) = 0.848` (probe **P2**, reproducing `clearance_derived_base.py`
negative probe 3 exactly). Intervening **diagonal** gates (`cq_phi`) remain
fine — the accepted `stalecond` fixtures; diagonality is the load-bearing
invariant (bd `rz-diag-flag-strip-invariant`).

**Source semantics is well-defined and entangled.** Under the project's own
taint contract a tainted `icmp` is the reversible template — an entangling
predicate copy into a fresh flag rail, taken at the *compare's* wire state.
So `U_src = CRz(a)[f→q] · Ry(t2)[q] · MINT[q→f] · Ry(γ)[q]`, whose final
state has the flag **entangled with `q`** (purity of `ρ_q` = 0.606 < 1,
probe **P6**). The program *asked* for a predicate record it can no longer
recompute; that record is part of its meaning.

## 1. Mint-at-compare alone: right arm, unstrippable flag (issue claim 2a)

Minting in the valid wire window (after `def(%q)`, before the chained theta)
and swap-routing the arm verbatim is **source-exact while the flag lives**:
fidelity 1.0 to machine precision, work rail exactly `|0⟩` at free (probe
**P1** — arm selection is fixed by mint position alone). But the 4.1
`icmp_inv` strip then **misses**: it recomputes the predicate on the post-Ry
basis, residual flag `P(1) = sin²(t2/2) = 0.152` (probe **P3**; the issue's
0.118 was the same structure under a different parameterization). The
residual is identical with **no arm at all** — the obstruction is
arm-class-independent, created entirely by `MINT; Ry` (P3, second line).

## 2. The theorem: source-exactness ⊻ freeable flag

Write the source state as `|Ψ⟩ = |0⟩_f|ψ₀⟩ + |1⟩_f|ψ₁⟩`. Any compilation
that frees the flag must end in `|0⟩_f ⊗ |φ⟩` — a **pure** marginal on `q` —
while the source marginal `ρ_q` is **mixed** (P6: purity
`1 − 2cos²(γ/2)sin²(γ/2)(1−|u|²) = 0.606`, `u = cos(t2/2)sin(t2/2)(e^{ia}−1)`).
Therefore **no flag-freeing compilation reproduces source statistics**, with
the quantitative ceiling

```
sup_φ |⟨Ψ_src | 0_f, φ⟩| = ‖ψ₀‖ = cos(γ/2) = 0.853
```

over *all* clean-flag gate sequences (P6; the branch-mint emitter's 0.848
sits just under it). This closes the construction search — no cleverer strip
can exist. The candidates the issue asked about, each verified:

| candidate (issue item) | flag | fidelity vs source | probe |
|---|---|---|---|
| 4.1 `icmp_inv` strip after region (2a) | **dirty** `sin²(t2/2) = 0.152` | — | P3 |
| Bennett conjugated strip `Ry†; icmp_inv; Ry` (2b) | **dirty** `sin²(γ/2)sin²(t2)sin²(a/2)` = 0.002 (a=0.25) / 0.100 (a=2.0) | — | P4 |
| full reverse-play → strip → replay (2b) | clean | **0.727 — the arm is erased** (replayed `CRz` sees a `|0⟩` control) | P5 |
| `t2 = π` corner (2c) | clean (`u = 0`) | **0.727 — answer applied to a basis eigenstate and lost** | P9 |
| value arm, conjugated strip (2c) | clean | **not exact — coherently erases the icmp's record**; record-merging interference separates by 0.45 in `P(q=0)` | P10 |
| sub-shape scan over `t2` (2c) | residual `sin²(t2/2)` zero **only** at `t2 ≡ 0 (mod 2π)` — Ry = ±identity, the already-accepted diagonal case | — | P8 |
| mint-at-compare + **leak** (2d) | leaked, entangled | **1.0 exactly**, incl. downstream interference | P1, P7 |

The conjugated strip does not commute with a phase arm (P4's failure term is
exactly `u`); for value arms it *cleans the flag* but produces the
"classical-bool fiction" — more coherence than the source has — which a
record-merging interference circuit distinguishes loudly (P10:
`P(q=0)` 0.500 vs 0.946). A clean flag is **not** evidence of soundness
(P9/P10); only the P6 marginal argument decides.

## 3. The leak option (issue item 2d) — exact, and rejected as a default

The unique-exact family is: mint in the compare's wire window, route, free
the (provably `|0⟩`) rails, **never strip, never free the flag** — a leaked,
entangled flag rail. Probe **P7**: under a downstream re-interference circuit
the leaked compilation tracks source statistics *exactly* (0.502122 ==
0.502122) while the branch-mint compile diverges (0.935). Rule 6 permits
leaving a dirty rail allocated, and full-region reverse-play (which includes
the mint's adjoint) reclaims it on demand — so the leak is *doctrinally
admissible*. It is nevertheless **rejected as a silent default**:

- The leaked record dephases `q` under downstream interference. That *is*
  the source's own meaning (P7) — but it is almost never the user's intent
  for a dead C bool, and accepting silently reproduces the exact failure
  mode for which the forward-only/measure-only mode was struck (Rule 5
  precedent): silently degraded Grover/QPE statistics, verify-clean and
  trace-plausible.
- It breaks the 4.1 phase-arm contract (flag stripped + freed; the
  `CNT-COUNT` free-count probes) and requires wire-window mint placement —
  new emitter machinery in the most miscompile-prone corner of the project,
  to serve a shape with no known legitimate demand.
- The user can always restructure: compare immediately before the branch
  (wanting the live predicate) or branch before the second `cq_theta`
  (wanting the stale one, coherently strippable). The loud decline tells
  them so; a silent leak tells them nothing (Prime Directive).

If genuine demand for stale-predicate-with-record semantics ever appears, a
future implementation issue would: (i) place the mint via the §4 wire-walk
window (after the operand's defining call, before the wire's next in-place
gate); (ii) emit route/route-back and rail frees only; (iii) leave the flag
allocated and **excluded** from the strip/free contract; (iv) gate the whole
thing behind an *explicit user opt-in* (it must never be a silent default);
(v) re-clear P1/P7 against the emitted stream. Until then: decline.

## 4. Guard hardening: position is not provenance (found by this investigation)

The landed guard scanned **instructions between the compare and the branch**.
That is unsound under Rule 9: an `icmp` is pure, and LLVM may schedule it
*below* the chained theta (the SSA graph is unchanged — `%c` still reads the
pre-Ry `%q`). The sunk-compare layout was confirmed **accepted and
miscompiled** by the in-tree pass (2026-06-10): the emitted stream mints
after `cqrt_ry(h, t2)` — byte-for-byte the P2 wrong unitary, verify-clean.
Opaque `cq_*` calls do not reorder; pure instructions do — so the guard must
key on the **wire**, not the schedule. Fixed in
`ArmClassify::condWireDisposition` (then `nonDiagonalGateBeforeBranch`) by an SSA wire-walk: follow
in-place gate user edges (`arg-0` of `cq_phi_*` — diagonal, keep walking the
same wire; `arg-0` of `cq_theta_*` — non-diagonal wire gate → **decline**).

**Seeding matters as much as walking — direct operands are not the wire.**
Derived (arithmetic-mediated) conditions are an *accepted* region shape
**today**, and the first wire-walk seeded only the compare's direct tainted
operands — so `%d = add i32 %q, 1; %c = icmp sgt i32 %d, 5` hid the stale
`%q` one pure wire-hop behind the add: the pass **accepted and miscompiled**
the probe (confirmed 2026-06-10, exit 0, verify-clean: `cq_template_add(%h,
1)` emitted *after* `cqrt_ry(%h, %t2)` while `%d` denotes the pre-Ry value —
the same P2 family, found by review of this investigation). Closed by
seeding the walk from the condition's full tainted backward **provenance**
(`condProvenance`) instead of its direct operands. The walk does not cross
the merge `phi`, so *phi-mediated* post-region thetas are unreachable; a
**direct** post-region theta user of a provenance value *is* reachable and
declined — over-decline, accepted as safe (the wire demonstrably gains a
non-diagonal gate while the condition's record is live) — **until bd lom0
Increment 4 (2026-08-28), see the §6 amendment below**: that decline is now
POSITION-AWARE for a flat homogeneous-PHASE region with `!ShareCondFlag`. The positional scan
is retained for its cross-wire conservatism. Fixtures:
`control_swap_reject_stalecond_sunk_compare.ll` and
`control_swap_reject_stalecond_derived_cond.ll` (decline, message
char-for-char); the accepted `stalecond` / derived / cross-qubit fixtures
are unaffected (their condition provenance wires carry only diagonal users).

*Residual exposure — **closed 2026-06-10** (test_C_libtooling-uzb):* the same
position-vs-SSA stale-record family exists with **no branch at all** —
straight-line `q = theta(u0,g); q2 = theta(q,t2); d = q + 1; measure(d)` was
silently accepted, with `cq_template_add` firing post-Ry (out of
ArmClassify's reach; the ee5 guard closed only the in-region condition
instance). Now declined pass-wide by
`OpcodeLowering::declineStaleRecordOps` — a pure pre-lowering analysis that
walks each tainted operand's wire via the **shared** walker
(`WireWalk::findNonDiagonalWireGate`, hoisted from ArmClassify). Unlike the
condition guard, this one is **position-aware**, and soundly so: a pure op's
template is emitted *at the op's own scheduled position* (the inspected point
IS the emission point — not this section's mint-at-branch trap), so a theta
provably after every execution of the op (`DT.dominates(op, theta)` **and**
`!isPotentiallyReachable(theta, op)` — the second conjunct closes
loop-iteration-2 staleness) is harmless and the pre-scheduled
use-then-re-rotate shape keeps lowering. Fixtures:
`lowering_reject_stale_record_{add,crossblock,loop}.ll` (decline) and
`lowering_stale_record_add_{before_theta,after_phi}.ll` (the accept
boundary: pre-theta schedule and diagonal-only wires stay green).

## 5. Verdict

**(ii) Fundamental decline.** Mint-at-compare repairs arm selection (P1) but
cannot make the flag strippable (P6 theorem; P3/P4/P5/P8/P9/P10 close every
candidate, including every arm class and the only special angle). The exact
compilation exists only with a leaked entangled flag — recorded above as a
possible future *explicit opt-in*, never a silent accept. The
`"condition predates a non-diagonal gate"` decline is the permanent answer for a
theta BETWEEN the compare and the branch (P6 is untouched by anything below),
robust — after the §4 hardening (wire-walk + provenance seeding) — to both
instruction scheduling and derived (arithmetic-mediated) conditions; a theta
provably AFTER the region's own strip is a different question, answered in §6. The
branch-free instance of the same stale-record family is closed pass-wide by
the position-aware `declineStaleRecordOps` guard
(`"operand predates a non-diagonal gate"`; test_C_libtooling-uzb, 2026-06-10;
§4 residual-exposure note).

## 6. Amendment 2026-08-28 — bd lom0 Increment 4: the POSITION-AWARE phase accept

**What changed, and what did not.** The P6 theorem (§2) — source-exactness and a
freeable flag are mutually exclusive when a chained `Ry` sits *between* the compare
and the branch — is untouched; that shape still declines (`control_swap_reject_post_
region_theta_and_between.ll`, and the positional scan P5 runs first and covers other
wires too). What the §4 wire-walk over-declined was a theta that runs strictly
**after** the region's whole emission stream — mint, `cqrt_cswap` route, `Rz`, route
back, rail frees, `icmp_inv` strip, flag free — all of which `emitRegion` inserts
before `R.Pred`'s terminator `BI`. That is the single wall between CQ and a full
Grover iteration (`… R0; a = cq_theta(a, 0.5); a += off;`).

**The accept.** `ArmClassify::condWireDisposition` now runs the position-free walk
first; if it finds a gate, the region is accepted iff ALL of: P1 the region classifies
as a homogeneous PHASE arm (value arms keep the position-free decline, both the
condition walk and the routed-base walk); P2 `!ShareCondFlag` (the ziov share path
skips the strip, so the flag outlives the region); P3 a flat `emitRegion` region
(4.3 nests, select, switch and the 6.5 classical-call arm are untouched — structurally,
`classifyArms` has one caller and nests are peeled before it); P4 `Cond` in `R.Pred`;
P5 the positional scan is clean; and every theta on the wire satisfies
`provablyBefore(BI, T)` = `DT.dominates(BI, T) && !isPotentiallyReachable(T, BI)`,
via `WireWalk::findNonDiagonalWireGate`'s POSITION-AWARE mode with `EmitPoint = BI`
(the same walker; the `DominatorTree` is built once per function in
`detectControlRegions`, pre-mutation). This satisfies the general rule recorded in bd
memory `stale-record-position-aware-guard` — position-aware is sound only when the
inspected instruction IS the emission point — because `BI` is exactly where the
stream is minted, whereas the compare (the point the 2026-06-10 investigation
rejected) is not.

**Why it is sound only together with the M-A live-record guard (bd 6uqc Inc 1–3).**
"After the strip the region holds no live record" is true of the FLAG only. A
derived condition's provenance chain, or the routed base's dead alloc parent,
survives the strip; the late, module-wide guard declines the post-region theta over
any such dead record (`control_swap_reject_post_region_theta_derived_cond.ll`,
`lowering_reject_live_record_routed_base_anc.ll` — both now carry the guard's
message, not this file's). And since M-C (Inc 2) the SSA "wire" and the physical
rail no longer coincide (the S† theta acts on the very register the oracle's
condition read); the proof above is over IR positions only and never argues
"different SSA values ⇒ different rails".

**Witnesses.** `control_swap_accept_post_region_theta{,_shared_rail,_shapes}.ll`,
`control_swap_accept_two_iterations.ll`; e2e `slice_control_grover_2iter` (two full
S·O·S†·R0 iterations, strict free-pairing, only the register allocated at each of
its five `cqrt_ry`). Rule-13 cleared 2026-08-28 (24 probe angles, HEAD-vs-tree sweep
= the new fixtures only).

