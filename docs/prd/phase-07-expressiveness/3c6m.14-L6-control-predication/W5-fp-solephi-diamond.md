# W5 — the sole-phi fp diamond claim witness (bd `vyqi`, 2026-07-24)

**Status: DONE** — the scoping memo + design of record for the
fp-MERGE-UNDER-TAINTED-CONTROL investigation the **zco4** Inc-1 finding
triggered, and the (small) widening it concluded in. Companion memory:
bd `fp-merge-tainted-control-w5-verdict`.

## 1. The question, and the exact decline anatomy (Rule 11 — all measured)

A promoted fp accumulator written on **both arms** of a tainted branch
survives to detection as a live sole `phi double`/`x86_fp80` and loud-declined
`control flow under quantum control`. Two cooperating sites, neither a physics
boundary:

1. **PredMux leaves it** — `recoverRegion`'s claim-witness set (W) deliberately
   excluded the **flat sole-2-incoming-phi diamond** (anti-overlap with the
   swap-route owners). Verified: `CQ_PREDMUX_DBG` shows `gate=W-witness`.
2. **ArmClassify declines it** — the 4.2 value path's **categorical fp fence**
   (`MergePhi->getType()->isFPOrFPVectorTy()` → decline) fires before any
   routed-base logic. The *same-base* INTEGER twin also declines (the if/else
   provenance-overlap rule), so nothing about the both-arms-write diamond was
   ever route-lowerable; fp merely hits the earlier, categorical fence.

**The decisive inconsistency:** the *same* fp body with **two** merge phis (or
any nested tainted terminator, or a >2-incoming phi) was **already claimed**
by PredMux, flattened to selects, and lowered by the kjd1
`cqrt_copy_f{16,32,64,80}_controlled` merge — probed and verified. The sole-phi
diamond was the **last unclaimed flat acyclic tainted-control shape**, an
anti-overlap fence artifact.

## 2. Semantic core (Q2) and the Bennett consult

`phi [%a,lo],[%b,hi]` under `br i1 %c` **is** `select %c',%a,%b` (edge-predicate
polarity respected) once the arm bodies are speculatable — exactly PredMux's
Inc-1 §6.1 per-basis-state equivalence, already Rule-13-cleared. Bennett.jl
(consulted per the standing instruction; HEAD `9c1b77e`) lowers an `IRPhi` at a
merge and an `IRSelect` through the **same** `lower_mux!` predicated-mux
primitive (`src/lowering/phi.jl`, `src/lowering/arith.jl:516-532`) into a fresh
|0⟩ target — the construction IS "flatten to select, lower as controlled copy".
Its fp is softfloat bit-data end-to-end, so an fp merge at a **copy** consumer
is a solved wide-integer mux; the angle hazard lives only at **rotation**
consumers (kjd1 gates 3/5 keep that fence). Bennett's two sharpened
preconditions are both already carried by the substrate: nesting composes via
the BP∧lit edge-predicate algebra (its recorded v0.5 false-path-sensitization
miscompile is structurally excluded — each select mints its own fresh target),
and the write-once-wire assumption is re-created by the kjd1 gate-2c
stale-condition guard.

## 3. The widening (what shipped)

`PredMuxFlatten.cpp` `recoverRegion`, **W5**: a *br-rooted* flat region whose
merge holds **exactly one 2-incoming scalar-fp (muxable) phi with distinct
incomings** is a claim witness. ~10 lines; no emitter, taint, or ABI change;
freeze-orthogonal (the kjd1 copy family is the frozen set; nothing new minted).

**Containment (every existing ACCEPT byte-identical):** every shipped accept
with such a phi holds a `cq_phi`/`cq_theta` call inside an arm (phase arms,
eq-fold, a8c0 re-anchor) → structurally excluded by E4's no-`cq_*`-calls rule;
the empty-arm identity phi (an accepted degenerate phase arm) → excluded by
the distinct-incomings fence; the 6.5 classical-call arm is i32-only; guarded
store/abort-park have no such phi. INTEGER sole-phi diamonds are **deliberately
not claimed** (the 4.2 value owners accept the independent-base method-B
shapes; the two-base integer mux stays the owner-declined 65wb.5 surface). So
W5 flips only decline→accept, and post-flatten adjudication is the cleared
kjd1 six-gate ladder (verified: Rz-lineage → still declines; chained-Ry stale
condition → still declines `condition predates a non-diagonal gate`; in-loop →
E2 leaves, d8jl message; vectors unreachable — the escape guard owns them).

**Known message re-label (pinned):** a nested region whose INNER flat fp
diamond W5 now flattens, but whose outer region stays unclaimable (atomic /
escaped / type-punned volatile access etc.), declines `control flow` instead
of `nested control flow` — same loudness, narrower label. Six etiq/qram pins
updated in place with the rationale.

**Fixtures:** positives `control_predmux_accept_fp_diamond_solephi{,_f80}.ll`,
`control_predmux_accept_fp_triangle_solephi.ll`, conversions
`control_predmux_accept_fp_arm_select.ll` (ex kjd1 §5.9d pin — its ArmClassify
no-select-vocabulary tripwire re-pinned type-agnostically by
`control_swap_reject_select_in_routed_arm_intmerge.ll`),
`control_predmux_accept_fp_triangle_crosscond.ll` (ex 4.2 WI-3 fp-merge pin),
`lowering_volatile_scalar_promote_fpphi_tainted.ll` (ex zco4 safety net, now
the promote→flatten→copy end-to-end positive); matrix
`control_predmux_fp_diamond_{rzlineage,stalecond}_declines.ll`,
`control_predmux_leave_fp_diamond_inloop.ll`,
`control_predmux_leave_int_diamond_solephi.ll` (containment). e2e:
`slice_predmux_fp_diamond_volatile.c` (+ golden) — the volatile-accumulator
idiom end-to-end (volatile defeats clang if-conversion, so the wild shape
always reaches the pass as a branch, never a pre-formed select).

## 4. log10l (Q3) — the true remaining distance (all measured on the dumped injected body)

The REAL `e_log10l.c` z-merge is a **3-phi** merge (`z` both-write fp + a
passthrough fp sibling + an i32 exponent sibling) — **already claimed** by the
existing multi-phi witness: the post-PredMux dump shows the z selects minted.
**W5 is therefore NOT the log10l unblock**; `log10l.f80` remains blocked, in
order, on:
1. **`ldexpl` closure** — census infrastructure, not compiler: openlibm ships
   `ldexpl` only as module-asm `.set ldexpl, scalbnl`
   (`openlibm_strong_reference`), invisible to the defmap's `define` regex.
2. the `__isnanl` early-exit value region (`s_isnan.c:63`, post-shim first
   blocker: `value-arm swap-route`).
3. the sign/zero/inf early-exit chain feeding the **5-incoming fp return
   merge** (with a theta-passthrough incoming) — controlled-return/N-way-mux
   family.
4. frexpl's tainted 3-way **switch** (non-empty default C5, memory-writing
   type-pun arms, nested br, an undef incoming).
5. the outer `e>2‖e<−2` diamond whose arms each contain **two rolled
   `__polevll`/`__p1evll` loops** (classically-latched; loops-under-control /
   static-K unroll — the `8h7d` campaign) plus the in-arm `ldexpl` call.

⇒ **log10l census +1 stays DEFERRED** (owner decision recorded in zco4): it is
a multi-increment early-exit + switch + loops-under-control campaign — the
broad control neighborhood, though **not** literally the Payne–Hanek MUX-EXCH
mechanism (Q4: the fp-merge shape itself is disjoint from MUX-EXCH; W5 shares
no machinery with it).

## 5. Census value of W5 proper

The **volatile-single-accumulator idiom class**: `volatile` on the guarded
scalar suppresses clang's own if-conversion, so the ONE-accumulator
"***CAUTION***" bodies always reach the pass as flat sole-phi branches — the
exact W5 shape — after `promoteVolatileScalarLocals`. Multi-variable and
nested variants were already covered; W5 completes the class. Also closes the
1-phi/2-phi behavioral inconsistency (a refactor-hazard trap: deleting a dead
second variable in a source could previously flip a body from COMPILES to
decline).
