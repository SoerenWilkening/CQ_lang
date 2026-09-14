; control_swap_accept_select_mergephi_two_tree_leaves.ll — ACCEPT (bd `4aiu`,
; Track P). TWO prep merge φ as the TWO leaves of one `and i1` tree at the 4.4
; DATA SELECT — the shape that forced `ControlRegion::PrepRegionIdx` to become
; the LIST `PrepRegionIdxs`.
;
; WHY THE LIST IS THE ENFORCEMENT AND NOT A TIDINESS CHANGE. Each φ leaf is
; admitted by its OWN prep region, and each owes `lowerControlRegions` its own
; "prep before me" precedence edge (Track M's round-1 finding F-M1). A scalar
; field would have silently kept the LAST leaf's index and dropped the first
; region's edge — which is an over-decline at best (the H-1 backstop fires on a
; condition half-rewritten) and a use-after-free at worst. Two φ leaves cannot
; name ONE region (a `BranchRegion` has exactly one `Merge`), so `Pending` cannot
; be double-counted, and every such edge points INTO the select, so a
; `SelectRegion` still cannot lie on a precedence cycle.
;
; STREAM: the two prepped rails are read as the two READ-ONLY CONTROLS of one
; `cqrt_toffoli` onto a fresh `|0⟩` ancilla `g`; the copy merge writes
; `out = (g ? 2 : 5)` with both `cqrt_x` ON `g`; the SAME toffoli returns `g` to
; `|0⟩` on every branch (proven-`|0⟩` free, Rule 6). Neither user register is ever
; `cqrt_x`-bracketed or freed — `Ry(θ)|0⟩ ≠ |0⟩`, so both are left ALLOCATED.
;
; ⚠ RED ON THE ORACLE: `control flow` at `59ac5b7` (ROOT-ONLY grammar).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=TOFCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOPHI < %t.cqd0.ll

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br i1 %b0, label %a1, label %m1
a1:
  %t1 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br label %m1
m1:
  %p1 = phi i1 [ %t1, %a1 ], [ false, %entry ]
  br i1 %b0, label %a2, label %m2
a2:
  %t2 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 9.000000e-01)
  br label %m2
m2:
  %p2 = phi i1 [ %t2, %a2 ], [ false, %m1 ]
  %and = and i1 %p1, %p2
  %sel = select i1 %and, i32 2, i32 5
  %x1 = call zeroext i1 @cq_measure_i1(i1 zeroext %p1)
  %z1 = zext i1 %x1 to i32
  %x2 = call zeroext i1 @cq_measure_i1(i1 zeroext %p2)
  %z2 = zext i1 %x2 to i32
  %s0 = add nsw i32 %z1, %z2
  %m = call i32 @cq_measure_si32(i32 %sel)
  %s = add nsw i32 %s0, %m
  ret i32 %s
}

; CHECK:      %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double 5.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H2]], double 9.000000e-01)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[H2]], i32 %[[G]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[T]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: %[[FV:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[G]], i32 %[[FV]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[H1]], i32 %[[H2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])

; NOX-NOT: cqrt_cswap
; NOX-NOT: cqrt_rz
; NOX-NOT: cq_phi
; NOX-NOT: cq_template_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT: call void @cqrt_x(
; TOFCNT-COUNT-2: call void @cqrt_toffoli(
; TOFCNT-NOT: call void @cqrt_toffoli(
; NOPHI-NOT: = phi
