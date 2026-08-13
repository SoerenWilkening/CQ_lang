; lowering_qram_read_select_origin.ll — ACCEPT (Phase 7.5 Inc 3, the §2.8(iv)
; single-origin phi/select proof): a QROM read whose address gep base is a pointer
; `select` BOTH of whose arms resolve to the SAME constant-global origin (`@tbl`).
; The provenance walk proves the single origin (diamond reconvergence is NOT a
; multi-origin reject — depth-bounded, not visited-set), and the read lowers like a
; direct-base QROM read. clang -O1 would FOLD this degenerate select; the
; hand-written select pins the walk's phi/select single-origin acceptance (the same
; test vehicle as the dead-LIFO fixtures clang would DCE). A genuinely two-origin
; select declines — see lowering_reject_qram_multi_origin.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6]
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @qrom_sel(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %base = select i1 %c, ptr @tbl, ptr @tbl     ; single origin (both arms @tbl)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds i32, ptr %base, i64 %i    ; flat gep off the select
  %v = load i32, ptr %g
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK:     call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:     call i32 @cqrt_qram_load_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: getelementptr
; CHECK-NOT: cq QRAM access
; CHECK-NOT: cq taint escape
