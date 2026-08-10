; lowering_io_tape_chained_theta.ll — ACCEPT (Phase 7.6). THE ROOTS-VS-RAILS
; DISCRIMINATOR for the bd 261j(a) record freeze.
;
; A CHAINED theta puts `cqrt_ry` on a DERIVED template rail, not on a root:
; `RotationLowering` emits the second rotation on the EXISTING handle it was handed,
; and here that handle is a `cq_template_add` producer's result. So the defective
; free lands on a rail that is not a root, and EVERY 'freeze the correlated ROOTS'
; formulation leaves it standing.
;
; MEASURED against the shipped pass before this fix (six lines of ordinary C —
; `int x=cq_theta(seed,.5); int y=x+1; int z=cq_theta(y,.25); printf("%d",z);`,
; clang -O1, EXIT=0): TWO defective frees were emitted,
;     cqrt_ry_i32(%OP,-0.25) ; cq_template_add_i32_hl_unc(%OP,%H,1) ; cqrt_free(%OP)
;     cqrt_ry_i32(%H,-0.5)   ; cqrt_free(%H)
; and BOTH were certified by `free_pairing_check.py` — %OP via T1-unc-reversal and
; %H via A2-reduces-to-identity. (That is also the correction to bd 261j(b): the
; checker tightening is not A2-only.) Note what changed and what did not: those
; three ADJOINT lines are still emitted verbatim. Only the two `cqrt_free`s are
; gone. The freeze subtracts frees, never reversals.
;
; Under the shipped rule both rails freeze:
;   Recorded   = {%OP}                     (the tape write reads it)
;   Correlated = {%OP, %H}                 (backward over the DAG ancestor edges)
;   %OP  carries `cqrt_ry_i32(%OP, 0.25)`  -> not basis-preserving -> FROZEN
;   %H   carries `cqrt_ry_i32(%H, 0.5)`    -> not basis-preserving -> FROZEN
; so NOTHING is freed. Both rails are fully reverse-played and then left allocated
; (Rule 6's fallback); `opt` still exits 0 with no diagnostic.
;
; Contrast lowering_io_tape_derived_uncompute.ll, whose %OP has the SAME producer
; but NO rotation on it, and therefore still reverses and frees. The two fixtures
; together pin that the freeze keys on the GATES A RAIL CARRIES, not on the rail's
; position in the DAG.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=NOFREE
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = add i32 %q, 1
  %q2 = call i32 @cq_theta_si32(i32 %s, double 2.500000e-01)
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q2)
  ret void
}

; The forward stream, the tape write, then the FULL reverse-play — and no free:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK:     call void @cqrt_ry_i32(i32 %[[OP]], double 2.500000e-01)
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %[[OP]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[OP]], double -2.500000e-01)
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP]], i32 %[[H]], i32 1)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; NEITHER rail is freed — the roots-vs-rails point, in a whole-module window:
; NOFREE:     %[[TAPE2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; NOFREE-NOT: cqrt_free
