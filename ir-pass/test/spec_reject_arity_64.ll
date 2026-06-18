; spec_reject_arity_64.ll — Phase 6.2 WI-2.3: a candidate callee whose arity
; EXCEEDS the 64-parameter specialization-mask cap is LOUDLY declined (DD-5). A
; 65th parameter would not fit the `uint64_t` `SpecMask`; masking it to 64 bits
; would silently truncate and ALIAS two distinct taint signatures of the callee
; onto one clone — the over-accept class (Rule 1). The classifier rejects FIRST
; (before any body inspection) with the pinned message, the site never enters
; `plan6`, and `opt` exits non-zero. The callee below has 65 i32 params with a
; tainted arg0, so it is a real candidate that hits exactly the arity guard.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @wide(i32 %p0, i32 %p1, i32 %p2, i32 %p3, i32 %p4, i32 %p5, i32 %p6, i32 %p7, i32 %p8, i32 %p9, i32 %p10, i32 %p11, i32 %p12, i32 %p13, i32 %p14, i32 %p15, i32 %p16, i32 %p17, i32 %p18, i32 %p19, i32 %p20, i32 %p21, i32 %p22, i32 %p23, i32 %p24, i32 %p25, i32 %p26, i32 %p27, i32 %p28, i32 %p29, i32 %p30, i32 %p31, i32 %p32, i32 %p33, i32 %p34, i32 %p35, i32 %p36, i32 %p37, i32 %p38, i32 %p39, i32 %p40, i32 %p41, i32 %p42, i32 %p43, i32 %p44, i32 %p45, i32 %p46, i32 %p47, i32 %p48, i32 %p49, i32 %p50, i32 %p51, i32 %p52, i32 %p53, i32 %p54, i32 %p55, i32 %p56, i32 %p57, i32 %p58, i32 %p59, i32 %p60, i32 %p61, i32 %p62, i32 %p63, i32 %p64) {
entry:
  %r = add i32 %p0, %p1
  ret i32 %r
}

define void @example(i32 %u0, i32 %c1, i32 %c2, i32 %c3, i32 %c4, i32 %c5, i32 %c6, i32 %c7, i32 %c8, i32 %c9, i32 %c10, i32 %c11, i32 %c12, i32 %c13, i32 %c14, i32 %c15, i32 %c16, i32 %c17, i32 %c18, i32 %c19, i32 %c20, i32 %c21, i32 %c22, i32 %c23, i32 %c24, i32 %c25, i32 %c26, i32 %c27, i32 %c28, i32 %c29, i32 %c30, i32 %c31, i32 %c32, i32 %c33, i32 %c34, i32 %c35, i32 %c36, i32 %c37, i32 %c38, i32 %c39, i32 %c40, i32 %c41, i32 %c42, i32 %c43, i32 %c44, i32 %c45, i32 %c46, i32 %c47, i32 %c48, i32 %c49, i32 %c50, i32 %c51, i32 %c52, i32 %c53, i32 %c54, i32 %c55, i32 %c56, i32 %c57, i32 %c58, i32 %c59, i32 %c60, i32 %c61, i32 %c62, i32 %c63, i32 %c64) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %y = call i32 @wide(i32 %q, i32 %c1, i32 %c2, i32 %c3, i32 %c4, i32 %c5, i32 %c6, i32 %c7, i32 %c8, i32 %c9, i32 %c10, i32 %c11, i32 %c12, i32 %c13, i32 %c14, i32 %c15, i32 %c16, i32 %c17, i32 %c18, i32 %c19, i32 %c20, i32 %c21, i32 %c22, i32 %c23, i32 %c24, i32 %c25, i32 %c26, i32 %c27, i32 %c28, i32 %c29, i32 %c30, i32 %c31, i32 %c32, i32 %c33, i32 %c34, i32 %c35, i32 %c36, i32 %c37, i32 %c38, i32 %c39, i32 %c40, i32 %c41, i32 %c42, i32 %c43, i32 %c44, i32 %c45, i32 %c46, i32 %c47, i32 %c48, i32 %c49, i32 %c50, i32 %c51, i32 %c52, i32 %c53, i32 %c54, i32 %c55, i32 %c56, i32 %c57, i32 %c58, i32 %c59, i32 %c60, i32 %c61, i32 %c62, i32 %c63, i32 %c64)
  %m = call i32 @cq_measure_si32(i32 %y)
  ret void
}

; CHECK: error{{.*}}cq specialization: callee arity exceeds the 64-parameter specialization mask limit
; No clone is synthesized for an over-wide callee.
; CHECK-NOT: @__cq_q_wide
