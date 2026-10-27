; HAND-WRITTEN. Rules: 14, 18, 9, 8, 4, 5, 2.
; Checked: chain(n & 3, a) with the recursion cut at depth min(K, B) = 3 (K = 4, B = 3; measured).
; Clean: the scrutinee n & 3; inside every level and every defined twin: the base-case flag, n - 1, the next level's result
; (zeroed by the twin, then freed), the difference, the merge, and at level 3 the cut call's |0> rail.
; Kept: the user register n; the level-0 clone's copied-out result rail (measured). No a_K: the depth n & 3 is at most
; B = 3 recursive calls (LLVM's range fact on the and), B <= K, so by rule 14 the overflow predicate is not kept.
; Rotations: Ry(th) on n.
; TRUE RECURSION WITH QUANTUM DEPTH (rule 14): clang cannot loop-convert chain (the result is used
; non-associatively), so the clone recurses. The recursion is bounded exactly as a loop is (09/37: a level is a trip
; of a header-test loop, its recursive call the back edge). Cutoff C = min(K, B) with K = 4 and B = 3 (n & 3 <= 3, so
; at most three recursive calls; the call site is tagged [K]): one clone per recursion LEVEL d = 0..C,
; __cq_q_chain_10 then __cq_q_chain_10_d1.._d3, each the clone of the same body whose recursive call site calls the
; next level; at level C = 3 the call is CUT and its value is a |0> rail (rule 14: the call at level K, here C, is
; replaced). The after-K notion is the loop's: the overflow predicate is "level C would recurse once more" =
; NOT c at level 3 under the chain, the analogue of a header-test loop's a_K (09). Here n_3 = (n & 3) - 3 <= 0, so
; it is |0> on every branch and nothing is kept (B <= K); with B > K or no bound it would be the kept output rail.
; The level's frame is the clone's own SSA values and LLVM's classical call stack; this is the
; frame-stack form of the loop-carried handle discipline: a rolled loop keeps the per-trip handles on the cqrt_push/pop stack
; because one body runs K times, a recursion keeps them in one body per level, so no runtime handle stack is
; needed. The recursive call runs unguarded (its value is read by nothing when the base case holds); the phi over base
; case / recursive arm is a select on the base-case flag (rule 9). Every level uncomputes its callee through the next
; level's _unc twin (07, rule 18); the twins recurse the same way. Cost is 2^K calls of the deepest level. Level 0 is
; called only by the entry, which measures its result, so __cq_q_chain_10 has no twin (§1.4: a twin nobody calls is not
; defined); the twins are _d1_unc.._d3_unc.
source_filename = "quantum_depth_recursion.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @quantum_depth_recursion(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register n]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)    ; IR: %5 = and i32 %4, 3
  %6 = call fastcc i32 @__cq_q_chain_10(i32 %5, i32 %2)    ; IR: %6 = call @chain(%5, %2), quantum clone (arg 0 quantum), recursion level 0  [K]
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 3)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_si32(%6)
  ret i32 %7    ; IR: ret i32 %7
}

define internal fastcc i32 @__cq_q_chain_10(i32 %0, i32 %1) {    ; IR: chain at recursion level 0
  %3 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 1)    ; IR: %3 = icmp slt i32 %0, 1  [base-case flag; the recursive arm runs under NOT c]
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -1)    ; IR: %7 = add nsw i32 %0, -1
  %5 = add nsw i32 %1, 1    ; IR: %8 = add nsw i32 %1, 1  (classical)
  %6 = call fastcc i32 @__cq_q_chain_10_d1(i32 %4, i32 %5)    ; IR: %9 = call @chain(%7, %8), the next level's clone (unguarded: read by nothing when c holds)
  %7 = call i32 @cq_template_sub_i32_lh(i32 %1, i32 %6)    ; IR: %10 = sub nsw i32 %1, %9
  %8 = call i32 @cq_template_select_i32_lh(i32 %3, i32 %1, i32 %7)    ; IR: %5 = phi [ %10, %6 ], [ %1, %2 ]: c ? a : %10
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %5  [result rail of the call]
  call void @cqrt_copy_i32(i32 %8, i32 %9)    ; IR: ret i32 %5  [copy the result out]
  call void @cq_template_select_i32_lh_unc(i32 %8, i32 %3, i32 %1, i32 %7)    ; IR: uncompute %5
  call void @cqrt_free(i32 %8)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %7, i32 %1, i32 %6)    ; IR: uncompute %10
  call void @cqrt_free(i32 %7)    ; IR: release the %10 rail (|0>)
  call fastcc void @__cq_q_chain_10_d1_unc(i32 %6, i32 %4, i32 %5)    ; IR: uncompute %9 (adjoint of the call)
  call void @cqrt_free(i32 %6)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 -1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %4)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %3, i32 %0, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret i32 %9    ; IR: ret i32 %5
}

define internal fastcc i32 @__cq_q_chain_10_d1(i32 %0, i32 %1) {    ; IR: chain at recursion level 1
  %3 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 1)    ; IR: %3 = icmp slt i32 %0, 1  [base-case flag; the recursive arm runs under NOT c]
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -1)    ; IR: %7 = add nsw i32 %0, -1
  %5 = add nsw i32 %1, 1    ; IR: %8 = add nsw i32 %1, 1  (classical)
  %6 = call fastcc i32 @__cq_q_chain_10_d2(i32 %4, i32 %5)    ; IR: %9 = call @chain(%7, %8), the next level's clone (unguarded: read by nothing when c holds)
  %7 = call i32 @cq_template_sub_i32_lh(i32 %1, i32 %6)    ; IR: %10 = sub nsw i32 %1, %9
  %8 = call i32 @cq_template_select_i32_lh(i32 %3, i32 %1, i32 %7)    ; IR: %5 = phi [ %10, %6 ], [ %1, %2 ]: c ? a : %10
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %5  [result rail of the call]
  call void @cqrt_copy_i32(i32 %8, i32 %9)    ; IR: ret i32 %5  [copy the result out]
  call void @cq_template_select_i32_lh_unc(i32 %8, i32 %3, i32 %1, i32 %7)    ; IR: uncompute %5
  call void @cqrt_free(i32 %8)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %7, i32 %1, i32 %6)    ; IR: uncompute %10
  call void @cqrt_free(i32 %7)    ; IR: release the %10 rail (|0>)
  call fastcc void @__cq_q_chain_10_d2_unc(i32 %6, i32 %4, i32 %5)    ; IR: uncompute %9 (adjoint of the call)
  call void @cqrt_free(i32 %6)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 -1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %4)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %3, i32 %0, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret i32 %9    ; IR: ret i32 %5
}

define internal fastcc void @__cq_q_chain_10_d1_unc(i32 %0, i32 %1, i32 %2) {    ; IR: adjoint of chain at level 1
  %4 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)    ; IR: recompute %3
  %5 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)    ; IR: recompute %7
  %6 = add nsw i32 %2, 1    ; IR: %8  (classical)
  %7 = call fastcc i32 @__cq_q_chain_10_d2(i32 %5, i32 %6)    ; IR: %9 = call @chain(%7, %8), the next level's clone (unguarded: read by nothing when c holds)
  %8 = call i32 @cq_template_sub_i32_lh(i32 %2, i32 %7)    ; IR: recompute %10
  %9 = call i32 @cq_template_select_i32_lh(i32 %4, i32 %2, i32 %8)    ; IR: recompute %5
  call void @cqrt_copy_i32(i32 %9, i32 %0)    ; IR: ret i32 %5  [xor the result out of %out]
  call void @cq_template_select_i32_lh_unc(i32 %9, i32 %4, i32 %2, i32 %8)    ; IR: uncompute %5
  call void @cqrt_free(i32 %9)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %8, i32 %2, i32 %7)    ; IR: uncompute %10
  call void @cqrt_free(i32 %8)    ; IR: release the %10 rail (|0>)
  call fastcc void @__cq_q_chain_10_d2_unc(i32 %7, i32 %5, i32 %6)    ; IR: uncompute %9 (adjoint of the call)
  call void @cqrt_free(i32 %7)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %1, i32 -1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %5)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %4, i32 %1, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  ret void
}

define internal fastcc i32 @__cq_q_chain_10_d2(i32 %0, i32 %1) {    ; IR: chain at recursion level 2
  %3 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 1)    ; IR: %3 = icmp slt i32 %0, 1  [base-case flag; the recursive arm runs under NOT c]
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -1)    ; IR: %7 = add nsw i32 %0, -1
  %5 = add nsw i32 %1, 1    ; IR: %8 = add nsw i32 %1, 1  (classical)
  %6 = call fastcc i32 @__cq_q_chain_10_d3(i32 %4, i32 %5)    ; IR: %9 = call @chain(%7, %8), the next level's clone (unguarded: read by nothing when c holds)
  %7 = call i32 @cq_template_sub_i32_lh(i32 %1, i32 %6)    ; IR: %10 = sub nsw i32 %1, %9
  %8 = call i32 @cq_template_select_i32_lh(i32 %3, i32 %1, i32 %7)    ; IR: %5 = phi [ %10, %6 ], [ %1, %2 ]: c ? a : %10
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %5  [result rail of the call]
  call void @cqrt_copy_i32(i32 %8, i32 %9)    ; IR: ret i32 %5  [copy the result out]
  call void @cq_template_select_i32_lh_unc(i32 %8, i32 %3, i32 %1, i32 %7)    ; IR: uncompute %5
  call void @cqrt_free(i32 %8)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %7, i32 %1, i32 %6)    ; IR: uncompute %10
  call void @cqrt_free(i32 %7)    ; IR: release the %10 rail (|0>)
  call fastcc void @__cq_q_chain_10_d3_unc(i32 %6, i32 %4, i32 %5)    ; IR: uncompute %9 (adjoint of the call)
  call void @cqrt_free(i32 %6)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 -1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %4)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %3, i32 %0, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret i32 %9    ; IR: ret i32 %5
}

define internal fastcc void @__cq_q_chain_10_d2_unc(i32 %0, i32 %1, i32 %2) {    ; IR: adjoint of chain at level 2
  %4 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)    ; IR: recompute %3
  %5 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)    ; IR: recompute %7
  %6 = add nsw i32 %2, 1    ; IR: %8  (classical)
  %7 = call fastcc i32 @__cq_q_chain_10_d3(i32 %5, i32 %6)    ; IR: %9 = call @chain(%7, %8), the next level's clone (unguarded: read by nothing when c holds)
  %8 = call i32 @cq_template_sub_i32_lh(i32 %2, i32 %7)    ; IR: recompute %10
  %9 = call i32 @cq_template_select_i32_lh(i32 %4, i32 %2, i32 %8)    ; IR: recompute %5
  call void @cqrt_copy_i32(i32 %9, i32 %0)    ; IR: ret i32 %5  [xor the result out of %out]
  call void @cq_template_select_i32_lh_unc(i32 %9, i32 %4, i32 %2, i32 %8)    ; IR: uncompute %5
  call void @cqrt_free(i32 %9)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %8, i32 %2, i32 %7)    ; IR: uncompute %10
  call void @cqrt_free(i32 %8)    ; IR: release the %10 rail (|0>)
  call fastcc void @__cq_q_chain_10_d3_unc(i32 %7, i32 %5, i32 %6)    ; IR: uncompute %9 (adjoint of the call)
  call void @cqrt_free(i32 %7)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %1, i32 -1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %5)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %4, i32 %1, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  ret void
}

define internal fastcc i32 @__cq_q_chain_10_d3(i32 %0, i32 %1) {    ; IR: chain at recursion level 3
  %3 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 1)    ; IR: %3 = icmp slt i32 %0, 1  [base-case flag; the recursive arm runs under NOT c]
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -1)    ; IR: %7 = add nsw i32 %0, -1
  %5 = add nsw i32 %1, 1    ; IR: %8 = add nsw i32 %1, 1  (classical)
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %9 = call @chain(%7, %8): level C = min(K, B) = 3 reached [K], the call is CUT: a |0> rail (n - 3 <= 0, so NOT c = |0> here)
  %7 = call i32 @cq_template_sub_i32_lh(i32 %1, i32 %6)    ; IR: %10 = sub nsw i32 %1, %9
  %8 = call i32 @cq_template_select_i32_lh(i32 %3, i32 %1, i32 %7)    ; IR: %5 = phi [ %10, %6 ], [ %1, %2 ]: c ? a : %10
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %5  [result rail of the call]
  call void @cqrt_copy_i32(i32 %8, i32 %9)    ; IR: ret i32 %5  [copy the result out]
  call void @cq_template_select_i32_lh_unc(i32 %8, i32 %3, i32 %1, i32 %7)    ; IR: uncompute %5
  call void @cqrt_free(i32 %8)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %7, i32 %1, i32 %6)    ; IR: uncompute %10
  call void @cqrt_free(i32 %7)    ; IR: release the %10 rail (|0>)
  call void @cqrt_free(i32 %6)    ; IR: release the cut call's zero rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 -1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %4)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %3, i32 %0, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret i32 %9    ; IR: ret i32 %5
}

define internal fastcc void @__cq_q_chain_10_d3_unc(i32 %0, i32 %1, i32 %2) {    ; IR: adjoint of chain at level 3
  %4 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)    ; IR: recompute %3
  %5 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)    ; IR: recompute %7
  %6 = add nsw i32 %2, 1    ; IR: %8  (classical)
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %9 = call @chain(%7, %8): level C = min(K, B) = 3 reached [K], the call is CUT: a |0> rail (n - 3 <= 0, so NOT c = |0> here)
  %8 = call i32 @cq_template_sub_i32_lh(i32 %2, i32 %7)    ; IR: recompute %10
  %9 = call i32 @cq_template_select_i32_lh(i32 %4, i32 %2, i32 %8)    ; IR: recompute %5
  call void @cqrt_copy_i32(i32 %9, i32 %0)    ; IR: ret i32 %5  [xor the result out of %out]
  call void @cq_template_select_i32_lh_unc(i32 %9, i32 %4, i32 %2, i32 %8)    ; IR: uncompute %5
  call void @cqrt_free(i32 %9)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %8, i32 %2, i32 %7)    ; IR: uncompute %10
  call void @cqrt_free(i32 %8)    ; IR: release the %10 rail (|0>)
  call void @cqrt_free(i32 %7)    ; IR: release the cut call's zero rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %1, i32 -1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %5)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %4, i32 %1, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_lh(i32, i32)
declare void @cq_template_sub_i32_lh_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)


!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}
!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
