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

Declined today by `ArmClassify::nonDiagonalGateBeforeBranch`
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
`ArmClassify::nonDiagonalGateBeforeBranch` by an SSA wire-walk: follow
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
declines — over-decline, accepted as safe (the wire demonstrably gains a
non-diagonal gate while the condition's record is live). The positional scan
is retained for its cross-wire conservatism. Fixtures:
`control_swap_reject_stalecond_sunk_compare.ll` and
`control_swap_reject_stalecond_derived_cond.ll` (decline, message
char-for-char); the accepted `stalecond` / derived / cross-qubit fixtures
are unaffected (their condition provenance wires carry only diagonal users).

*Residual exposure (tracked, out of ArmClassify's reach):* the same
position-vs-SSA stale-record family exists with **no branch at all** —
straight-line `q = theta(u0,g); q2 = theta(q,t2); d = q + 1; measure(d)` is
silently accepted today, with `cq_template_add` firing post-Ry
(OpcodeLowering/TaintPropagation domain; the ee5 guard fix closes only the
in-region condition instance). Filed as **test_C_libtooling-uzb** (P1 bug).
Any future accept-predicate for such shapes must use wire-window reasoning,
not instruction position.

## 5. Verdict

**(ii) Fundamental decline.** Mint-at-compare repairs arm selection (P1) but
cannot make the flag strippable (P6 theorem; P3/P4/P5/P8/P9/P10 close every
candidate, including every arm class and the only special angle). The exact
compilation exists only with a leaked entangled flag — recorded above as a
possible future *explicit opt-in*, never a silent accept. The
`"condition predates a non-diagonal gate"` decline is the permanent answer,
robust — after the §4 hardening (wire-walk + provenance seeding) — to both
instruction scheduling and derived (arithmetic-mediated) conditions. The
branch-free instance of the same stale-record family remains open pass-wide
(test_C_libtooling-uzb; §4 residual-exposure note).
