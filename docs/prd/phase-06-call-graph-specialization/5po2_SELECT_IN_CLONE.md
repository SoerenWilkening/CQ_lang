# Phase 6 / issue 5po2 — tainted `select` in a lifted callee (design + Rule-13 record)

`test_C_libtooling-5po2` · branch `dugh-repropagate-control-merge`. The first
increment that lets Phase-6 specialization (clone-on-taint) lift a callee whose
body contains **in-body control** — specifically a tainted `select` — instead of
declining it `InBodyControl`. Motivated by the demo `demo/foo_superposition/`:
`foo(b){ int a=0; if(b<5) a+=b; return a; }` compiles (clang -O1) to
`foo(b) = select(icmp slt b,5, b, 0)`, and a plain classical function like this
is absolutely realizable as a reversible quantum subroutine — the compiler simply
had no bridge from the top-level 4.4 select emitter into the Bennett-wrapped clone
path.

## Why it used to decline (the two-pipeline gap)

Top-level tainted control is lowered **in place** by the Phase-4 machinery
(`SelectMergeEmit`), which mints a flag, does controlled-XOR copies, strips the
flag, and frees it — all self-contained. A callee receiving a superposition is a
**different** mechanism: Phase-6 clones it into `@__cq_q_<callee>_<mask>` and
**Bennett-wraps** it (compute → copy result out → reverse-play the body via
`EmitInverse` → free scratch). That path was scoped to straight-line value bodies;
`SpecializeReject` declined every `select`/`phi` as `InBodyControl`, because
`lowerOps` does not lower a `select` and the wrap's per-call reverse chain had no
adjoint for a controlled copy.

## What landed (the mechanism)

Scoped **tight** (Prime Directive — first increment): only
`select(icmp(param, k), param, 0)` — the compare tests the **same** param the
true arm routes, the false arm is constant **zero**, the type is **i32**. The
same-param requirement makes the condition and the data share taint by
construction, foreclosing a mixed classical-flag-over-quantum-data select.

- **`SpecializeReject::isLiftableSelect`** (SpecializeReject.cpp): the shape gate;
  everything off it (non-zero/non-const false arm, derived true arm, cross-param
  condition, fp/`fcmp`, non-i32) stays `InBodyControl`.
- **`Specialization::lowerCloneSelect`** (Specialization.cpp): run in `buildClone`
  **before** `lowerOps`. For a select whose param is genuinely tainted it emits
  the reversible embedding — flag kept **live** (no local strip):

  ```
  flag = cq_template_icmp_<pred>_i32_hl(param, k)   ; reuses lowerCompareToFlag (Rule 14)
  out  = cqrt_alloc_i32(0)                          ; |0> result rail
  cqrt_copy_i32_controlled(flag, param, out)        ; out = flag ? param : 0
  ```

  When the param is **classical** the select is a plain classical mux — left
  untouched (taint is the only Q/C boundary). The capture in `buildClone` routes
  the controlled copy into the **ForwardStream only** (a reverse-only op that
  mints no rail) and the out alloc into **ScratchRails only** (a rail to free that
  is not a forward op).
- **`EmitInverse` (`isInverseEmittable`/the involution block)**:
  `cqrt_copy_<W>_controlled` joins `cqrt_x`/`cqrt_cswap` as a **self-inverse**
  involution — re-emitted verbatim under the still-live flag it XOR-copies the
  source into the out rail a second time, zeroing it. The uncontrolled Bennett
  copy-out `cqrt_copy_<W>` (no `_controlled` suffix) is deliberately excluded (it
  is the escaping basis copy, never a forward link).

The Bennett wrap then reverses `[flag-mint, controlled-copy]`: the self-inverse
copy zeroes `out`, the compare `_unc` zeroes `flag`, and both scratch rails free
clean (no dirty free — Rule 6). The borrowed input param is preserved read-only.

## Verified

- **Golden** `tests/e2e/e2e-slice-specialize-select` (multi-file, un-inlined
  `foo`) — links + byte-diffs the reversible-embedding trace.
- **Lit** positive `spec_accept_select_body.ll` (ordered clone-stream check) +
  negatives `spec_reject_select_{nonzero_false,derived_true,mixed_param}.ll`.
- **Adversarial probes** (owner, pre-review): select result used mid-body
  (`sel+1`), fan-out (`sel*sel`), classical-condition select in a 2-param clone —
  all compose correctly (each rail uncomputed + freed exactly once, verify-clean).
- Full suite green (all ctest entries).

## Rule-13 clearance

Independent adversarial reviewer charged to refute correctness (silent
miscompile: dirty free / dropped edge / wrong unitary), reasoning analytically on
extracted IR (no simulation — owner decision), plus 10 hand-built probes lowered
→ verified → linked → executed and the full ir-pass-lit + e2e suite.

**Verdict: CLEAN — no silent miscompile in the accepted shape.**

| Lens | Result |
|---|---|
| Correct-by-construction | **clean** — the minted `flag` IS the select condition (incl. the `flipPredicate` constant-on-left `icmp`), so `out = flag ? param : 0` equals the select verbatim; basis-valued permutation result → method-B is the right method (Rule 7), no phase, no dephasing. |
| Dirty free / leak (Rule 6) | **clean** — every `ScratchRail` traced to `\|0⟩` before its `cqrt_free` (out rail zeroed by the self-inverse controlled copy under the live flag; flag by its `icmp…_unc`); each controlled copy appears exactly twice (forward+reverse), never double-uncomputed; only the escape copy survives. |
| Reverse ordering | **clean** — LIFO holds; consumers (`add_unc`, nested-clone twin) run before their source rails zero; every `_unc` reads live sources. |
| Over-accept past the gate | **clean** — multiple selects, CSE'd shared condition, condition-also-read-as-data, constant-on-left `icmp`, select feeding a nested clone, depth-2 transitive nesting all lower correctly; the three mixed hazards (classical-flag/quantum-data, quantum-flag/classical-data, Q+Q condition) all decline loudly `InBodyControl`, no raw select surviving. The "one `icmp` operand must BE the true-arm param" requirement is the load-bearing property. |
| Transitive twin / `CurHandle=null` | **clean** — `@__cq_q_inner_1_unc` for a select-containing clone synthesized + composed to depth 2; `CurHandle=null` correct for the copy's flag slot. |
| `cqrt_copy_` prefix discrimination | **clean** — uncontrolled Bennett copy-out never reversed; only `_controlled` copies are involution links; no cross-match with the `cq_template_` branch. |
| `if (!Flag) continue` path | **not a hole** — `lowerCompareToFlag` always emits a `DS_Error` before returning null (loud decline, `opt` non-zero); practically unreachable for the gated i32/`icmp`/`_hl` shape. |

Probes: `scratchpad/probes/`. First increment landed + Rule-13-cleared; the
widenings (non-zero/non-const false arm, derived true arm, `br`/`switch` in a
callee, fp) remain open follow-ons that decline loudly today (Prime Directive).
