; Stage 4 IR with branched control flow — exercises PostDominatorTree on
; non-trivial CFG. A single quantum init in entry; both arms of an if measure
; the value; merge block joins. cqrt_free should land in the merge block
; (post-dominator of both arms), not duplicated into either arm.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%qint_mid_t = type { i32 }

declare %qint_mid_t @cq_init_i32(i32)
declare i64         @cq_measure(%qint_mid_t)

define i64 @example_branch(i1 %cond) {
entry:
  %a_struct = call %qint_mid_t @cq_init_i32(i32 3)
  br i1 %cond, label %then, label %else

then:
  %a_val_t = extractvalue %qint_mid_t %a_struct, 0
  %wrap_t  = insertvalue %qint_mid_t poison, i32 %a_val_t, 0
  %m1      = call i64 @cq_measure(%qint_mid_t %wrap_t)
  br label %merge

else:
  %a_val_e = extractvalue %qint_mid_t %a_struct, 0
  %wrap_e  = insertvalue %qint_mid_t poison, i32 %a_val_e, 0
  %m2      = call i64 @cq_measure(%qint_mid_t %wrap_e)
  br label %merge

merge:
  %m = phi i64 [ %m1, %then ], [ %m2, %else ]
  ret i64 %m
}
