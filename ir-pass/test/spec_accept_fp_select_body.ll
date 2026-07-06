; spec_accept_fp_select_body.ll — Phase 6 / issue kmdc: the canonical fabs-shape
; FP two-arm select INSIDE a specialization-lifted callee. `int mhelper(int n){
; double x=(double)n; double a=(x<0.0)?-x:x; return ilogb(a); }` — an int→int
; helper whose fp is purely internal scratch. clang -O1 gives
; `select(icmp slt n,0, fneg x, x)` feeding the libm producer `ilogb`.
;
; Lifted into `@__cq_q_mhelper_1` as the full 4.4 controlled-XOR stream over an fp
; `cqrt_copy_f64_controlled` + an fp |0> rail: copy the TRUE arm on the flag, then
; the ¬flag `cqrt_x`-bracketed copy of the FALSE arm. SAFE with NO angle fence — a
; clone body is provably rotation-free (scanBody rejects cq_theta/cq_phi), so the
; fp value never reaches a rotation angle; the RetW=="i32" gate keeps fp
; clone-internal (see the kmdc PRD). The flag is kept LIVE for the Bennett reverse.
;
; THE LOAD-BEARING PIN (the kmdc CONFIRMED hazard): the two ¬flag `cqrt_x` brackets
; MUST appear in the Bennett REVERSE too (a palindrome). `isForwardTemplate`
; matches only `cq_template_` names, so without the dedicated `SelectXBrackets`
; capture the reverse would DROP them → replay `[copy_F, copy_T]` at the wrong
; polarity → `out = arm_T ^ arm_F ≠ 0` → a dirty free / hidden measurement (Rule 6),
; verify-clean. The CNT check pins EXACTLY four `cqrt_x` (2 forward + 2 reverse).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @ilogb(double)

define i32 @mhelper(i32 %n) {
entry:
  %x  = sitofp i32 %n to double
  %c  = icmp slt i32 %n, 0
  %nx = fneg double %x
  %a  = select i1 %c, double %nx, double %x   ; fabs — two derived fp arms
  %r  = call i32 @ilogb(double %a)
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
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_mhelper_1(i32 %[[H:[a-zA-Z0-9_.]+]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])

; Clone body — the fp rail + FORWARD two-arm stream (copy_T, ¬flag bracket, copy_F, bracket).
; CHECK:     define internal i32 @__cq_q_mhelper_1(i32 %n)
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %n, i32 0)
; CHECK:     %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %[[T:[a-zA-Z0-9_.]+]], i32 %[[SEL]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %[[F:[a-zA-Z0-9_.]+]], i32 %[[SEL]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call i32 @cq_template_ilogb_f64_to_i32(i32 %[[SEL]])

; Bennett REVERSE — the PALINDROME: ilogb _unc, then bracket, copy_F, bracket,
; copy_T (the brackets are NOT dropped), then the compare/fneg/sitofp _unc chain.
; CHECK:     call void @cq_template_ilogb_f64_to_i32_unc(
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %[[F]], i32 %[[SEL]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %[[T]], i32 %[[SEL]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[FLAG]], i32 %n, i32 0)
; CHECK:     call void @cq_template_fneg_f64_unc(
; CHECK:     call void @cq_template_sitofp_i32_to_f64_unc(
; CHECK:     call void @cqrt_free(i32 %[[SEL]])
; CHECK:     ret i32

; No leftover raw select, no decline.
; CHECK-NOT: = select
; CHECK-NOT: under quantum lift

; EXACTLY four cqrt_x — 2 forward brackets + 2 reverse brackets. A dropped-bracket
; regression would leave only 2 (the reverse pair missing).
; CNT-COUNT-4: call void @cqrt_x(
; CNT-NOT:     call void @cqrt_x(
