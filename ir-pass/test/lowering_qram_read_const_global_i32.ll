; lowering_qram_read_const_global_i32.ll — ACCEPT (Phase 7.5 Inc 1): a tainted-index
; READ of a const-global table (QROM-shaped) `return tbl[q]`. The whole phase fires
; ONLY for the dynamic/tainted index clang -O1 cannot scalarize (a static index is
; SROA'd away). Lowers to one `cqrt_qram_alloc_i32` (array-handle birth — the const
; contents stay CLASSICAL metadata, only the count is passed) + one
; `cqrt_qram_load_i32` (Toffoli-copy-out; the cell is preserved). The mandatory
; `sext …to i64` index widening is STRIPPED — the index handle is i32 (Rule 15). NO
; measurement is inserted (Rule 5); no `getelementptr`/`load` survives.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6]
declare i32 @cq_theta_si32(i32, double)

define i32 @qrom_read(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %i   ; tainted-index access
  %v = load i32, ptr %g
  ret i32 %v
}

; The array handle is born once at entry (count 8); the index handle is the lowered
; theta; the load copies the cell out into a fresh value handle, which is returned:
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[H]])
; CHECK:     ret i32 %[[V]]
; CHECK-NOT: getelementptr
; CHECK-NOT: = load
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape
