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
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = add i32 %q, 1
  %p = call i32 @cq_phi_si32(i32 %s, double 1.000000e-01)
  %z = call i32 (ptr, ...) @printf(ptr @.str, i32 %p)
  ret void
}

; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK:     call void @cqrt_rz_i32(i32 %[[OP]], double 1.000000e-01)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[OP]])
; The Rz-carrying RECORDED rail reverses and FREES — rz is basis-preserving:
; CHECK:     call void @cqrt_rz_i32(i32 %[[OP]], double -1.000000e-01)
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[OP]])
; Its Ry ancestor still freezes:
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; NOFREE:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; NOFREE-NOT: call void @cqrt_free(i32 %[[H2]])
