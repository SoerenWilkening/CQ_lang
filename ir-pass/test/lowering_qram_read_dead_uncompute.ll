; lowering_qram_read_dead_uncompute.ll — ACCEPT (Phase 7.5 Inc 1): a tainted-index
; READ whose loaded value is DEAD scratch. The cqrt_qram_load is an ordinary data
; producer, so the whole-DAG uncompute spine reverses it like any other: its void
; `_unc` un-copies the loaded value back to |0> using the (preserved) cell, then
; frees the rail; the index handle's Ry is then reverse-played and the handle KEPT:
; Ry-dagger restores its runtime seed, not |0> (bd 5c5b, libcqops vmz9). The array
; handle is a CLASSICAL resource (never tainted) — never reversed, never freed. NO
; measurement (Rule 5).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEROOT < %t.cqd0.ll
@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6]
declare i32 @cq_theta_si32(i32, double)

define void @qrom_read_dead(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %i
  %v = load i32, ptr %g          ; dead scratch read
  ret void
}

; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[H]])
; CHECK:     call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[H]])
; CHECK:     call void @cqrt_free(i32 %[[V]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double -5.000000e-01)
; CHECK-NOT: cqrt_free(i32 %[[H]])
; CHECK-NOT: cqrt_free(i32 %[[ARR]])
; CHECK-NOT: cqrt_measure

; bd 5c5b review r2: the root is never freed ANYWHERE after its birth — own prefix,
; one anchor (the alloc), so the window runs alloc -> EOF and also covers a free
; slipped in BEFORE the root's un-rotation; `tools/fixture_guard_liveness.py`
; checks the window by injection.
; NOFREEROOT:     %[[RT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREEROOT-NOT: call void @cqrt_free(i32 %[[RT]])
