# Phase 6.3 — Transitive worklist: Rule-13 (medium) clearance record

`test_C_libtooling-mvna.9` · branch `phase-6.3-transitive`. Independent
adversarial clearance per Rule 13 (a green suite alone does **not** clear a core
lowering change). Five perspective-diverse reviewers, each charged to *refute*
correctness on extracted IR (own adversarial `.ll` inputs + `opt`/`clang` runs),
plus a synthesis judge that re-reproduced every finding.

## What landed (the mechanism under review)

A Bennett clone whose body calls another classical fn with a **post-seed
tainted** argument specializes the inner call **depth-first**, and the outer
wrap's reverse uncomputes it via a synthesized **void uncompute twin**
`@__cq_q_<inner>_<mask>_unc(out, args…)` running `out ^= f(args)` — zeroing the
entangled inner-result rail and restoring the borrowed quantum inputs so the rail
frees clean (Rule 6/8). Recursion / call-graph cycles + varargs decline loudly.
Touches the cleared-core `EmitInverse` (clone-call adjoint) and the Bennett wrap.

## Verdict

| Lens | Result |
|---|---|
| No-cloning / double-uncompute / disjoint `cloneTaint` (Rule 8) | **clean** — depth-3 twin-of-twin, fan-out, chained inners, top+inner sharing all reverse each gate exactly once; rails freed once. |
| Borrowed-input restoration / dirty-free / hidden-measurement (Rule 6/7/8) | **clean** — the twin `out ^= f` provably zeroes the rail; borrowed inputs pristine; no inserted measurement; bodies basis-valued. |
| Over-accept / recursion-cycle / decline soundness (Prime Directive) | **clean** — mutual/longer cycles, non-i32/fp/varargs/decl-only/in-body-control/`cq_*` inners all decline loudly, `opt` non-zero; no half-built wrong-link clone. |
| Drain-ordering / cache / convergence / termination (the 6.2 hazard re-armed) | **clean** — a cache HIT always reads a FINALIZED `ReturnTainted` (depth-first finalizes before return); each `(callee,mask)` + twin synthesized once; `ensureTwin` idempotent; terminates on the acyclic subset. |
| Attribute-stripping completeness / backend DCE / ABI | **1 confirmed crash → FIXED** (below). |

## Confirmed issue (fixed before commit)

**Void-twin stale return attributes → `opt -verify` crash (exit 134).**
`synthUncomputeTwin` retypes the return to `void`, but `CloneFunctionInto` copies
the forward clone's i32-only return attrs (`noundef`/`signext`/`zeroext`/`range`)
onto the void return — malformed. Fires on any inner whose `clang -O1` return
carries `noundef` (a non-full-range op like `a & 255`); the `a * 7` golden dodged
it by luck (full overflow range → no return attr). **Fix** (single chokepoint
`stripStaleClassicalAttrs`, Rule 14): for a void return clear the entire
`ReturnIndex` attribute set; drop `returned` from params. The fix only *removes*
attributes (strictly more conservative — cannot introduce a miscompile).
Verified: `opt` exits 0, `verify` clean, and an **-O2** relink keeps every twin +
`cqrt_free` call (no DCE). Pinned by `spec_accept_transitive_retattr.ll`.

This same chokepoint also fixes a **latent silent-miscompile** the void twin
surfaced: clones inheriting `memory(none)`/`willreturn` let the backend delete the
void twin call (unused result) — freeing the entangled rail dirty. See bd memory
`6-3-stale-classical-attrs`.

## Non-blocking (deferred to 6.4)

A non-i32 **integer** arg/return reuses the `kMsgFpAbi` "floating-point …"
diagnostic string — cosmetically inaccurate, but the decline itself is correct
and loud. The rejection-message matrix is 6.4's charge.

**Cleared.** Full suite 25/25 green (incl. `e2e-slice-specialize-transitive`),
6 new/changed lit fixtures, the confirmed crash fixed + pinned.
