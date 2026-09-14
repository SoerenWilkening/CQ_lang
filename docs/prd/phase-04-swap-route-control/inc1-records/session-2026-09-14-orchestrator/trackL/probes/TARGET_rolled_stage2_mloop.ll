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
  %ma  = call i32 @cqrt_measure_i32(i32 %a.final)
  br label %mloop

mloop:                                            ; preds = %measure, %mloop
  %j   = phi i64 [ 0,   %measure ], [ %j.next, %mloop ]
  %acc = phi i32 [ %ma, %measure ], [ %acc.next, %mloop ]
  %mc  = getelementptr inbounds [3 x i32], ptr %bank, i64 0, i64 %j
  %hb  = load i32, ptr %mc, align 4              ; D5: bank load at a LOOP-VARIANT index
  %mb  = call i1 @cqrt_measure_i1(i32 %hb)
  %zb  = zext i1 %mb to i32
  %acc.next = add nsw i32 %acc, %zb
  %j.next   = add nuw nsw i64 %j, 1
  %jdone    = icmp eq i64 %j.next, 3
  br i1 %jdone, label %mdone, label %mloop

mdone:                                            ; preds = %mloop
  %res = phi i32 [ %acc.next, %mloop ]
  ret i32 %res
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
