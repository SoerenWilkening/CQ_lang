; control_swap_reject_cond_datause_unlowerable_cast.ll — DECLINE probe (ziov.4):
; a tainted control compare reused as DATA, where the data cast has an
; UNSUPPORTED width — must decline PRE-mutation (Rule 9 detect-before-mutate).
;
; (Width re-pointed i128 -> i256 in the n0ui follow-up: i128 is now a supported
; Tier-1 INTERMEDIATE width and would LOWER, so this unsupported-width probe uses
; the next genuinely-unsupported int width to keep testing the gate.)
;
; `%c = icmp sgt q, 5` feeds the diamond's `br` (control) AND `%d = sext %c to
; i256` (data). The i256 lineage narrows back (`trunc to i32`) and escapes via
; `ret`, so `condDataUseDisposition` USED to walk it to ShareOk → set
; ShareCondFlag → `emitRegion` routed the diamond + `flattenRegion` erased it,
; and ONLY THEN did `lowerOps`/`rewriteCast` diagnose the unlowerable
; `sext i1→i128` ("no template for opcode 'sext i128'"). LOUD, but a
; mutate-then-decline: detection ACCEPTED a region it could not lower (Rule 9).
;
; ziov.4 mirrors `rewriteCast`'s lowerability gate (the SAME pure
; `abiWidthFromType`+`castInScope` predicates, NO module-mutating template mint)
; inside `condDataUseDisposition`: an unsupported-width / out-of-scope data cast
; on the condition lineage yields `Unlowerable` and declines HERE, in detection,
; before any route/flatten. Over-declining is always safe (Prime Directive).
;
; ADVERSARIAL POSTCONDITION: the diagnostic is the NEW pre-mutation string
; ("condition data use has no template"), NOT the post-flatten "no template for
; opcode 'sext i256'" — proving the region is declined BEFORE it is mutated.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition data use has no template under quantum control
; The OLD (mutate-then-decline) message must NOT appear — detection declines first:
; CHECK-NOT: no template for opcode 'sext i256'
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %d = sext i1 %c to i256            ; DATA use, UNSUPPORTED width (i256)
  %e = trunc i256 %d to i32          ; narrow back so the lineage escapes at i32
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  %r  = add i32 %m, %e               ; keep %e live — escapes via ret
  ret i32 %r
}
