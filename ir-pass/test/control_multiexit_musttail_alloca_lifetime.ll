; control_multiexit_musttail_alloca_lifetime.ll — ACCEPT (bd test_C_libtooling-dm7f.5,
; review round 1 F1). `@example` is `clang -O1`'s output (cleaned of target attributes
; and TBAA) for
;     __attribute__((noinline)) int f(int u, int a) {
;       int buf[2] = {a, u}; int s = sum2(buf);
;       int q = u; cq_theta(&q, 0.5);
;       if (q > 3) __attribute__((musttail)) return k(u, s);
;       return 5;
;     }
; `buf` survives -O1 (its address reaches `sum2`), so clang closes its lifetime with
; `llvm.lifetime.end` before the plain `ret` and emits none before the `musttail` one.
; `@twin` is clang's output for the same source WITHOUT the attribute: ONE `ret` block
; holding the merge phi, then the marker. Before the fix the former `ret 5` block kept
; its marker, was not empty, was never folded, and the module declined `value-arm
; swap-route under quantum control` while `@twin` compiled (review probe p4/p4t).
; `unifyTaintedReturns` now SINKS the `lifetime.end` markers that close a former `ret`
; block into `cq.retmerge` (after the phi, before the `ret`, duplicates dropped) when
; the marker's pointer is a static entry-block `alloca` (it dominates the merge), so
; the block empties, folds, and the module is `@twin`. Sound: the marker now also runs
; after the demoted `k` call, at the point the function returns; `tail` and `musttail`
; both promise `k` does not touch the caller's allocas, and `@twin` runs that same
; marker on the same path. Both streams are pinned line for line.
;
; HAND TRACE. q = Ry(0.5)|u0>; s = sum2(buf) and r = k(poison, s) run classically
; (r hoisted, its operand frozen); f = [x > 3]; out = |0>, XOR-copied from alloc(r)
; under f and from alloc(5) under NOT f; f stripped to 0 and freed; `buf` dies; out
; escapes.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=LCNT < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

define i32 @k(i32 %u, i32 %a) #0 {
  %s = add nsw i32 %a, 100
  ret i32 %s
}

define i32 @sum2(ptr nocapture noundef readonly %p) #1 {
  %x = load i32, ptr %p, align 4
  %g = getelementptr inbounds i8, ptr %p, i64 4
  %y = load i32, ptr %g, align 4
  %s = add nsw i32 %y, %x
  ret i32 %s
}

define i32 @example(i32 noundef %u0, i32 noundef %a) {
entry:
  %buf = alloca [2 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %buf)
  store i32 %a, ptr %buf, align 4
  %hi = getelementptr inbounds i8, ptr %buf, i64 4
  store i32 %u0, ptr %hi, align 4
  %s = call i32 @sum2(ptr noundef nonnull %buf)
  %q = call i32 @cq_theta_si32(i32 noundef %u0, double noundef 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %other
arm:
  %r = musttail call i32 @k(i32 poison, i32 noundef %s)
  ret i32 %r
other:
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %buf)
  ret i32 5
}

define i32 @twin(i32 noundef %u0, i32 noundef %a) {
entry:
  %buf = alloca [2 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %buf)
  store i32 %a, ptr %buf, align 4
  %hi = getelementptr inbounds i8, ptr %buf, i64 4
  store i32 %u0, ptr %hi, align 4
  %s = call i32 @sum2(ptr noundef nonnull %buf)
  %q = call i32 @cq_theta_si32(i32 noundef %u0, double noundef 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %m
arm:
  %r = tail call i32 @k(i32 poison, i32 noundef %s)
  br label %m
m:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %buf)
  ret i32 %y
}

attributes #0 = { noinline nounwind willreturn memory(none) }
attributes #1 = { noinline nounwind willreturn memory(argmem: read) }

; CHECK: define i32 @example(i32 noundef %u0, i32 noundef %a) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %buf = alloca [2 x i32], align 4
; CHECK-NEXT: call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %buf)
; CHECK-NEXT: store i32 %a, ptr %buf, align 4
; CHECK-NEXT: %hi = getelementptr inbounds i8, ptr %buf, i64 4
; CHECK-NEXT: store i32 %u0, ptr %hi, align 4
; CHECK-NEXT: %s = call i32 @sum2(ptr noundef nonnull %buf)
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[FR:[a-zA-Z0-9_.]+]] = freeze i32 %s
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call i32 @k(i32 poison, i32 noundef %[[FR]])
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[S1]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[S2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %buf)
; CHECK-NEXT: ret i32 %[[OUT]]
; CHECK-NEXT: }
; CHECK: define i32 @twin(i32 noundef %u0, i32 noundef %a) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %buf = alloca [2 x i32], align 4
; CHECK-NEXT: call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %buf)
; CHECK-NEXT: store i32 %a, ptr %buf, align 4
; CHECK-NEXT: %hi = getelementptr inbounds i8, ptr %buf, i64 4
; CHECK-NEXT: store i32 %u0, ptr %hi, align 4
; CHECK-NEXT: %s = call i32 @sum2(ptr noundef nonnull %buf)
; CHECK-NEXT: %[[TH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[TH]], double 5.000000e-01)
; CHECK-NEXT: %[[TFR:[a-zA-Z0-9_.]+]] = freeze i32 %s
; CHECK-NEXT: %[[TR:[a-zA-Z0-9_.]+]] = tail call i32 @k(i32 poison, i32 noundef %[[TFR]])
; CHECK-NEXT: %[[TF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[TH]], i32 3)
; CHECK-NEXT: %[[TOUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[TS1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[TR]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[TF]], i32 %[[TS1]], i32 %[[TOUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[TF]])
; CHECK-NEXT: %[[TS2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[TF]], i32 %[[TS2]], i32 %[[TOUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[TF]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[TF]], i32 %[[TH]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[TF]])
; CHECK-NEXT: call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %buf)
; CHECK-NEXT: ret i32 %[[TOUT]]
; CHECK-NEXT: }

; WHOLE-FILE, PURE-NEGATIVE. (`musttail call`: the ModuleID line carries this file's name.)
; NEG-NOT: musttail call
; NEG-NOT: cq.retmerge

; One `lifetime.end` per function: the sunk marker is not duplicated.
; LCNT-COUNT-2: call void @llvm.lifetime.end.p0(
; LCNT-NOT:     call void @llvm.lifetime.end.p0(
