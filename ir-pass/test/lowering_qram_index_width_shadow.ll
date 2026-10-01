; lowering_qram_index_width_shadow.ll — ACCEPT (libcqops handoff b6a): the
; local-array (`processShadowAlloca`) twin of lowering_qram_index_width_qrom.ll.
; A store, a GUARDED store (under tainted control) and a load, each with a
; native i64 (`long`) index. Every QRAM call — forward AND every `_unc` the
; spine emits — gets its OWN `trunc; call; trunc_unc; free` bracket
; (`bracketQramIndexCasts`, after `uncompute`), so the index rail it reads is
; 32 bits wide and no cast rail is ever live across another gate.
;
; @main is the round-1 review's F1: a first draft kept ONE
; cast rail per access alive until the access was reversed — or forever, for a
; store that is never reversed. That rail is a CNOT copy of the index register,
; so the later `cq_theta(b, -0.5)` rotated a register entangled with it: the
; source measures b == 0 with probability 1, the draft gave P(b == 1) ≈ 0.115
; (`opt` rc 0, stage 2b clean, one `live derived record` warning). It is `main`
; because outside `main` this shape declined before and after b6a ("dead chain
; would free a measured register"); since bd 01po.4 the non-main form lowers too
; (lowering_qram_store_measured_index_nonmain.ll). Pinned here:
; the store's bracket closes (`cqrt_free`) before the rotation, and no warning.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.cqd0.ll
; DIAG-NOT: live derived record
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_theta_sll(i64, double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @shadow_long(i64 %u0, i64 %u1, i32 %ux, i32 %uc) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %p = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %q = call i64 @cq_theta_sll(i64 %u1, double 5.000000e-01)
  %x = call i32 @cq_theta_si32(i32 %ux, double 5.000000e-01)
  %c = call i32 @cq_theta_si32(i32 %uc, double 5.000000e-01)
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %p
  store i32 %x, ptr %gp, align 4                  ; arr[p] = x — plain store
  %f = icmp slt i32 %c, 3
  br i1 %f, label %arm, label %merge

arm:
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %q
  store i32 7, ptr %gq, align 4                   ; if (c<3) arr[q] = 7 — guarded
  br label %merge

merge:
  %gl = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %q
  %v = load i32, ptr %gl, align 4                 ; arr[q] — load
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK-LABEL: define i32 @shadow_long(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %u0)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %u1)
; Forward: each call in its own bracket over its i64 index rail.
; CHECK:      %[[T1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[P]])
; CHECK-NEXT: call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[T1]], i32 %[[X:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[T1]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T1]])
; CHECK:      %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_controlled(i32 %[[FLAG:[a-zA-Z0-9_.]+]], i32 %[[ARR]], i32 %[[T2]], i32 %[[VAL:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[T2]], i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T2]])
; CHECK:      %[[T3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[Q]])
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[T3]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[T3]], i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T3]])
; Reversal (LIFO: load, guarded store, store), each `_unc` in its own bracket:
; CHECK:      %[[U3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[U3]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[U3]], i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[U3]])
; CHECK:      %[[U2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_controlled_unc(i32 %[[FLAG]], i32 %[[ARR]], i32 %[[U2]], i32 %[[VAL]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[U2]], i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[U2]])
; CHECK:      %[[U1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[P]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[U1]], i32 %[[X]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[U1]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[U1]])
; No QRAM call takes a raw i64 rail as its index:
; CHECK-NOT:  @cqrt_qram_{{[a-z_0-9]+}}({{.*}}i32 %[[P]]
; CHECK-NOT:  @cqrt_qram_{{[a-z_0-9]+}}({{.*}}i32 %[[Q]]
; CHECK:      ret i32

define i32 @main(i1 %u0, i1 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %zb = zext i1 %b to i64
  %gb = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zb
  store i32 0, ptr %gb, align 4                   ; arr[b] = 0 — never reversed
  %p = call i1 @cq_theta_i1(i1 %u1, double 5.000000e-01)
  %zp = zext i1 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zp
  %v = load i32, ptr %gp, align 4
  %b2 = call i1 @cq_theta_i1(i1 %b, double -5.000000e-01)   ; b rotated back
  %mb = call i1 @cq_measure_i1(i1 %b2)
  %mv = call i32 @cq_measure_si32(i32 %v)
  %zmb = zext i1 %mb to i32
  %r = add i32 %mv, %zmb
  ret i32 %r
}

; CHECK-LABEL: define i32 @main(
; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK:      %[[BT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[B]])
; CHECK-NEXT: call void @cqrt_qram_store_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[BT]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[BT]], i32 %[[B]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BT]])
; CHECK:      call void @cqrt_ry_i1(i32 %[[B]], double -5.000000e-01)
; CHECK:      ret i32
