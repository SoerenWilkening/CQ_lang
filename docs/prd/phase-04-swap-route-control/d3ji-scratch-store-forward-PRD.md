# d3ji — Store a quantum handle into a local scratch slot (g7ip-sibling store→load forwarding)

**Status:** INVESTIGATED, not built — **blocked on an owner scope decision.**
Follow-on from `dugh` (owner-directed defer, 2026-07-04). Branch
`dugh-repropagate-control-merge`.

> **TL;DR (the finding).** The d3ji accept-shape — a provably-same-address,
> no-escape, single-write/single-read local-array store→load round-trip of a
> quantum `%out` handle — is **eliminated by `clang -O1`'s GVN before the
> cq-lowering pass ever runs.** d3ji's accept-set is a *strict subset* of what GVN
> already forwards, so a d3ji forwarder would be **dead code on the validated -O1
> floor** and **cannot be exercised by an e2e golden** (a Rule-16 done-criterion).
> The current `kMsgStore` decline is already **correct** on real code; it fires only
> on hand-authored off-floor IR (the probe `pA1`), which is a safe over-decline
> (Prime Directive). **Recommendation: close as not-reachable and keep the safe
> decline.** Do not add unexercisable mutation code to the correctness-critical core.

---

## 1. The intended capability

`dugh` (Phase 4×6) re-propagates the untainted control-merge `%out` (a
`cqrt_alloc_<W>` i32 handle built by the 6.5 classical-call arm / 4.5 switch
data-mux), so onward **arith / phase** flow lowers. One physics-valid onward flow
`dugh` explicitly deferred to d3ji: a **local-array store of the merged quantum
handle**, then a read-back and measure — the probe
`scratchpad/8mld/pA1_localarray_store.ll`:

```llvm
merge:
  %y   = phi i32 [ %r, %arm ], [ 5, %entry ]         ; the untainted control-merge (becomes %out)
  %slot= getelementptr [8 x i32], ptr %arr, i32 0, i32 %i   ; classical index %i
  store i32 %y, ptr %slot                            ; store the qubit handle into scratch
  %v   = load  i32, ptr %slot
  %m   = call i32 @cq_measure_si32(i32 %v)
```

The store of a tainted value into memory is an escape (CQ taint is SSA-only), so
after `repropagateControlMerges` re-taints `%out` the store declines
`kMsgStore` ("cq taint escape: tainted value stored to memory").

**Intended fix (per the issue + `bd memories g7ip-inline-producer-design`):** a
g7ip-sibling **store→load forwarding**. Prove the scratch slot is
single-write / single-read / no-alias / no-escape at a definite (or provably
round-tripping) **classical** address; the store→load round-trip is then a
reversible identity (`%v === %out`), so RAUW `%v → %out`, erase the store/load
(and the now-dead gep/alloca/lifetimes), and `measure(%v)` becomes
`measure(%out)` — flowing through the normal sink path. Orthogonal to Phase-7.5
Shadow (`arr[q]=classical`: **tainted** index / **classical** value); d3ji is
**classical** index / **tainted** value.

## 2. The finding — the accept-shape is unreachable on `-O1` (Rule 9, Rule 11)

`clang -O1` runs GVN / MemDep / EarlyCSE / SROA, which **already perform exactly
this store→load forwarding** whenever it is provable — using full alias analysis
+ MemorySSA, **strictly stronger** than d3ji's structural "same SSA pointer /
structurally-equal geps, no-escape, single-store" proof. Therefore:

> **d3ji's accept-set ⊂ GVN's forward-set.** A round-trip *survives* `-O1` only
> when GVN cannot prove the addresses match — which is exactly when d3ji must
> **also decline** (forwarding would silent-miscompile). The accept case and the
> survivor case are disjoint.

Verified on **six** real `-O1` emissions (`scratchpad/d3ji/t*.c`,
`clang -Iinclude -include CQ.h -O1 -emit-llvm`), each the 6.5 classical-call arm
`int y=q; if(q>5) y=ext_f(7);` feeding a scratch store→load→measure:

| # | Source shape | `-O1` result |
|---|---|---|
| t1 / tF | `arr[i]=y; measure(arr[i])`, same dynamic index `i` (**= literal pA1**) | GVN forwards, **array deleted**, `measure(phi)` |
| tB | `asm volatile("":::"memory")` between store and load (arr doesn't escape) | GVN forwards across the barrier, array deleted |
| tC | two distinct **const** slots | **SROA**'d away entirely |
| tE | quantum handle in a **struct field**, read back | GVN forwards, struct deleted, `measure(phi)` |
| tD | `arr[i]=y; measure(arr[j])`, `i,j` **two separate `volatile` reads** | **store/load SURVIVES** — but `arr[i]` vs `arr[j]` are **not provably equal**, so forwarding is a **silent miscompile if `i≠j`** → a **DECLINE**, not an accept |

In every case where the round-trip is a valid accept, GVN eliminated it before the
pass ran (the merge is consumed directly by the measure, which `dugh`/6.5 already
lowers correctly — **no d3ji needed**). The only survivor (tD) is a mandatory
decline.

**Why g7ip *does* survive `-O1` (the disanalogy):** g7ip's store is in a
**non-inlined callee** and its load in the **caller**, straddling a call boundary
GVN cannot see across — so the round-trip persists and g7ip collapses it by
inlining. A **same-function local array** has no such barrier; GVN sees both sides.
The "g7ip-sibling" framing is apt in *mechanism* (algebraic store/load collapse)
but the two differ in *reachability*: g7ip's shape reaches the pass, d3ji's does not.

## 3. Consequences

* A d3ji forwarder would be **dead on the `-O1` floor** — its accept path is never
  taken on any supported input (`-O0` is unsupported; `-O2/-O3` are regression-
  matrix-only and forward even more aggressively).
* It **cannot be gated by an e2e golden** (Rule 16 done-criterion). Rule 2 says
  hand-authored IR (`pA1`) is *not* correctness evidence, so the capability would
  ship on lit-fixtures alone — below this project's bar.
* The **current behavior is already correct**: the `kMsgStore` decline
  (`control_classical_call_arm_reject_localarray_store.ll`) fires only on
  hand-authored off-floor IR and is a **safe over-decline** (Prime Directive — over-
  declining is always safe). **No real `-O1` input is mishandled.**

## 4. Options (owner decision — asked 2026-07-04, owner away)

1. **Close d3ji as not-reachable / won't-fix (RECOMMENDED).** Keep the safe
   decline; the pass already handles all real `-O1` code correctly. Update the
   reject fixture's comment from "interim over-decline pending d3ji" to "permanent
   safe decline — the d3ji forwarder shape is `-O1`-unreachable (GVN-subsumed)."
   **No core-lowering change.**
2. **Build the forwarder anyway** for robustness on non-clang / lower-opt IR,
   accepting that no e2e can exercise it and that it duplicates GVN on the floor.
   Design sketch in §5; still requires full Rule-13 clearance. *Weakens the
   Rule-2/Rule-16 evidence standard for a capability with no reachable input.*
3. **Rescope** to the genuinely different capability implied by "store a quantum
   handle into a scratch array": a handle stored at a classical index then **read
   back at a QUANTUM index** — a superposition register-file, the *dual* of the 7.5
   Shadow model, largely **no-cloning-bound**. This is **not** store→load
   forwarding; it needs a fresh PRD and a settled physics scope.

## 5. Design sketch (only if the owner chooses option 2)

A taint-gated, ACCEPT-ONLY / ADDITIVE anon helper `forwardScratchRoundTrips`
inside `repropagateControlMerges` (TaintPropagation.cpp), run **after** the
step-1 re-seed propagation and **before** `declineTaintEscapes`, so a proven
round-trip is canonicalized away before the escape net sees the store; an
unprovable shape is left untouched and falls through to the existing `kMsgStore`
decline (no new decline string). Placement inside `repropagateControlMerges`
gives twin-pipeline parity for free.

**TOTAL structural proof (miss-safety is structural — an unaccounted aliasing
write or an escaped alloca is a silent miscompile):**

* base is a static, non-array-allocation local alloca;
* **every** transitive user of the alloca is a gep-into-it, a `isSimple()`
  load/store *through* it, or a lifetime/dbg intrinsic — **nothing** that captures
  the pointer (call arg, `ret`, `ptrtoint`, `icmp`, the *value* operand of a store,
  an atomic, a `mem*` intrinsic) → no escape, no aliasing pointer exists;
* across all users **exactly one** store and **exactly one** load, both of the same
  `iW` type;
* the store's and load's pointers compute the **same** address (identical SSA
  pointer, or structurally-identical geps: same base alloca + same source element
  type + SSA-identical indices);
* the address is **classical** (no gep index tainted) — else it is the 7.5
  tainted-index case (out of scope);
* the store **value is tainted** (the re-seeded `%out` handle) — the trigger;
* the store **dominates** the load (combined with single-store, this discharges the
  no-intervening-write obligation — there is no other writer);
* neither is in a loop (conservative, g7ip precedent).

The transform is provably **fan-out-neutral** (the store/load is a move; forwarding
transfers the load's users onto `%out`, the same live-use count) and correctness is
**taint-agnostic** (pure store→load forwarding; the handle rides through unchanged,
so no no-cloning obligation beyond the address/alias proof). Fixtures would be
lit-only: flip `..._reject_localarray_store.ll` → accept (CHECK `cqrt_measure`
reading `%out`, `CHECK-NOT: store`/`alloca`), plus decline probes
(escape, different-index, multi-store, multi-load, not-dominating, volatile,
tainted-index). **No e2e is possible** (§3).

## 6. Done criteria (unmet — blocked)

Owner scope decision required (§4). Under option 1, "done" = the safe decline +
this finding recorded (bd memory `d3ji-gvn-subsumption-finding`, this doc). Under
option 2, the standard bar (lit fixtures + Rule-13 clearance) minus the
impossible e2e. Under option 3, a fresh PRD.
