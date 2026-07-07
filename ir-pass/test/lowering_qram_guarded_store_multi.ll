; lowering_qram_guarded_store_multi.ll — ACCEPT (g5gi): TWO separate guarded-store
; diamonds that SHARE a block —
;   if (q < 3) { arr[i] = 7; }   if (q < 5) { arr[j] = 8; }
; The first diamond's merge (`%merge1`) is the SECOND diamond's `Pred`. BOTH are
; recognized as GuardedStoreArm regions. v1 (iw81.7) declined this via the
; cross-region block-lifetime pre-flight, which marked `%merge1` (the first region's
; MergeBB) "doomed" and saw the second region reference it. g5gi exempts a
; GuardedStoreArm's MergeBB from the doomed set: `emitGuardedStoreArmRegion` erases
; ONLY the `Arm` block — it rewires `Pred → MergeBB` unconditionally and LEAVES
; `MergeBB` intact (unlike the phase / if-else flatten). So the two diamonds are
; independent and both lower.
;
; Each store is guarded on its OWN path-predicate flag; the whole-DAG LIFO uncompute
; reverses both stores + both flag strips in strict reverse program order (store2
; before store1; each flag stripped-then-freed after its store-reverse). The array
; handle is NEVER freed (§2.9).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @two_diamonds(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %j = call i32 @cq_theta_si32(i32 %u2, double 5.000000e-01)
  %f1 = icmp slt i32 %q, 3
  br i1 %f1, label %arm1, label %merge1

arm1:
  %si = sext i32 %i to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %si
  store i32 7, ptr %g, align 4
  br label %merge1

merge1:                                           ; the FIRST merge == SECOND Pred
  %f2 = icmp slt i32 %q, 5
  br i1 %f2, label %arm2, label %merge2

arm2:
  %sj = sext i32 %j to i64
  %gj = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %sj
  store i32 8, ptr %gj, align 4
  br label %merge2

merge2:
  %sq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %sq
  %v = load i32, ptr %gq, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; Forward: ONE array handle, then the first guarded store (flag1 = q<3), then — in
; the SURVIVING merge1 block — the second guarded store (flag2 = q<5). Two DISTINCT
; flags, one shared array handle:
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:     call void @cqrt_qram_store_i32_controlled(i32 %[[F1]], i32 %[[ARR]], i32 %[[I1:[a-zA-Z0-9_.]+]], i32 %[[V1:[a-zA-Z0-9_.]+]])
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_qram_store_i32_controlled(i32 %[[F2]], i32 %[[ARR]], i32 %[[I2:[a-zA-Z0-9_.]+]], i32 %[[V2:[a-zA-Z0-9_.]+]])
; The load is copied out to a kept measured carrier:
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[Q]])
; CHECK:     call void @cqrt_copy_i32(i32 %[[V]],
; Reversal (LIFO): load_unc + free, then store2's `_controlled_unc` + strip2 + free
; flag2, then store1's `_controlled_unc` + strip1 + free flag1 — store2 reverses
; BEFORE store1 (reverse of the forward push order), each flag stripped-then-freed
; after its store-reverse (the pred-lifetime invariant, per store):
; CHECK:     call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[Q]])
; CHECK:     call void @cqrt_qram_store_i32_controlled_unc(i32 %[[F2]], i32 %[[ARR]], i32 %[[I2]], i32 %[[V2]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cqrt_qram_store_i32_controlled_unc(i32 %[[F1]], i32 %[[ARR]], i32 %[[I1]], i32 %[[V1]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; The array handle is NEVER freed; the diamonds/raw stores/raw compares are gone:
; CHECK-NOT: call void @cqrt_free(i32 %[[ARR]])
; CHECK-NOT: br i1
; CHECK-NOT: store i32
; CHECK-NOT: = icmp
; CHECK-NOT: cq taint escape
