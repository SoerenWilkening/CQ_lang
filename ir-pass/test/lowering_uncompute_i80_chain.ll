; lowering_uncompute_i80_chain.ll — witness restoration for the THREE i80 adjoint
; twins that lost their only exerciser in dbab515 (bd `gowy`; the `tkju` cleanup).
;
; PROVENANCE, stated exactly (re-verified with git before writing this, Rule 0/11).
; dbab515 DELETED NOTHING: `git show --name-status --format='' dbab515` is 1 A +
; 75 M and ZERO D, and `tests/e2e/*.c` counts 249 before and 249 after. What that
; commit did was DE-VENDOR 52 slices IN PLACE — it stripped the fictional openlibm
; SOFTWARE bodies those .c files had vendored for Rule-18 HARDWARE keeps (a keep
; has no injectable body; at the ship floor the call folds to `@llvm.<fn>` before
; codegen) and REGENERATED their goldens. Every slice still exists. What vanished
; were trace LINES. The sole prior witness for all three symbols below was
; `tests/e2e/slice_libm_real_coshl.expected.log` — 14 `zext_i32_to_i80_unc`,
; 13 `or_i80_hl_unc`, 14 `trunc_i80_to_i32_unc` at dbab515^, and 0 / 0 / 0 at
; dbab515. The bodies that commit removed from that slice — two `olm_floorl` f80
; ladders + three `olm_copysign*` shims, both hardware keeps — carried f80 union
; bit-punning; the slice's OWN body still puns (12 `and_i80_hl` survive at HEAD),
; but these three links went to zero.
; Post-regeneration `cq_template_{zext_i32_to_i80,or_i80_hl,trunc_i80_to_i32}_unc`
; exist ONLY as generated bodies in `runtime/cq_templates.{c,h}` — grep the tree:
; no golden, no fixture, nothing else. (Their FORWARD halves are NOT orphaned —
; `or_i80_hl` and `trunc_i80_to_i32` still appear in surviving goldens; it is the
; three void `_unc` twins that lost every witness.)
;
; Un-witnessed `_unc` symbols are the worst kind to lose — the whole-DAG LIFO
; uncompute spine is precisely where this project's verify-clean silent miscompiles
; live (Rule 13), and `opt -verify` is blind to every failure mode below. Sibling
; i80 adjoints (`and_i80_hl_unc`, `lshr_i80_hl_unc`, `zext_i64_to_i80_unc`,
; `trunc_i80_to_i64_unc`) survive in the e2e goldens with byte-identical prototype
; shapes; these three were simply orphaned, so a cheap lit fixture — not an e2e
; slice — is the right restoration (no accept-predicate is added here, so per
; Rule 12 a POSITIVE fixture is sufficient; there is no new decline to mirror).
;
; The shape: `q = cq_theta; w = (i80)q; o = w | 7; t = (i32)o` — a DEAD i80 chain,
; widen -> bitwise -> narrow. i80 is the widest non-power-of-2 integer width CQ
; carries (bd 3c6m.51): the x86_fp80 bit-pattern width, Tier-1 INTERMEDIATE only,
; reached in real code when an f80 libm body type-puns its sign/exponent/mantissa
; and promoteFp80Union rewrites the union into register-form `bitcast`/`lshr`/
; `and`/`or`/`shl`/`trunc`. The datalayout line is kept deliberately: f80:128 is
; what makes the 80-bit lane meaningful on this target.
;
; PHYSICS PINNED HERE — four facts, each invisible to the verifier:
;
;   * DD-3 SLOT ORDER. The void `_unc` emitter is shape-agnostic: it PREPENDS the
;     forward result `out` and then copies the forward operands in their ORIGINAL
;     order (EmitInverse.cpp). So `or_i80_hl(a, 7)` must adjoint to
;     `or_i80_hl_unc(out, a, 7)` — `out` first, the handle still at slot 0 of the
;     forward group, the classical immediate still at slot 1, at its real i80 IR
;     width. A swapped or dropped slot is a verify-clean WRONG UNITARY, which is
;     why every CHECK below binds SSA IDENTITY with a capture var rather than
;     grepping for the symbol name.
;
;   * LIFO LEAF-FIRST REVERSAL. The adjoint stream is the forward stream played
;     backwards: trunc_unc, THEN or_unc, THEN zext_unc, THEN the un-rotation
;     `cqrt_ry(-θ)` of the root. Any other order is not an adjoint.
;
;   * STILL-LIVE SOURCE AT EACH ADJOINT STEP. Each `_unc` recomputes its output
;     rail from its SOURCE and XORs it back to |0⟩ — so the source must still be
;     allocated when the adjoint runs. This is load-bearing for the narrowing link
;     in particular: `trunc i80 -> i32` discards 48 bits and is irreversible on its
;     own; it is only reversible as an EMBEDDED map `|a, out⟩ → |a, out ⊕ trunc a⟩`
;     with `a` kept. LIFO is what guarantees that liveness, and the CHECK order
;     below pins it: `trunc_i80_to_i32_unc` reads %h_op BEFORE %h_op is freed,
;     `or_i80_hl_unc` reads %h_cast BEFORE %h_cast is freed, `zext_i32_to_i80_unc`
;     reads the root BEFORE the root is un-rotated. An adjoint reading an already-freed
;     rail would be a hidden measurement on a collapsed wire (Rule 6).
;
;   * PROVEN-CLEAN FREE, AND ONLY THEN — pinned by CHECK-NEXT, not plain CHECK.
;     Every `cqrt_free` here is the instruction IMMEDIATELY after the step that
;     made its rail safe to reset. For the three DERIVED rails that step is their
;     own void `_unc`, which drives the rail to |0⟩. For the theta ROOT it is NOT
;     |0⟩: `cqrt_alloc_i32(%x)` initialises the root to the alloc-time CLASSICAL
;     BASIS state |x⟩ (runtime/cq_runtime.h — the allocator takes an initial
;     classical value), and `cqrt_ry(-θ)` restores exactly THAT state, not |0⟩.
;     So the root is KEPT, never freed (bd 5c5b, libcqops vmz9). This file used to
;     license its free as "provably DISENTANGLED and in a KNOWN classical state";
;     that is measurement immunity, not the |0⟩ proof a `cqrt_free` (a hardware
;     reset = projective measurement, Rule 6) requires, and the backend's free
;     certificate convicts it.
;     ADJACENCY IS THE POINT AND IT IS LOAD-BEARING: a plain (non-`-NEXT`)
;     directive pins only relative ORDER, and a stray gate inserted BETWEEN an
;     `_unc` and its `cqrt_free` re-dirties the just-zeroed rail, turning that free
;     into a hidden measurement that collapses `q`. Measured, not assumed: injecting
;     `call void @cqrt_x(i32 %h_op)` between `or_i80_hl_unc` and `cqrt_free(%h_op)`
;     PASSED the plain-CHECK version of this file and FAILS the CHECK-NEXT version.
;     Nothing else covers this at the lit layer — `tools/free_pairing_check.py` is
;     an e2e stage-2b gate and never runs on lit fixtures.
;
; Rule 15 re-pin: the runtime handle is `i32` at EVERY link of this chain — in, out
; and through — regardless of the i80 VALUE width. i80 appears exactly once in the
; lowered IR, as the type of the classical immediate `7`; it is never a handle
; width, never allocated, never measured. (The generated C prototype rides
; `__int128` because C has no 80-bit integer — identical to the `and_i80_hl_unc`
; shape that the surviving goldens link and run today.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; The lowered body is ONE contiguous stream — verified against the real lowered
; output, not assumed — so every directive after the anchor is a `-NEXT` form, and
; no gate, no free and no extra template call may appear anywhere between the
; alloc and `ret`.
;
; Forward chain: theta -> alloc + ry, the i80 widen, the HL bitwise or, the narrow.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i32_to_i80(i32 %[[H]])
; CHECK-NEXT: %[[O:[a-zA-Z0-9_.]+]] = call i32 @cq_template_or_i80_hl(i32 %[[W]], i80 7)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i80_to_i32(i32 %[[O]])
;
; Reversed adjoint (LIFO leaf-first). Read the interleave as pairs: uncompute the
; rail from its still-live source, then — with nothing in between — free the rail
; the `_unc` just returned to |0>, then step outward.
; CHECK-NEXT: call void @cq_template_trunc_i80_to_i32_unc(i32 %[[T]], i32 %[[O]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: call void @cq_template_or_i80_hl_unc(i32 %[[O]], i32 %[[W]], i80 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[O]])
; CHECK-NEXT: call void @cq_template_zext_i32_to_i80_unc(i32 %[[W]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[W]])
; The root closes differently: un-rotate to the alloc-time classical basis state
; |x> — not |0> — and keep it (no free).
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK-NEXT: ret void
;
; The whole-DAG adjoint is the VOID `_unc`, NEVER the fresh-minting `_inv` twin
; (an `_inv` here would allocate a NEW rail instead of returning the old one to
; |0>, leaving the original dirty and entangled under the following free).
; CHECK-NOT: cq_template_zext_i32_to_i80_inv
; CHECK-NOT: cq_template_or_i80_hl_inv
; CHECK-NOT: cq_template_trunc_i80_to_i32_inv
; The intrinsic surface is fully lowered.
; CHECK-NOT: cq_theta_
; Exactly three frees, one per derived rail: none after the root's un-rotation. (Spelled with
; `call void @` so it cannot match the module-scope `declare void @cqrt_free(i32)`
; that shares this trailing [last match -> EOF] region.)
; CHECK-NOT: call void @cqrt_free(
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %w = zext i32 %q to i80        ; widen onto the i80 bit-pattern lane
  %o = or i80 %w, 7              ; HL bitwise link, i80 immediate at its real width
  %t = trunc i80 %o to i32       ; narrow back; DEAD terminal -> whole-DAG reversal
  ret void
}
