; lowering_reject_qram_read_under_control_shl_wrap.ll — DECLINE (bd s6ao,
; Rule-13 round 2). THE BOUND ANALYSIS MUST NOT TRUNCATE INSIDE ITSELF.
;
; `unconditionalMax` (PoisonFacts.cpp) computes at a WIDE accumulator (65 bits)
; and must never let a rule's own arithmetic wrap there. The first draft of the
; `Shl` rule computed `A->shl(C)` at that width and then tested the PRODUCT for
; wrap. `APInt::shl` truncates, so a product exceeding 2^65 read as "no wrap" and
; the rule returned a bound BELOW the truth:
;
;   unconditionalMax(ctpop i64) = 64 = 2^6      (the operand-width rule)
;   APInt(65, 64) << 59         = 2^65 ≡ 0      (TRUNCATED)
;   0 < 2^64  =>  claimed max 0                 while the true max is 2^59
;
; A bound that shrinks as its input grows is not a bound, and the fence inverts:
; MEASURED on the draft, `shl … 58` DECLINED while `shl … 59` ACCEPTED — the
; SMALLER index refused and the LARGER admitted. The emitted circuit was an
; UNMASKED `cqrt_qram_load_f64` at index 2^59 of a THREE-cell table, `opt` exit
; 0, on the frozen-designate 7.5 symbol.
;
; *** WHY THE `range` ATTRIBUTE IS PRESENT AND MUST STAY. *** It is not
; decoration: it supplies the KNOWN-BITS side of the accept. Without it
; `computeKnownBits` alone refuses this cone, so the module declines for an
; unrelated reason and the fixture would pass while pinning nothing. The
; attribute is channel (A) in PoisonFacts.h — precisely the channel
; `UseInstrInfo=false` structurally cannot gate and the explicit walk exists to
; close — so this fixture pins the walk closing the very channel it advertises.
; TWO Rule-13 lenses filed this defect as "latent, not reachable" because they
; probed the shift WITHOUT feeding known-bits from that channel; one line of
; attribute is the whole difference between latent and live.
;
; The fix guards on the OPERAND's magnitude before shifting
; (`A->getActiveBits() + C > W`), never on the product.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@t3 = internal unnamed_addr constant [3 x double] [double 1.0, double 2.0, double 3.0]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i64 @llvm.ctpop.i64(i64)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %c = call range(i64 0, 1) i64 @llvm.ctpop.i64(i64 %bits)  ; supplies the KB side
  %sx = shl i64 %c, 59                                      ; 64<<59 wraps at 65 bits
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %g = getelementptr inbounds [3 x double], ptr @t3, i64 0, i64 %sx
  %v = load double, ptr %g, align 8
  %hd = fsub double %q, %v
  br label %merge
merge:
  %r = phi double [ %hd, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; Mirrored character-for-character from `kMsgQromUnderControlBounds`.
; CHECK: error: {{.*}}cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)
