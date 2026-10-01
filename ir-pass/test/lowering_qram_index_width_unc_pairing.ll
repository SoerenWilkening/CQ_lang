; lowering_qram_index_width_unc_pairing.ll — ACCEPT (libcqops handoff b6a; the
; round-2 review's G1). Two GUARDED stores into one local array index it with the
; same i8 value `c`, once sign-extended (`if (c >= 0) arr[c] = 1`) and once
; zero-extended (`if (h < 3) arr[(unsigned char)c] = 2`, a 256-cell array). Same
; callee, same index value, DIFFERENT casts, and every executed store in bounds.
; A draft bracketed each `_unc` with the cast of the FIRST forward that shared
; its (callee, index value), so the zext store's reversal popped at sext(c): for
; c < 0 that is an out-of-bounds index on an in-contract basis state, and the
; scratch array is never restored (verify-clean, stage 2b clean). Each `_unc`
; now inherits its OWN forward's tag through `emitInverseCall`
; (`inheritQramIndexTag`), so the pairing below is by construction.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i8 @cq_theta_si8(i8, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @two_guards(i8 %u, i32 %ug, i32 %uh, i32 %up) {
entry:
  %arr = alloca [256 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 1024, i1 false)
  %c = call i8 @cq_theta_si8(i8 %u, double 5.000000e-01)
  %h = call i32 @cq_theta_si32(i32 %uh, double 5.000000e-01)
  %f1 = icmp sge i8 %c, 0
  br i1 %f1, label %a1, label %m1

a1:
  %s = sext i8 %c to i64
  %p1 = getelementptr inbounds [256 x i32], ptr %arr, i64 0, i64 %s
  store i32 1, ptr %p1, align 4                   ; if (c>=0) arr[c] = 1
  br label %m1

m1:
  %f2 = icmp slt i32 %h, 3
  br i1 %f2, label %a2, label %m2

a2:
  %z = zext i8 %c to i64
  %p2 = getelementptr inbounds [256 x i32], ptr %arr, i64 0, i64 %z
  store i32 2, ptr %p2, align 4                   ; if (h<3) arr[(unsigned char)c] = 2
  br label %m2

m2:
  %q = call i32 @cq_theta_si32(i32 %up, double 5.000000e-01)
  %sq = sext i32 %q to i64
  %pl = getelementptr inbounds [256 x i32], ptr %arr, i64 0, i64 %sq
  %v = load i32, ptr %pl, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK-LABEL: define i32 @two_guards(
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %u)
; Forward: the sext store under flag F1, then the zext store under flag F2.
; CHECK:      %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i8_to_i32(i32 %[[C]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_controlled(i32 %[[F1:[a-zA-Z0-9_.]+]], i32 %[[ARR:[a-zA-Z0-9_.]+]], i32 %[[S]], i32 %[[V1:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cq_template_sext_i8_to_i32_unc(i32 %[[S]], i32 %[[C]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[S]])
; CHECK:      %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i8_to_i32(i32 %[[C]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_controlled(i32 %[[F2:[a-zA-Z0-9_.]+]], i32 %[[ARR]], i32 %[[Z]], i32 %[[V2:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cq_template_zext_i8_to_i32_unc(i32 %[[Z]], i32 %[[C]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[Z]])
; Reversal (LIFO): the zext store's `_unc` re-reads the index through a ZEXT
; bracket, the sext store's through a SEXT bracket — each its own forward's cast.
; CHECK:      %[[ZU:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i8_to_i32(i32 %[[C]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_controlled_unc(i32 %[[F2]], i32 %[[ARR]], i32 %[[ZU]], i32 %[[V2]])
; CHECK-NEXT: call void @cq_template_zext_i8_to_i32_unc(i32 %[[ZU]], i32 %[[C]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[ZU]])
; CHECK:      %[[SU:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i8_to_i32(i32 %[[C]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_controlled_unc(i32 %[[F1]], i32 %[[ARR]], i32 %[[SU]], i32 %[[V1]])
; CHECK-NEXT: call void @cq_template_sext_i8_to_i32_unc(i32 %[[SU]], i32 %[[C]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[SU]])
; CHECK:      ret i32
