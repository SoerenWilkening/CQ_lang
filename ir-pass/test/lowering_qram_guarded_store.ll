; lowering_qram_guarded_store.ll — ACCEPT (iw81.7): a tainted-index Shadow STORE
; UNDER tainted control — `if (q < 3) { arr[i] = 7; }  v = arr[q]; measure(v)`. The
; store arm is SIDE-EFFECT-ONLY (a gep + store, NO merge phi). It is NOT swap-routable
; (memory has no per-arm work rail; swap-routing writes arr[0]=0 on the inactive
; branch) — it is GENUINELY CONTROLLED. The control emitter mints the path-predicate
; flag from the pre-store condition handle, records (store->flag), FLATTENS the diamond
; (splice the gep+store into Pred, unconditional br to the merge), and leaves the flag
; LIVE. `lowerShadowMemory` emits the guarded store `cqrt_qram_store_i32_controlled(
; flag, arr, idx, val)` (Bennett emit_shadow_store_guarded! — a no-op when flag=0). The
; whole-DAG LIFO uncompute reverses it via `..._controlled_unc` (flag arg 0, still LIVE)
; and THEN strips the flag (`cq_template_icmp_slt_i32_hl_unc`) — the store-reverse-
; then-strip ORDER is the pred-lifetime invariant (an ungated / pre-stripped `_unc`
; over-pops the inactive branch, a dephasing silent miscompile). The array handle is
; a classical resource token, NEVER freed (§2.9). NO measurement is inserted the user
; did not write (Rule 5).
;
; The post-diamond load `arr[q]` is UNCONDITIONAL (it post-dominates the branch), so
; the iw81.7 control-dependence refinement of `instUnderTaintedControl` accepts it as
; straight-line 7.5 (a plain-dominance test over-declined it).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @guarded(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %f = icmp slt i32 %q, 3
  br i1 %f, label %arm, label %merge

arm:                                              ; the side-effect-only store arm
  %si = sext i32 %i to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %si
  store i32 7, ptr %g, align 4                    ; arr[i] = 7 — tainted index, guarded
  br label %merge

merge:
  %sq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %sq
  %v = load i32, ptr %gq, align 4                 ; arr[q] — unconditional (post-dominates)
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; Forward: array birth, the flag mint, the store value handle, then the GUARDED store
; (flag arg 0, arr arg 1). The diamond is FLATTENED (the arm's store lives in the
; straight-line stream; no br i1, no raw icmp/store survive):
; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:     %[[VAL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK:     call void @cqrt_qram_store_i32_controlled(i32 %[[FLAG]], i32 %[[ARR]], i32 %[[IDX:[a-zA-Z0-9_.]+]], i32 %[[VAL]])
; The post-diamond load is accepted (unconditional) and copied out to a kept carrier:
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[Q]])
; CHECK:     %[[RET:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[V]], i32 %[[RET]])
; Reversal (LIFO): load_unc + free, then the GUARDED store `_controlled_unc` with the
; flag STILL LIVE (arg 0), then the flag STRIP — the store-reverse-BEFORE-strip order
; is the pred-lifetime invariant:
; CHECK:     call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[Q]])
; CHECK:     call void @cqrt_qram_store_i32_controlled_unc(i32 %[[FLAG]], i32 %[[ARR]], i32 %[[IDX]], i32 %[[VAL]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[FLAG]], i32 %[[Q]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; The carrier is measured; the array handle is NEVER freed (a classical resource):
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[RET]])
; CHECK-NOT: call void @cqrt_free(i32 %[[ARR]])
; The diamond, the raw store, and the raw compare are all gone:
; CHECK-NOT: br i1
; CHECK-NOT: store i32
; CHECK-NOT: = icmp
; CHECK-NOT: cq taint escape
