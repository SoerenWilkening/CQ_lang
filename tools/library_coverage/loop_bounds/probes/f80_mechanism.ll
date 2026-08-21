; Is "the compare LHS is not the shift recurrence" SUFFICIENT to explain the f80
; CouldNotCompute? Same and-then-eq-0 mask shape, two AND operands: opaque vs constant.
define i32 @mask_opaque(i64 %man) {
entry:
  br label %loop
loop:
  %b = phi i32 [ 0, %entry ], [ %bn, %loop ]
  %m = phi i64 [ 2147483648, %entry ], [ %mn, %loop ]
  %bn = add nuw nsw i32 %b, 1
  %mn = lshr i64 %m, 1
  %a  = and i64 %mn, %man
  %c  = icmp eq i64 %a, 0
  br i1 %c, label %loop, label %exit
exit:
  ret i32 %bn
}

define i32 @mask_const(i64 %ignored) {
entry:
  br label %loop
loop:
  %b = phi i32 [ 0, %entry ], [ %bn, %loop ]
  %m = phi i64 [ 2147483648, %entry ], [ %mn, %loop ]
  %bn = add nuw nsw i32 %b, 1
  %mn = lshr i64 %m, 1
  %a  = and i64 %mn, 255
  %c  = icmp eq i64 %a, 0
  br i1 %c, label %loop, label %exit
exit:
  ret i32 %bn
}
