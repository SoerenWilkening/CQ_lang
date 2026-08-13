; lowering_uncompute_shifts_i64.ll — witness restoration for the i64 SHIFT adjoint
; pair, bd `gowy`. PROVENANCE, stated accurately because it is institutional memory
; (Rule 0): commit dbab515 ("tkju") DELETED NOTHING. `git show --name-status
; --format='' dbab515 | awk 'NF{print $1}' | sort | uniq -c` is 1 A + 75 M and ZERO
; D, and `tests/e2e/*.c` counts 249 both at dbab515^ and at dbab515 — every slice
; still exists. What dbab515 did was DE-VENDOR 52 slices IN PLACE: it stripped the
; fictional openlibm SOFTWARE bodies those .c files carried for Rule-18 HARDWARE
; keeps, and regenerated their goldens. Those vendored bit-twiddle ladders were the
; only thing that ever emitted `cq_template_shl_i64_hl_unc` and
; `cq_template_ashr_i64_hl_unc`, so it is the trace LINES that disappeared, from the
; regenerated `.expected.log` files — `tests/e2e/slice_libm_real_coshl.expected.log`
; carried 14 such lines at dbab515^ and carries 0 at HEAD; the slice and its golden
; are both still tracked and still green, only their witness CONTENT changed. Do not
; go looking for removed files. Both symbols still exist in the generated runtime
; (`runtime/cq_templates.c`) with NO witness anywhere — not an e2e golden, not a lit
; fixture. Both are ADJOINT TWINS, i.e. the whole-DAG uncompute spine, which is
; precisely where this project's verify-clean silent miscompiles live (Rule 13), so
; an un-witnessed `_unc` is a standing hazard and a cheap ir-pass lock buys back most
; of what the de-vendored golden used to prove. No accept-predicate is added here —
; the shapes were already accepted — so per Rule 12 a POSITIVE fixture is sufficient;
; there is no new decline edge to probe.
;
; SHAPE: `q = cq_theta; w = (i64)q; s = w << 3; a = s >> 2` — a dead i64 shift chain
; reached through a WIDENING cast. Nothing consumes %a, so the entire chain is
; source-derived dead data and the Phase-5 whole-DAG LIFO spine reverses all of it.
;
; What this fixture pins, and why each line of it is load-bearing:
;
;   * DD-3 SLOT ORDER. `EmitInverse` is shape-agnostic: it PREPENDS the forward
;     result `out` and then copies the forward operands in their ORIGINAL order. So
;     `cq_template_shl_i64_hl(src, i64 3)` must adjoint to
;     `cq_template_shl_i64_hl_unc(out, src, i64 3)` — never `(src, out, 3)`, never a
;     shift amount hoisted ahead of the rail it acts on. Every such permutation is
;     `opt -verify` clean and computes a DIFFERENT unitary, so the CHECKs below use
;     capture vars to pin handle IDENTITY per slot; grepping for the symbol name
;     alone would witness nothing that matters.
;
;   * RULE 15, TWICE OVER, IN ONE CALL. The RAIL handles are `i32` at every slot
;     (a runtime handle is always i32 regardless of the value width it stands for)
;     while the CLASSICAL shift amount keeps its real `i64` width in the forward
;     slot. Coercing that literal down to an i32 handle-shaped operand — or worse,
;     `cqrt_alloc`-ing a rail for it — is the width/angle miscompile family in its
;     integer dress. The cast link `zext i32 -> i64` makes the same point on the
;     arity-1 axis: the i64 is a VALUE width, never a handle width.
;
;   * LIFO LEAF-FIRST REVERSAL, SOURCE STILL LIVE AT EACH STEP, AND NOTHING SPLICED
;     IN BETWEEN. Forward order is zext -> shl -> ashr; the reversal is exactly its
;     mirror. `ashr_unc` reads the still-live %shl rail, `shl_unc` then reads the
;     still-live %cast rail, and `zext_unc` then reads the still-live alloc root.
;     Each rail is freed only AFTER its own adjoint has restored it and BEFORE its
;     producer's adjoint runs; reorder any of that and an adjoint reads an
;     already-freed rail. From the alloc anchor onward the directives below are
;     CHECK-NEXT, because the emitted spine really is contiguous and the ADJACENCY
;     is load-bearing rather than cosmetic: under an unanchored plain CHECK a stray
;     in-place gate spliced BETWEEN an `_unc` and its `cqrt_free` — e.g. `cqrt_x` on
;     the very rail the adjoint just drove to |0> — PASSES, and that mutant is
;     precisely a Rule-6 dirty free: the rail is re-dirtied after being zeroed, so
;     the reset becomes a hidden measurement that collapses `q`. Nothing covers this at
;     the lit layer — `tools/free_pairing_check.py` is an e2e stage-2b gate over
;     linked slices and never runs on .ll fixtures. The CHECK-NEXT chain also
;     subsumes any inline region CHECK-NOT — no instruction of ANY kind may appear
;     between two consecutive pinned lines. (Note for whoever edits this header
;     next: never write a directive prefix followed by a colon inside prose.
;     FileCheck scans the WHOLE check file, so a quoted one becomes a live
;     directive and the fixture fails for a reason that has nothing to do with the
;     pass. That is why the guards are named without their colons throughout.)
;
;   * PROVEN-|0> FREES OFF A LOSSY FUNCTION. A shift is lossy as a function — `shl`
;     drops high bits, `ashr` drops low ones — which is exactly why the lowering does
;     NOT rewrite in place. The embedded Bennett form |a,0> -> |a, a<<3> XORs into a
;     FRESH rail and is a permutation for ANY f, lossy or not; the adjoint is that
;     same self-inverse XOR recomputed from the live source, driving the out rail
;     back to |0>. So and only so is each DERIVED rail's `cqrt_free` here a Rule-6
;     legal reset and not a hidden measurement on a dirty rail.
;
;     The ROOT %h discharges the same Rule-6 obligation by a DIFFERENT argument, and
;     the distinction is real, not pedantry: `cqrt_alloc_i32(%x)` initialises the
;     root to the alloc-time CLASSICAL BASIS state |x>, so the closing Ry(-θ)
;     restores THAT state — it does not, and need not, produce |0>. What licenses
;     the root's `cqrt_free` is that it is provably DISENTANGLED and in a KNOWN
;     classical state. Only the derived rails genuinely reach |0>, and only they do
;     so via their own `_unc`.
;
;   * The adjoint is the VOID `_unc`, never the fresh-minting `_inv` — an `_inv`
;     would allocate a new rail and leave the old one dirty and allocated instead of
;     restoring it, so the frees below would stop being provable. The trailing
;     CHECK-NOTs hold that line for both shifts and for the cast. FileCheck scopes
;     them to [last positive match -> EOF] — here `ret void`, `}` and the declare
;     block — and that is sufficient, not vacuous, because the lowered module's
;     declare block mirrors EXACTLY the set of emitted symbols: a wrongly-emitted
;     `..._inv` call necessarily drags a `declare ... @..._inv` into the guarded
;     region, where it IS caught. The `cq_theta_` guard is a witness for the same
;     structural reason, in the other direction — the pass ERASES the now-unused
;     `declare i32 @cq_theta_si32`, so its absence from the whole lowered module,
;     declares included, is the intrinsic-erasure lock.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; Forward chain: theta -> alloc + ry, the widening cast, then the two i64 shifts.
; The classical shift amounts stay i64; every handle is i32. The alloc is the only
; unanchored CHECK — it is the anchor; every line after it is pinned ADJACENT.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i32_to_i64(i32 %[[H]])
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i64_hl(i32 %[[W]], i64 3)
; CHECK-NEXT: %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_ashr_i64_hl(i32 %[[S]], i64 2)
;
; Reversed adjoint (LIFO, leaf first). Read the pairs: each `_unc` takes (out, src,
; lit) with `out` the rail it restores and `src` the rail still live from the forward
; stream — ashr_unc(out=%a, src=%s, 2), then %a is |0> and freed IMMEDIATELY;
; shl_unc(out=%s, src=%w, 3), then %s is |0> and freed immediately; zext_unc(out=%w,
; src=%h), then %w is |0> and freed immediately; finally Ry(-θ) returns the root to
; its alloc-time classical basis state |x> — disentangled and known, NOT |0> — and
; the root is freed last. Every free below is CHECK-NEXT on its own adjoint: that
; adjacency is the Rule-6 lock (nothing may re-dirty a rail between the `_unc` that
; zeroed it and the reset that consumes that fact).
; CHECK-NEXT: call void @cq_template_ashr_i64_hl_unc(i32 %[[A]], i32 %[[S]], i64 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cq_template_shl_i64_hl_unc(i32 %[[S]], i32 %[[W]], i64 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[S]])
; CHECK-NEXT: call void @cq_template_zext_i32_to_i64_unc(i32 %[[W]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[W]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H]])
;
; CHECK-NOT: cq_template_ashr_i64_hl_inv
; CHECK-NOT: cq_template_shl_i64_hl_inv
; CHECK-NOT: cq_template_zext_i32_to_i64_inv
; CHECK-NOT: cq_theta_
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %w = zext i32 %q to i64                        ; widening cast into the i64 chain
  %s = shl i64 %w, 3                             ; HL: handle + i64 classical amount
  %a = ashr i64 %s, 2                            ; dead terminal of the shift chain
  ret void
}
