; control_angle_select_ry_nested_mux_shared_node.ll — ACCEPT under the debug
; allocator (bd test_C_libtooling-dm7f.54 round-2 review F1, a USE-AFTER-FREE:
; revC54r2/p4.ll SIGSEGV'd `cq-opt-debugalloc`). The inner member's condition
; `n = la && lb` is an INTERIOR node of the outer member's tree `o = n || lz`.
; The round-1 emitter erased each member's dead tree in turn, freeing `n`, `la`,
; `lb` before the inner member's snapshot read them; the erase is now ONE
; liveness cascade over the UNION of every member's condition instructions,
; after all members are emitted. ANALYTIC: o -> Ry(.11); ¬o ∧ n -> Ry(.22)
; (unreachable: n implies o, so that leaf's predicate is 0 on every branch, its
; gate never fires); ¬o ∧ ¬n -> Ry(.33). Each member mints its own network from
; the shared leaves and strips it LIFO.
;
; RUN: %debugalloc-cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; CHECK:      call void @cqrt_ry_i1_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T:[a-zA-Z0-9_.]+]], double 1.100000e-01)
; CHECK:      call void @cqrt_ry_i1_controlled(i32 %[[P:p[0-9]*]], i32 %[[T]], double 2.200000e-01)
; CHECK:      call void @cqrt_ry_i1_controlled(i32 %[[P]], i32 %[[T]], double 3.300000e-01)
; CHECK:      call void @cqrt_free(i32 %[[P]])
; CHECK:      call i1 @cqrt_measure_i1(i32 %[[T]])
; NEG-NOT: = select
; NEG-NOT: = icmp
; NEG-NOT: cq_theta_

; outer member cond o = (la && lb) || lz ; inner member cond = n = (la && lb), a node of the outer tree
define i32 @f4() noinline {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %la = icmp sgt i32 %1, 3
  %lb = icmp eq i32 %2, 2
  %lz = icmp ult i32 %3, 7
  %n = select i1 %la, i1 %lb, i1 false
  %o = select i1 %n, i1 true, i1 %lz
  %s2 = select i1 %n, double 2.200000e-01, double 3.300000e-01
  %s1 = select i1 %o, double 1.100000e-01, double %s2
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %s1) #3
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #4
  %9 = zext i1 %8 to i32
  ret i32 %9
}
define i32 @main() {
  %1 = tail call i32 @f4()
  ret i32 %1
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
