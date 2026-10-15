; control_classical_call_arm_accept_clang_return_contract.ll — ACCEPT (bd test_C_libtooling-bwfp).
; R11 round 3 F2/F3: ordinary C whose clang -O1 output carries contracts the round-3
; snapshot (sha 8c141046) could not prove, so it declined what e0af16ed lowered:
;   @cls  `int cls(int x){return x > 0 ? 1 : 2;}`   -> `noundef range(i32 1, 3)`
;   @md   `unsigned md(unsigned x){return x % 10u;}` -> `noundef range(i32 0, 10)`
;   @pick `int pick(int x,int y){return x;}` from ANOTHER TU (llvm-linked, as
;         run_slice_multi.sh does)                  -> `i32 noundef returned %0`
; Known bits alone cannot see either range (`select 2, 1` has no common bit;
; `urem` by 10 bounds no bit). The proof now intersects `computeConstantRange` with
; known bits in both signednesses, and `returned` is admitted when every `ret` of
; the callee returns that parameter (review round 4: LLVM's known bits trust it, so
; an unverified one proves false ranges). IR below is the clang 19.1.7 -O1 output of those
; definitions with target attributes trimmed. `@pick`'s unread second slot may be
; neutralised to 0 (the pre-existing dead-slot rule, `SpecDeadArgMask`; e0af16ed too).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @ex1(
; CHECK:       %[[R1:[a-zA-Z0-9_.]+]] = tail call i32 @cls(i32 noundef %0)
; CHECK:       call void @cqrt_xorc_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[R1]])
; CHECK-LABEL: define i32 @ex2(
; CHECK:       %[[R2:[a-zA-Z0-9_.]+]] = tail call i32 @md(i32 noundef %0)
; CHECK:       call void @cqrt_xorc_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[R2]])
; CHECK-LABEL: define i32 @ex4(
; CHECK:       %[[R4:[a-zA-Z0-9_.]+]] = tail call i32 @pick(i32 noundef %0, i32 noundef {{%1|0}})
; CHECK:       call void @cqrt_xorc_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[R4]])

define noundef range(i32 1, 3) i32 @cls(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp slt i32 %0, 1
  %3 = select i1 %2, i32 2, i32 1
  ret i32 %3
}

define noundef range(i32 0, 10) i32 @md(i32 noundef %0) local_unnamed_addr #0 {
  %2 = urem i32 %0, 10
  ret i32 %2
}

define noundef i32 @pick(i32 noundef returned %0, i32 noundef %1) local_unnamed_addr #0 {
  ret i32 %0
}

define i32 @ex1(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #2
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %6

4:
  %5 = tail call i32 @cls(i32 noundef %0)
  br label %6

6:
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8
}

define i32 @ex2(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_ui32(i32 noundef 0, double noundef 0.000000e+00) #2
  %3 = icmp ugt i32 %2, 3
  br i1 %3, label %4, label %6

4:
  %5 = tail call i32 @md(i32 noundef %0)
  br label %6

6:
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #3
  ret i32 %8
}

define i32 @ex4(i32 noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #2
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %7

5:
  %6 = tail call i32 @pick(i32 noundef %0, i32 noundef %1) #3
  br label %7

7:
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr
declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
