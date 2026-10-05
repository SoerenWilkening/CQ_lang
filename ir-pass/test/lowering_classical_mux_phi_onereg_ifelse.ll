; lowering_classical_mux_phi_onereg_ifelse.ll — ACCEPT: one-register merge
; phi over an if/else, no straight-through edge (test_C_libtooling-5j5).
; `clang -O1` output (attribute groups and metadata trimmed) for
;
;     int main(int argc, char **argv) {
;       int q = 7; cq_theta(&q, 0.5);
;       if (argc > 1) cq_theta(&q, 0.25); else cq_theta(&q, 0.125);
;       return cq_measure(q);
;     }
;
; Each arm holds one in-place Ry on the one register, so the merge is
; `phi [%6, %5], [%8, %7]` with BOTH incomings distinct SSA names of %3's
; register. (`nomerge` keeps clang from sinking the two calls into one call on a
; selected angle.) The lift predicate is per-edge: each incoming resolves
; through its own arm's gate to the SAME base %3, and the renaming phi is erased.
;
; This is NOT ControlDetect's if/else: the condition is CLASSICAL (detection
; keys strictly on condition taint), so no flag, no rails, no routing. The
; branch structure is left byte-untouched, each arm keeps its own Ry, and only
; the renaming phi is erased.
;
; History: written for the pre-3qlq register form
; `if (c) q = cq_phi(q, a); else q = cq_phi(q, b);`. The 3qlq migration deleted
; both uncontrolled phases and left both arms empty; bd jttf (2026-10-05)
; re-spelled them as the in-place Ry gates above.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[C:[0-9]+]] = icmp sgt i32 %0, 1
; CHECK-NEXT: br i1 %[[C]], label %[[A:[0-9]+]], label %[[B:[0-9]+]]
; The true arm rotates by 0.25, the false arm by 0.125, both on the ONE handle:
; CHECK:      {{^}}[[A]]:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT: br label %[[MERGE:[0-9]+]]
; CHECK:      {{^}}[[B]]:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK-NEXT: br label %[[MERGE]]
; CHECK:      {{^}}[[MERGE]]:
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
;
; Whole-module negatives: no phi survives, zero controlled gates and no routing
; (the condition is classical), no free (main-resident handle):
; NEG-NOT: phi i32
; NEG-NOT: cqrt_cswap
; NEG-NOT: _controlled
; NEG-NOT: cqrt_free
; NEG-NOT: cq_theta_si32
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2)); jttf: re-spelled register-free 2026-10-05

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01) #2
  %4 = icmp sgt i32 %0, 1
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.500000e-01) #2
  br label %9

7:                                                ; preds = %2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.250000e-01) #2
  br label %9

9:                                                ; preds = %7, %5
  %10 = phi i32 [ %6, %5 ], [ %8, %7 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  ret i32 %11
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
