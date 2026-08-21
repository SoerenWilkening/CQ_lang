; Could a derivation recover the f80 bound by IMPORTING the source's guard?
; Same mask loop, with the guard `man != 0` expressed as llvm.assume.
declare void @llvm.assume(i1)

define i32 @mask_no_assume(i64 %man) {
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

define i32 @mask_with_assume(i64 %man) {
entry:
  %nz = icmp ne i64 %man, 0
  call void @llvm.assume(i1 %nz)
  %lo = icmp ult i64 %man, 2147483648
  call void @llvm.assume(i1 %lo)
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

; and the same loop with the MASK's exhaustion made explicit (m reaches 0)
define i32 @mask_with_m_bound(i64 %man) {
entry:
  br label %loop
loop:
  %b = phi i32 [ 0, %entry ], [ %bn, %loop ]
  %m = phi i64 [ 2147483648, %entry ], [ %mn, %loop ]
  %bn = add nuw nsw i32 %b, 1
  %mn = lshr exact i64 %m, 1
  %a  = and i64 %mn, %man
  %c  = icmp eq i64 %a, 0
  %still = icmp ne i64 %mn, 0
  %go = and i1 %c, %still
  br i1 %go, label %loop, label %exit
exit:
  ret i32 %bn
}
