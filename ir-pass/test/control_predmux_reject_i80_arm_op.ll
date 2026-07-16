; control_predmux_reject_i80_arm_op.ll — bd 3c6m.51 Inc 3 DECLINE (the E4 i80
; clause boundary): PredMux admits EXACTLY the four shipped i80 bitwise rows
; (and/lshr/or/shl — i80BinaryInScope) plus the castInScope i80 grid inside a
; claimable arm; an `add i80` has NO template, so the region is LEFT unclaimed
; (detect-before-mutate — a claim would half-lower) and the tainted diamond
; falls to the control detector's loud decline. The accept twin is
; lowering_fp80_union_multiblock.ll, whose arms carry only supported i80 ops.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)

define i64 @i80arm() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %bc = bitcast x86_fp80 %q to i80
  %w = trunc i80 %bc to i64
  %c = icmp eq i64 %w, 0
  br i1 %c, label %a, label %b

a:
  %s = add i80 %bc, 1                     ; NO i80 add template — E4 leaves the region
  %t = trunc i80 %s to i64
  %k1 = and i64 %t, 32767
  %j1 = or i64 %w, 1
  br label %m

b:
  %k2 = and i64 %w, 255
  %j2 = or i64 %w, 2
  br label %m

m:                                        ; 2 merge phis = a PredMux claim witness
  %k = phi i64 [ %k1, %a ], [ %k2, %b ]
  %j = phi i64 [ %j1, %a ], [ %j2, %b ]
  %r = add i64 %k, %j
  %mm = call i64 @cq_measure_sll(i64 %r)
  ret i64 %mm
}

; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: cq_template_add_i80
