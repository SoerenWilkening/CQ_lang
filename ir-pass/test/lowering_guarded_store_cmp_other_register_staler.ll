; lowering_guarded_store_cmp_other_register_staler.ll — ACCEPT, the DISCRIMINATING
; control for `lowering_reject_guarded_store_cmp_blind_staler.ll` (Track A.1,
; Rule-13 ROUND-2 finding F-A1R2-1; probe `review_a1_r2_probes/gs3.c`, plain
; `clang -O1` C).
;
;     static int guarded_local(int seed) {
;       int arr[8] = {0};
;       int q  = cq_theta(seed, 0.5);
;       int t  = cq_theta(seed + 2, 0.5);
;       int t2 = cq_theta(t, 0.9);        /* staler on t's WIRE — NOT on q's */
;       int i  = cq_theta(seed + 1, 0.5);
;       if (q < 3) { arr[i] = 7; }
;       int v = arr[q];
;       return cq_measure(v) + cq_measure(t2);
;     }
;
; The guard's own rail (`%h`, `q`) carries no gate between its Ry and the flag
; mint, so `cq_template_icmp_slt_i32_hl(%h, 3)` encodes the source's predicate
; and the controlled Shadow store commits on the right amplitudes. If this file
; goes red, the F-A1R2-1 narrowing has stopped being about the condition's wire.
; GREEN on the ORACLE (`main` 0c7380c), on b439944 and here — MEASURED on all
; three.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @guarded_local() {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %arr, i8 0, i64 32, i1 false)
  %q  = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %t  = call i32 @cq_theta_si32(i32 2, double 5.000000e-01)
  %t2 = call i32 @cq_theta_si32(i32 %t, double 9.000000e-01)
  %i  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %c  = icmp slt i32 %q, 3
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry
  %si = sext i32 %i to i64
  %sp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %si
  store i32 7, ptr %sp, align 4
  br label %merge

merge:                                            ; preds = %arm, %entry
  %li = sext i32 %q to i64
  %lp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %li
  %v  = load i32, ptr %lp, align 4
  %m  = call i32 @cq_measure_si32(i32 %v)
  %m2 = call i32 @cq_measure_si32(i32 %t2)
  %s  = add nsw i32 %m2, %m
  ret i32 %s
}

; The flag reads the GUARD's own rail; the staler rides `%h1` (`t`):
; CHECK:      %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[HQ]], double 5.000000e-01)
; CHECK:      %[[HT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK:      call void @cqrt_ry_i32(i32 %[[HT]], double 5.000000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[HT]], double 9.000000e-01)
; CHECK:      %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[HQ]], i32 3)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cqrt_qram_store_i32_controlled_unc(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[FLAG]], i32 %[[HQ]], i32 3)
; CHECK:      call void @cqrt_free(i32 %[[FLAG]])
; CHECK-NOT:  cqrt_cswap
; CHECK-NOT:  br i1 

; Whole-file exact counts:
; RYCNT-COUNT-6: call void @cqrt_ry_i32(
; RYCNT-NOT:     call void @cqrt_ry
; MCNT-COUNT-2:  = call i32 @cqrt_measure_i32(
; MCNT-NOT:      call i32 @cqrt_measure
; FCNT-COUNT-2: call void @cqrt_free
; FCNT-NOT:     call void @cqrt_free
; XCNT-NOT:     call void @cqrt_x

; SILENT-NOT: cq controlled lowering
; SILENT-NOT: cq shadow
