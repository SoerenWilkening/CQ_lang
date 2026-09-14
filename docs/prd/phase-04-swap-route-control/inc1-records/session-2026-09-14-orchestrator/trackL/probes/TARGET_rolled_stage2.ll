; TARGET stage-2 (post-cq-lowering) shape for the owner's ROLLED bank cascade.
; Hand-written to the design; linked and run to prove the stream is well-formed.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main() local_unnamed_addr {
entry:
  ; [3 x i8] rewritten to [3 x i32]: the cells hold classical HANDLES.
  %bank = alloca [3 x i32], align 4, !cq.railbank !0
  ; `a` is quantum from the header phi onward, so it is minted before the loop.
  %a0 = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %i   = phi i64 [ 0,   %entry ], [ %i.next, %loop ]
  %h_a = phi i32 [ %a0, %entry ], [ %out,    %loop ]

  ; ---- prep region:  if (a >= 3) b[i] = cq_theta(b[i], 0.5) --------------
  %f   = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h_a, i32 2)
  %h_b = call i32 @cqrt_alloc_i1(i1 false)            ; FRESH rail, this trip
  call void @cqrt_ry_i1_controlled(i32 %f, i32 %h_b, double 5.000000e-01)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %f, i32 %h_a, i32 2)
  call void @cqrt_free(i32 %f)

  ; ---- value arm:  if (b[i]) a -= 3 --------------------------------------
  %h_sub = call i32 @cq_template_add_i32_hl(i32 %h_a, i32 -3)
  %bf    = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_cnot(i32 %h_b, i32 %bf)             ; rail root -> CNOT copy
  %out   = call i32 @cqrt_alloc_i32(i32 0)            ; fresh |0> merge rail
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_sub, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_a, i32 %out)
  call void @cqrt_x(i32 %bf)
  call void @cqrt_cnot(i32 %h_b, i32 %bf)             ; bf back to |0>
  call void @cqrt_free(i32 %bf)                       ; proven-|0> free

  ; ---- the bank store: a CLASSICAL i32 into classical memory -------------
  %cell = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %i
  store i32 %h_b, ptr %cell, align 4

  %i.next = add nuw nsw i64 %i, 1
  %done   = icmp eq i64 %i.next, 3
  br i1 %done, label %measure, label %loop

measure:                                          ; preds = %loop
  %a.final = phi i32 [ %out, %loop ]
  %c0  = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 0
  %hb0 = load i32, ptr %c0, align 4                   ; D5: bank load -> measure
  %m0  = call i1 @cqrt_measure_i1(i32 %hb0)
  %z0  = zext i1 %m0 to i32
  %c1  = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 1
  %hb1 = load i32, ptr %c1, align 4
  %m1  = call i1 @cqrt_measure_i1(i32 %hb1)
  %z1  = zext i1 %m1 to i32
  %s1  = add nuw nsw i32 %z0, %z1
  %c2  = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 2
  %hb2 = load i32, ptr %c2, align 4
  %m2  = call i1 @cqrt_measure_i1(i32 %hb2)
  %z2  = zext i1 %m2 to i32
  %s2  = add nuw nsw i32 %s1, %z2
  %ma  = call i32 @cqrt_measure_i32(i32 %a.final)
  %s3  = add nsw i32 %s2, %ma
  ret i32 %s3
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_copy_i32_controlled(i32, i32, i32)
declare void @cqrt_cnot(i32, i32)
declare void @cqrt_x(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cqrt_measure_i32(i32)

!0 = !{!"i1"}
