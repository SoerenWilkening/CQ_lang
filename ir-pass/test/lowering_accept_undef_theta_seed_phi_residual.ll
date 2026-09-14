; lowering_accept_undef_theta_seed_phi_residual.ll — ACCEPT, and it is the
; RESIDUAL of bd z9t1 clause 5 written down as a fixture rather than as a
; sentence.
;
; THE RULE IS NOT TOTAL AND THE OWNER RULED IT THAT WAY. The normalizer asks
; `valueCarriesUndef` (LiteralIntegrity.h), which is CONSTANT-ONLY: an `undef`
; that reaches the seed through a `phi` — or through any other instruction — is
; not a literal at arg-0, so nothing fires and the emitted module is EXACTLY what
; the 2026-09-13 oracle emitted for it. Measured on the oracle
; (f7b65d8ccd7bc472, 2026-09-14) before the rule was written, and again after:
;
;     %h = call i32 @cqrt_alloc_i1(i1 %s)        ; %s = phi i1 [ undef, %a ], …
;
; This is NOT a new hole. It is the pre-existing one, held still: the alloc slot
; carries an SSA value rather than a literal, so `declineUnpairedUndefLiterals`
; (which counts LITERAL slots) does not see it either, exactly as before. bd
; `bwsh` holds the residual; this file is what makes a future change to it
; VISIBLE instead of silent — widen the normalizer to chase instruction
; operands and this fixture goes red, which is the conversation that widening
; owes.
;
; ⚠ RETIREMENT TRIGGER: if bd `bwsh` is ever taken and an `undef` reaching the
; seed through a `phi` is normalized too, this file becomes
; `call i32 @cqrt_alloc_i1(i1 false)` — re-derive it then, do NOT delete it: the
; ACCEPT/ACCEPT pair (this file and `..._undef_theta_seed_zero.ll`) is what
; distinguishes "the rule got wider" from "the rule stopped firing".
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     %[[S:[a-zA-Z0-9_.]+]] = phi i1 [ undef, %a ], [ %x, %b ]
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %[[S]])
; CHECK:     call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK:     call i1 @cqrt_measure_i1(i32 %[[H]])

;
; *** THE WHOLE EMITTED STREAM, PINNED IN ORDER, WITH NOTHING ELSE ALLOWED. ***
; The two `--implicit-check-not` patterns carry a negative over the ENTIRE file
; between every pair of STREAM lines, so ANY extra emitted gate — an injected
; `cqrt_x` on a user register, a second `cqrt_ry`, a `cqrt_cswap`, a `cqrt_free`,
; a measurement the user did not write (Rule 5) — reddens this prefix wherever it
; is placed. MEASURED with `$SES/trackU/probes/impl/inject_u.py`, not asserted:
; strip this prefix and 11 of 17 mutations over two of these fixtures go MISSED
; (injected `cqrt_x`, extra `cqrt_free`, extra `cqrt_ry`, `cqrt_cswap`, swapped
; copy pair, extra measurement); with it, 0 MISSED of 67 over all nine. The
; patterns match CALL SITES only (`call {{.*}}@cqrt_`), so the module's trailing
; `declare` lines are untouched.
; RUN: %filecheck %s --check-prefix=STREAM \
; RUN:   --implicit-check-not='call {{.*}}@cqrt_' \
; RUN:   --implicit-check-not='call {{.*}}@cq_template_' < %t.cqd0.ll
; STREAM:      %h = call i32 @cqrt_alloc_i1(i1 %s)
; STREAM:      call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; STREAM:      %m1 = call i1 @cqrt_measure_i1(i32 %h)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %c, i1 %x) {
entry:
  br i1 %c, label %a, label %b
a:
  br label %j
b:
  br label %j
j:
  %s = phi i1 [ undef, %a ], [ %x, %b ]
  %q = call i1 @cq_theta_i1(i1 %s, double 5.000000e-01)
  %m = call i1 @cq_measure_i1(i1 %q)
  ret i1 %m
}
