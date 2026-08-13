; lowering_fp80_union_seed_purecall_i80cmp.ll — ACCEPT (bd 3c6m.14.1).
;
; SURFACE S3 — `Fp80Union`'s `AdmitArgDerived` SEED CONE, and the half of the
; increment that lives in a DIFFERENT MODULE making a DIFFERENT accept decision.
; This is why the ticket scopes (A) and (B) as one increment: `Fp80Union.cpp`
; consumes the pure-callee proof through the exported `isSpeculatablePureCallee`,
; so widening the proof for PredMux widens this whether or not anyone looks.
;
; It is the shipped lowering_fp80_union_seed_purecall.ll (bd adia Lever C, the
; `expl` seeding its k-scaling union from an outlined `floorl`) with ONE change:
; the pure callee now carries an fp80 BIT-PATTERN compare — the openlibm
; `GET_LDBL_MAN` / `manh == LDBL_NBIT && manl == 0` test shape — as its only
; off-grid instruction. Pre-change that made `@purefloor` un-provable, the seed
; cone failed, the candidate was dropped, and `%u` stayed an alloca. Measured on
; a pinned pre-change plugin (this is a genuine red-green, not a forward pin):
;
;     PRE :  %u = alloca %union.IEEEl2bits, align 16   ... load i64 ...
;     POST:  no alloca; bitcast x86_fp80 %px to i80 + lshr/trunc/zext
;
; SOUNDNESS, stated because "more unions promote" is a real mutation and not a
; no-op: the seed gate is a SCOPE classifier, not the padding fence. A candidate
; that needs the widened mode classifies OPPORTUNISTIC, and the §4.1 PaddingWalk
; — which owns padding soundness and is unchanged — still runs over the larger
; candidate set; on a PADDING violation the opportunistic set is dropped and the
; strict fixpoint re-runs rather than diagnosing. (That negative is pinned by the
; shipped lowering_fp80_union_mixed_oppfail_promotes.ll / _mixed_strictfail_loud.ll
; pair, which this fixture does not duplicate.)
;
; DO NOT GENERALISE THAT INTO "the widening can only ever ADD a promotion" — the
; first draft of this header did, and a Rule-13 lens falsified it in both
; directions with runs: a newly promoted union reaches the POST-promotion
; i80-phi scan and can draw a `kMsgFp80I80Merge` the pre-change plugin never
; emitted; and because a walk failure drops the WHOLE opportunistic class, a
; walk-failing pure-callee-seeded candidate can drag down a walk-clean
; arg-seeded sibling that used to promote. Both directions are safe (loud
; decline / memory form, never a silent miscompile) and neither is pinned by a
; fixture — see the note at the admission site in Fp80Union.cpp.
;
; The quantum anchor keeps the module off the passthrough early-out. Note that
; @helper is never called from quantum code: the promotion decision here is
; module-level and taint-independent, which is precisely what makes it a
; separate surface from S1/S2.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @anchor(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}

; The pure acyclic fp body, now carrying the fp80 bit-pattern compare.
define x86_fp80 @purefloor(x86_fp80 %x) {
entry:
  %bc = bitcast x86_fp80 %x to i80
  %man = and i80 %bc, 18446744073709551615
  %eq = icmp eq i80 %man, 9223372036854775808
  %n = fsub x86_fp80 %x, 0xK3FFF8000000000000000
  %p = select i1 %eq, x86_fp80 %n, x86_fp80 %x
  ret x86_fp80 %p
}

; u.e = purefloor(x); return u.bits.exp — the expl k-scaling GET whose seed cone
; crosses the outlined pure call.
define i32 @helper(x86_fp80 noundef %x) {
entry:
  %u = alloca %union.IEEEl2bits, align 16
  %px = call x86_fp80 @purefloor(x86_fp80 %x)
  store x86_fp80 %px, ptr %u, align 16
  %g = getelementptr inbounds i8, ptr %u, i64 8
  %w = load i64, ptr %g, align 8
  %e = and i64 %w, 32767
  %t = trunc i64 %e to i32
  ret i32 %t
}

; @purefloor itself is untouched — Fp80Union promotes the CALLER's union, it does
; not rewrite the proven-pure callee. (It precedes @helper in the output, so it
; is checked first: CHECK-LABEL blocks are ordered.)
; CHECK-LABEL: define x86_fp80 @purefloor(x86_fp80 %x)
; CHECK:         icmp eq i80 %{{[a-zA-Z0-9_.]+}}, 9223372036854775808

; The union promotes to register form: the call result is bitcast-extracted
; directly, the alloca is gone, and the 15-bit exponent mask survives on the
; extracted word (dropping it would silently widen `bits.exp` into `bits.sign`).
; The red-green assertion is the `CHECK-NOT: alloca` between the label and the
; first positive directive: on the pre-change plugin @helper opens with
; `%u = alloca %union.IEEEl2bits` and the register chain below does not exist.
; (An earlier draft also carried a trailing `CHECK-NOT: load` and called it half
; the assertion; a Rule-13 lens showed it was STRUCTURALLY INERT — after the
; final positive directive FileCheck scopes it to [ret .. EOF], a region holding
; only `declare` lines. The load-freeness is instead asserted positionally by the
; CHECK-NEXT chain, which admits no instruction between the bitcast and the ret.)
; CHECK-LABEL: define i32 @helper(x86_fp80 noundef %x)
; CHECK-NOT:     alloca
; CHECK:         %[[PX:[a-zA-Z0-9_.]+]] = call x86_fp80 @purefloor(x86_fp80 %x)
; CHECK-NEXT:    %[[B:[a-zA-Z0-9_.]+]] = bitcast x86_fp80 %[[PX]] to i80
; CHECK-NEXT:    %[[HI:[a-zA-Z0-9_.]+]] = lshr i80 %[[B]], 64
; CHECK-NEXT:    %[[W:[a-zA-Z0-9_.]+]] = trunc i80 %[[HI]] to i16
; CHECK-NEXT:    %[[Z:[a-zA-Z0-9_.]+]] = zext i16 %[[W]] to i64
; CHECK-NEXT:    %[[E:[a-zA-Z0-9_.]+]] = and i64 %[[Z]], 32767
; CHECK-NEXT:    %[[T:[a-zA-Z0-9_.]+]] = trunc i64 %[[E]] to i32
; CHECK-NEXT:    ret i32 %[[T]]
