; spec_accept_clone_classical_scope.ll — ACCEPT (bd p3kd.7.2 scoping pin): clone-mode
; PredMux roots regions at CLASSICAL terminators only inside the clone being
; lowered. The clone driver runs `flattenPredMuxRegions` over the WHOLE module with
; the clone's own taint set, so "is this function the clone" is asked as "does one
; of its ARGUMENTS carry that taint" (`hasTaintedArgument`): only the clone's
; parameters are in it. Here the CALLER has a classical diamond of its own and the
; ORIGINAL callee (kept for classical callers) has the classical diamond the clone
; if-converts; both must keep their branches. Only `__cq_q_helper_01` is flattened,
; into a classical choice of rail between the two quantum arms.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %c) {
entry:
  %cc = icmp sgt i32 %c, 0
  br i1 %cc, label %p, label %n
p:
  %bp = add i32 %b, %c
  br label %m
n:
  %bn = sub i32 %b, %c
  br label %m
m:
  %r = phi i32 [ %bp, %p ], [ %bn, %n ]
  ret i32 %r
}

define i32 @example(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %kk = icmp slt i32 %k, 100
  br i1 %kk, label %small, label %big
small:
  %k2 = mul i32 %k, 2
  br label %go
big:
  %k3 = add i32 %k, 1
  br label %go
go:
  %kv = phi i32 [ %k2, %small ], [ %k3, %big ]
  %r = call i32 @helper(i32 %q, i32 %kv)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; The original callee keeps its classical branch.
; CHECK-LABEL: define i32 @helper(
; CHECK:       br i1 %cc, label %p, label %n
; The caller keeps its classical branch around the lifted call.
; CHECK-LABEL: define i32 @example(
; CHECK:       br i1 %kk, label %small, label %big
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_01(i32 %{{[a-zA-Z0-9_.]+}}, i32 %kv)
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 %[[R]])
; The clone alone is flattened.
; CHECK-LABEL: define internal i32 @__cq_q_helper_01(i32 %b, i32 %c)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[CC:[a-zA-Z0-9_.]+]] = icmp sgt i32 %c, 0
; CHECK-NEXT:  %[[N:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_hl(i32 %b, i32 %c)
; CHECK-NEXT:  %[[P:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 %c)
; CHECK-NEXT:  %[[FC:[a-zA-Z0-9_.]+]] = freeze i1 %[[CC]]
; CHECK-NEXT:  %[[S:[a-zA-Z0-9_.]+]] = select i1 %[[FC]], i32 %[[P]], i32 %[[N]]
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[S]], i32 %[[OUT]])
; CHECK-NOT:   br
; CHECK:       ret i32 %[[OUT]]
