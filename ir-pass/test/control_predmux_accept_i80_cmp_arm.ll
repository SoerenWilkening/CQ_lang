; control_predmux_accept_i80_cmp_arm.ll — ACCEPT (bd 3c6m.61): an arm-resident
; x86_fp80 BIT-PATTERN compare, the exact shape real openlibm `hypotl` puts in
; its Inf/NaN arm:
;
;     GET_LDBL_MAN(manh, manl, a);
;     if (manh == LDBL_NBIT && manl == 0) w = a;
;
; which `clang -O1` + promoteFp80Union fuse into
;   `icmp eq i80 (and i80 %bits, 0xFFFF'FFFF'FFFF'FFFF), 0x8000'0000'0000'0000`
; INSIDE the arm, feeding an f80 select. Before 3c6m.61 the E4 clause blanket-
; excluded every i80 compare on the claim that "the canonical promotion never
; puts those inside an arm" — hypotl falsified it and the whole cell declined at
; the ship floor while the census pipeline scored it COMPILES (the scoreboard-
; honesty defect this fixture closes).
;
; The compare is claimed because it is provably `_hl`: exactly ONE operand is a
; ConstantInt, so `lowerCompareImpl` can only ever take its HL path, whose
; `cq_template_icmp_eq_i80_hl` (+ `_unc` twin) ship in the frozen §6.0 grid. No
; new symbol, no new gate sequence. The Q+Q twin is fenced — see the decline
; sibling control_predmux_reject_i80_cmp_qq.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi x86_fp80' < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @probe(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %c = fcmp olt x86_fp80 %q, 0xK3FFE8000000000000000
  br i1 %c, label %nan, label %norm

nan:                                    ; the Inf/NaN arm
  %bc = bitcast x86_fp80 %q to i80
  %man = and i80 %bc, 18446744073709551615        ; GET_LDBL_MAN: low 64 bits
  %isnbit = icmp eq i80 %man, 9223372036854775808 ; manh == LDBL_NBIT && manl == 0
  %w = select i1 %isnbit, x86_fp80 %q, x86_fp80 0xK3FFF8000000000000000
  %k1 = fadd x86_fp80 %w, 0xKBFFE8000000000000000
  br label %merge

norm:
  %k2 = fmul x86_fp80 %q, 0xK40008000000000000000
  br label %merge

merge:                                  ; 2 merge phis = the W3 PredMux claim witness
  %z = phi x86_fp80 [ %k1, %nan ], [ %k2, %norm ]
  %z2 = phi x86_fp80 [ %w, %nan ], [ %q, %norm ]
  %s = fadd x86_fp80 %z, %z2
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %s)
  ret x86_fp80 %m
}

; A Rule-13 lens showed the first draft of these CHECKs was mutation-BLIND: it
; pinned the predicate, the constant, the flag and the target rail, but left the
; compare's DATA operand and both copy SOURCES as wildcards — so an inverted
; select and a dropped mantissa mask both passed unchanged. Everything
; load-bearing is now captured and named.

; The tainted rail, and the fp80 bit-pattern extract chain off it.
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 %u0)
; CHECK:     %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_bitcast_f80_to_i80(i32 %[[Q]])
; CHECK:     %[[MAN:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i80_hl(i32 %[[CAST]], i80 18446744073709551615)

; The compare MUST read the MASKED mantissa %[[MAN]], never the raw %[[CAST]] —
; dropping the `and` silently turns hypotl's `manh==LDBL_NBIT && manl==0` NaN
; test into a whole-bit-pattern equality.
; CHECK:     %[[F80:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i80_hl(i32 %[[MAN]], i80 9223372036854775808)

; The 4.4/kjd1 merge, with BOTH copy sources named and IN ORDER: flag=1 copies
; the true arm (%q, the rail), ¬flag copies the false arm (the 1.0 literal rail).
; Swapping them is an arm inversion — a verify-clean silent miscompile.
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK:     call void @cqrt_copy_f80_controlled(i32 %[[F80]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F80]])
; CHECK:     %[[SELOP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK3FFF8000000000000000)
; CHECK:     call void @cqrt_copy_f80_controlled(i32 %[[F80]], i32 %[[SELOP]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F80]])

; Rule 6 — the flag rail is stripped by the VOID out-first `_unc`, which must
; recompute from the SAME %[[MAN]] and the SAME constant (a strip against
; different operands computes a different function and leaves the rail dirty),
; and it NAMES the rail the next line frees (bd 8txa), so the golden witnesses
; the pairing.
; CHECK:     call void @cq_template_icmp_eq_i80_hl_unc(i32 %[[F80]], i32 %[[MAN]], i80 9223372036854775808)
; CHECK:     call void @cqrt_free(i32 %[[F80]])

; CHECK:     call x86_fp80 @cqrt_measure_f80(
