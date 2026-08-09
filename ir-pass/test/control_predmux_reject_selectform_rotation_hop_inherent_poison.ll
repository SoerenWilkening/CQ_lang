; control_predmux_reject_selectform_rotation_hop_inherent_poison.ll — REJECT
; (bd u1rp). THE HOP MUST NOT LAUNDER AN OP THAT HAS NO FLAG TO DROP.
;
; A variable-amount `shl` is INHERENT poison when the amount reaches the bit
; width — there is no annotation to remove, which is exactly why
; `definedOpAfterFlagDrop` refuses it outright. Placed DIRECTLY in a shielded
; cone it has always declined. Placed ONE `cq_phi` HOP above the compare it was
; ACCEPTED, on the pre-fix plugin and on the shipped one before this change,
; because `cq_phi` was classified as a defined leaf and the walk stopped there.
;
; THE HOP THEREFORE TURNED A CORRECT DECLINE INTO AN UNSOUND ACCEPT, and no
; amount of flag-stripping could have mitigated it — that is the point. The
; measured pair, on the pre-fix plugin:
;
;     shl directly in the cone        -> DECLINE      (correct)
;     shl one cq_phi hop above it     -> FLATTEN      (unsound)
;
; `cq_phi`'s result IS operand 0 (`RotationLowering` RAUWs it verbatim), so the
; cone must continue through it; `classifyConeNode` now returns
; `ConeNode::PassThrough` and both walkers follow operand 0.
;
; THE DIRECT HALF OF THE PAIR IS NOT IN THIS FILE, and that is a limitation of
; the harness rather than a choice: `opt` emits the FIRST `DS_Error` and exits,
; so a two-function decline fixture can only ever assert one message. The direct
; placement was measured separately and declines on all three plugins
; (pre-change, the first draft, and this one) — the shape is
;
;     %bad = shl i32 %c, %d
;     %b   = icmp slt i32 %q, %bad        ; no rotation hop
;
; and it is the E6 grammar that refuses it. The nearest committed sibling is
; control_predmux_reject_selectform_shift_wide_amount.ll, which pins the
; CONSTANT out-of-range amount rather than the variable one.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:  | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; The laundered form: inherent poison, one cq_phi hop above the compare.
define i32 @probe_hop(i32 %u, i32 %c, i32 %d) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %bad = shl i32 %c, %d
  %r1 = call i32 @cq_phi_si32(i32 %bad, double 2.500000e-01)
  %b = icmp slt i32 %q, %r1
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; CHECK: error: {{.*}}in function probe_hop i32 (i32, i32, i32): cq controlled lowering: control flow under quantum control
