; control_classical_call_arm_accept_onward_ctl_select.ll — ACCEPT (yn71, Phase 4×6,
; the CONTROL case): a 6.5 classical-call arm whose UNTAINTED merge `%out` feeds a NEW
; TAINTED-condition `select` — `int y = 5; if (q>3) y = f(a); int z = (y>7) ? y : 99;
; measure z`. `(y>7)?y:99` is the natural clang -O1 form of a downstream data mux (an
; opaque-call-free ternary is speculatable → a `select`, not a diamond).
;
; The select condition `icmp sgt %out, 7` is a `%out` derivation — tainted only after
; `repropagateControlMerges` re-seeds. dugh declined the tainted-condition select
; (`control flow under quantum control`, via `declineClassicalMuxes` deferring to
; ControlDetect); yn71 RE-DETECTS it (`detectAndLowerOnwardControl` runs the step-183
; select scan) and `SelectMergeEmit` lowers it as the 4.4 controlled-XOR copy merge
; into a fresh `%out2` rail: mint the flag from `icmp(%out, 7)`, alloc %out2=|0>, copy
; the TRUE source (`%out`) on the flag, the FALSE source (99) on ¬flag (cqrt_x-
; bracketed — ONLY the second copy), strip + free the flag; the measure reads %out2.
; No CFG surgery (a select has no diamond), so no re-flatten.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @f(i32) #0
define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]           ; UNTAINTED ccarm merge -> %out
  %c2 = icmp sgt i32 %y, 7                             ; tainted only AFTER the re-seed
  %z = select i1 %c2, i32 %y, i32 99                  ; NEW tainted-condition select
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; The ccarm builds %out; then the onward controlled-XOR merge builds a fresh %out2,
; copying %out on the flag and 99 on ¬flag, the flag minted from icmp(%out, 7):
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[OUT]], i32 7)
; CHECK:     %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[OUT]], i32 %[[OUT2]])
; CHECK:     call void @cqrt_x(i32 %[[F2]])
; CHECK:     %[[NN:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 99)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[NN]], i32 %[[OUT2]])
; CHECK:     call void @cqrt_x(i32 %[[F2]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[OUT]], i32 7)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT2]])

; No surviving select, and the region ACCEPTS:
; CHECK-NOT: select
; ACC-NOT: under quantum control
