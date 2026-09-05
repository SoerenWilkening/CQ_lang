; lowering_io_tape_rz_preserving.ll — ACCEPT (Phase 7.6). Coverage for the
; `cqrt_rz_` arm of `preservesBasisUnderRecord` (bd 261j(a)), which the Rule-13
; round found had ZERO fixture coverage despite being reachable from ordinary C.
;
; `printf("%d", cq_phi(x + 1, 0.1))` — the taped rail %OP carries a `cqrt_rz`, and
; it must NOT freeze. Rz is DIAGONAL: it is trivial on |0> (invariant (b) with
; g = identity), and the label-diagonal phase it applies commutes with, and cancels
; against, a basis-label record. So a recorded Rz rail is still freeable, and this
; fixture asserts it reverses AND frees, while its Ry ancestor %H freezes.
;
; That contrast is the whole point: `cqrt_ry` and `cqrt_rz` are both in-place
; rotations on the same handle slot, and the freeze must distinguish them by
; PHYSICS (Ry creates the superposition; Rz only phases it) rather than by shape.
; A predicate that closed over "any in-place rotation" would freeze %OP here and
; lose a sound free; one that opened to "any rotation" would un-freeze %H in every
; other fixture in this family and restore the original hidden measurement.
;
; VEHICLE-OP NOTE (bd test_C_libtooling-6uqc, M-C Increment 2a — `add` only).
; The DERIVED rail below is built with `mul`, not `add`, and that is load-bearing
; for what this file discriminates: since M-C a dead-parent `q + c` lowers to the
; VOID in-place `cqrt_addc_<W>`, which mints NO rail — so with `add` there would
; be exactly ONE rail here and the PER-RAIL freeze decision this fixture exists to
; pin would have nothing to discriminate between. `mul` is information-losing and
; therefore outside the dtzb in-place bijection family at every batch. The
; in-place spelling of the same program is covered end to end by
; tests/e2e/slice_io_chained_theta.c, whose golden carries it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = mul i32 %q, 3
  %z = call i32 (ptr, ...) @printf(ptr @.str, i32 %s)
  ret void
}

; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[OP]])
; The Rz-carrying RECORDED rail reverses and FREES — rz is basis-preserving:
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; Its Ry ancestor still freezes:
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; NOFREE:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; NOFREE-NOT: call void @cqrt_free(i32 %[[H2]])
