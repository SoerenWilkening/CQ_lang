; spec_accept_fp_select_body.ll — Phase 6 / issue kmdc: the canonical fabs-shape
; FP two-arm select INSIDE a specialization-lifted callee. `int mhelper(int n){
; double x=(double)n; double a=(x<0.0)?-x:x; return a>1.0; }` — an int→int helper
; whose fp is purely internal scratch. clang -O1 gives
; `select(icmp slt n,0, fneg x, x)` feeding a consumer that reduces the fp back to
; an i32. (p119: the terminal consumer is a stock `fcmp ogt`+`zext` — the original
; `ilogb` cross-width libm producer was removed as a library function; fcmp/zext
; exercise the same fp-select lifting + Bennett palindrome and keep the i32 return.)
;
; Lifted into `@__cq_q_mhelper_1` as the full 4.4 controlled-XOR stream over an fp
; `cqrt_copy_f64_controlled` + an fp |0> rail: copy the TRUE arm on the flag, then
; the ¬flag `cqrt_x`-bracketed copy of the FALSE arm. SAFE with NO angle fence — a
; clone body is provably rotation-free (scanBody rejects cq_theta/cq_phi), so the
; fp value never reaches a rotation angle; the RetW=="i32" gate keeps fp
; clone-internal (see the kmdc PRD). The flag is kept LIVE for the Bennett reverse.
;
; THE LOAD-BEARING PIN (the kmdc CONFIRMED hazard): the ¬flag `cqrt_x` bracket
; MUST appear in the Bennett REVERSE too (the mirror). Historically (pre-p3kd.7.8)
; `isForwardTemplate` matched only `cq_template_` names, so without the dedicated
; `SelectXBrackets` capture the reverse would DROP the brackets → replay `[copy_F, copy_T]` at the wrong
; polarity → `out = arm_T ^ arm_F ≠ 0` → a dirty free / hidden measurement (Rule 6),
; verify-clean. The CNT check pins EXACTLY two `cqrt_x` (1 forward + 1 reverse).
;
; bd p3kd.7.8: `lowerCloneSelect` and its `SelectXBrackets` capture are gone; main's
; stage list lowers the clone (SelectMergeEmit), and the Bennett wrap builds the
; reverse as the EXACT mirror of the whole forward. The forward's closing `cqrt_x`
; strip is elided (it writes only the flag after the flag's last forward read), so
; the forward leaves the flag at ¬c and the mirror's single `cqrt_x` restores it
; between the two reverse copies: one bracket each way, not two. Hand trace, |n>:
; x=(double)n, nx=−x, flag=c=[n<0]; copy_c(c,nx) then copy_c(¬c,x) gives out=|x|;
; fcmp/zext, copy-out; the mirror undoes zext, fcmp, copy_c(¬c,x), `cqrt_x` (flag
; back to c), copy_c(c,nx) (out back to 0), then the icmp/fneg/sitofp `_unc`s, so
; all six freed rails are |0>. Dropping the reverse bracket would replay both
; copies at polarity ¬c and leave out = x ⊕ nx ≠ 0 at its free: the CHECK-NEXT body
; and the CNT count both catch it. The old trailing `CHECK-NOT: = select` / `under
; quantum lift` scanned only the text after the clone's `ret` (and the diagnostic
; goes to stderr, which is not captured; a decline already fails the first RUN by
; its non-zero exit), so they pinned nothing; the CHECK-NEXT body now excludes a
; leftover select from the clone.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @mhelper(i32 %n) {
entry:
  %x  = sitofp i32 %n to double
  %c  = icmp slt i32 %n, 0
  %nx = fneg double %x
  %a  = select i1 %c, double %nx, double %x   ; fabs — two derived fp arms
  %cmp = fcmp ogt double %a, 1.000000e+00
  %r  = zext i1 %cmp to i32
  ret i32 %r
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; Caller retargets to the mangled clone.
; CHECK-LABEL: define i32 @example(
; CHECK:       %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_mhelper_1(i32 %[[H:[a-zA-Z0-9_.]+]])
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[R]])

; Clone body — the fp rail + FORWARD two-arm stream (copy_T, ¬flag bracket, copy_F;
; the closing bracket is elided), then the copy-out.
; CHECK-LABEL: define internal i32 @__cq_q_mhelper_1(i32 %n)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %n)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fneg_f64(i32 %[[X]])
; CHECK-NEXT:  %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %n, i32 0)
; CHECK-NEXT:  %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %[[T]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[FLAG]])
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %[[X]], i32 %[[SEL]])
; CHECK-NEXT:  %[[CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[SEL]], double 1.000000e+00)
; CHECK-NEXT:  %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP]])
; CHECK-NEXT:  %[[CO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[Z]], i32 %[[CO]])

; Bennett REVERSE — the MIRROR: zext _unc, fcmp _unc, then copy_F, the bracket,
; copy_T (the bracket is NOT dropped), then the compare/fneg/sitofp _unc, the frees.
; CHECK-NEXT:  call void @cq_template_zext_i1_to_i32_unc(i32 %[[Z]], i32 %[[CMP]])
; CHECK-NEXT:  call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[CMP]], i32 %[[SEL]], double 1.000000e+00)
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %[[X]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[FLAG]])
; CHECK-NEXT:  call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %[[T]], i32 %[[SEL]])
; CHECK-NEXT:  call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[FLAG]], i32 %n, i32 0)
; CHECK-NEXT:  call void @cq_template_fneg_f64_unc(i32 %[[T]], i32 %[[X]])
; CHECK-NEXT:  call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[X]], i32 %n)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[FLAG]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[CMP]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[Z]])
; CHECK-NEXT:  ret i32 %[[CO]]
; CHECK-NEXT:  }

; EXACTLY two cqrt_x — 1 forward bracket + 1 reverse bracket. A dropped-bracket
; regression would leave only 1 (the reverse one missing).
; CNT-COUNT-2: call void @cqrt_x(
; CNT-NOT:     call void @cqrt_x(
