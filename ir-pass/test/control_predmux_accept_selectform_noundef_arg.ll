; control_predmux_accept_selectform_noundef_arg.ll — ACCEPT (bd 615s, increment 2).
; ARM: the OTHER direction of the Argument clause — `noundef` is a PROOF, and the
; leaf rule must honour it.
;
; *** THIS ROW EXISTS BECAUSE INCREMENT 1 SHIPPED AN OVER-DECLINE ON EXACTLY THE
; CODE THE TICKET SAYS THESE ATTRIBUTES COME FROM. *** That increment enumerated
; the four parameter attributes that make an argument poison-if-violated and
; failed the cone on any of them. But stock `clang -O1 -ffinite-math-only` emits
; the attribute TOGETHER WITH `noundef`:
;
;     float f(float x, float y) { return x < y ? x : y; }
;   ->  define nofpclass(nan inf) float @f(float noundef nofpclass(nan inf) %0,
;                                          float noundef nofpclass(nan inf) %1)
;
; and increment 1 DECLINED that (measured), even though the `noundef` sitting
; right beside the `nofpclass` is precisely the proof the cone proof needs.
;
; WHY `noundef` DISCHARGES THE OBLIGATION — quote the clause, not the
; generalisation. An earlier draft of this header argued "either the argument is
; defined, or the program is already UB and nothing we do is licensed or
; unlicensed", and the Rule-13 round pointed out that at THAT generality it is the
; bd s6ao move wearing different clothes. The load-bearing fact is narrower and is
; verbatim LangRef 19, from the list of positions where a poison value triggers
; IMMEDIATE UB:
;
;     "The parameter operand of a `call` or `invoke` instruction, when the
;      function OR INVOKING CALL SITE has a `noundef` attribute in the
;      corresponding position."
;
; The UB sits AT THE CALL, which happens-before every instruction of the callee
; body — so there is no ordering objection to answer: on any execution that
; REACHES the rewritten code, the parameter was defined. (s6ao's escape hatch was
; a WELL-DEFINED execution on which the artifact then read out of bounds; this
; one is NO EXECUTION AT ALL. That is the discriminator.)
;
; COMPOSITION with `range`/`nofpclass`/`nonnull`/`align` follows from the same
; clause: each of those says a POISON VALUE is passed instead, and a poison value
; in a `noundef` parameter operand IS the immediate-UB case. Measured: LLVM folds
; a `freeze` away for `noundef nofpclass(nan inf)`, i.e. it makes the identical
; inference on the identical construct.
;
; ONE HONEST RESIDUAL: on a UB input CQ does not decline, it EMITS — and the
; emitted circuit for a caller passing literal `undef` here is bd u1rp-shaped
; (forward and `_unc` reading two materialisations, rail freed dirty), which
; `declineUnpairedUndefLiterals` cannot see because at guard time the value is an
; `Argument`, not a literal. That is permitted — the program invoked UB at the
; call — but it is what the second half of the argument actually buys, so it is
; written down rather than left implicit.
;
; RED-GREEN, in the ACCEPT direction — the rarer and more easily faked kind, so
; state the pair: the PREVIOUS commit declines this module with
; `cq controlled lowering: control flow under quantum control`; this one lowers it
; and flattens the diamond. Its sibling
; control_predmux_reject_selectform_bare_arg.ll is the same module with `noundef`
; removed from `%x`'s counterpart, and it declines. The two together are what pin
; the predicate as "the presence of the PROOF", never "the absence of a channel".
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)

; The exact parameter shape `clang -O1 -ffinite-math-only` produces: the
; poison-generating attribute AND the proof that it was not violated.
define i32 @probe(i32 noundef %u, double noundef %uf, double noundef nofpclass(nan inf) %x) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %qf = call double @cq_theta_f64(double %uf, double 2.500000e-01)
  %a  = icmp sgt i32 %q, 3
  %b  = fcmp ogt double %qf, %x        ; the SHIELDED operand, off the attributed %x
  %c  = select i1 %a, i1 %b, i1 false
  br i1 %c, label %arm, label %merge

arm:
  %k1 = add i32 %q, 7
  %k2 = mul i32 %q, 3
  %k3 = add i32 %q, 11
  %k4 = mul i32 %q, 5
  br label %merge

merge:
  %p1 = phi i32 [ %k1, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %p3 = phi i32 [ %k3, %arm ], [ %q, %entry ]
  %p4 = phi i32 [ %k4, %arm ], [ %q, %entry ]
  %s1 = add i32 %p1, %p2
  %s2 = add i32 %s1, %p3
  %s3 = add i32 %s2, %p4
  %m  = call i32 @cq_measure_si32(i32 %s3)
  ret i32 %m
}

; The region IS claimed and flattened: the shielded select becomes a toffoli
; conjunction over the two compare rails, and no `br i1` survives.
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK:     call i32 @cq_template_fcmp_ogt_f64_hl(
; CHECK:     call void @cqrt_toffoli(
; CHECK-NOT: br i1
