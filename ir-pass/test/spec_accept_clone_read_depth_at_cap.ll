; spec_accept_clone_read_depth_at_cap.ll — ACCEPT, DISCHARGED (bd rhk5 round 2; r1A
; F-r1A-5). The d4 caller with its clone call nesting FIFTEEN `noinline` helpers
; (h -> g1 -> … -> g15): proving the outer call read-only walks 16 (function, formal)
; pairs, exactly the nesting cap `kMaxCloneNesting` admits. Pinned beside
; spec_leak_clone_read_depth_cap.ll (sixteen helpers, 17 pairs, refused) so the cap
; is fixed at its value from BOTH sides: lowering it turns THIS file red, raising or
; deleting it turns the other red.
;
; ⚠ The cap is a CONSERVATIVE bound, not a physics fence: every body in the 17-pair
; chain is read-only too, and the refusal there is an over-leak. It exists because
; the proof recurses on the native stack. RETIREMENT TRIGGER (L8): if the walk is
; made iterative, retire the cap and turn the other file into an accept.
;
; ⚠ (Rule-13 r2B F-r2B-3) This file is RED on the oracle — it distinguishes rhk5 — but
; the claim that it fixes the cap's VALUE rests on the out-of-tree mutant matrix
; (`rhk5_probes/tools/mutants_r2.py` R5, cap 16 → 15), which is not a ctest gate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @slice(i32 %m) {
entry:
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %u = xor i32 %p, %q
  %s = call i32 @h(i32 %m, i32 %q)
  %c = icmp eq i32 %u, 10
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double 3.141590e+00)
  br label %merge

merge:
  %ms = call i32 @cq_measure_si32(i32 %s)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %r = add nsw i32 %mq, %ms
  ret i32 %r
}

define i32 @h(i32 %a, i32 %k) {
  %t = call i32 @g1(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g1(i32 %k) noinline {
  %t = call i32 @g2(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g2(i32 %k) noinline {
  %t = call i32 @g3(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g3(i32 %k) noinline {
  %t = call i32 @g4(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g4(i32 %k) noinline {
  %t = call i32 @g5(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g5(i32 %k) noinline {
  %t = call i32 @g6(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g6(i32 %k) noinline {
  %t = call i32 @g7(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g7(i32 %k) noinline {
  %t = call i32 @g8(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g8(i32 %k) noinline {
  %t = call i32 @g9(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g9(i32 %k) noinline {
  %t = call i32 @g10(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g10(i32 %k) noinline {
  %t = call i32 @g11(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g11(i32 %k) noinline {
  %t = call i32 @g12(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g12(i32 %k) noinline {
  %t = call i32 @g13(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g13(i32 %k) noinline {
  %t = call i32 @g14(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g14(i32 %k) noinline {
  %t = call i32 @g15(i32 %k)
  %r = add nsw i32 %t, 1
  ret i32 %r
}

define i32 @g15(i32 %k) noinline {
  %r = mul nsw i32 %k, 5
  ret i32 %r
}

; SILENT-NOT: warning
; SILENT-NOT: error
; LOWER-LABEL: define i32 @slice(
; LOWER: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LOWER: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cq_template_xor_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op1)
; LOWER-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op)
; LOWER: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
