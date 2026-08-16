; control_predmux_reject_selectform_bare_arg.ll — DECLINE (bd 615s, increment 2).
; ARM: `classifyConeNode`'s Argument clause on a BARE parameter — the POPULATED
; half of bd 615s, which increment 1 left open and this row closes.
;
; *** THIS FILE WAS AN ACCEPT FIXTURE ONE COMMIT AGO, AND THAT IS THE POINT. ***
; It shipped as `control_predmux_accept_selectform_bare_arg.ll`, pinning a
; KNOWN-UNSOUND accept on purpose and saying so in its own header, because
; increment 1 enumerated the four poison-generating parameter attributes
; (`nofpclass`/`range`/`nonnull`/`align`) and a bare `Argument` carries none of
; them. The leaf rule therefore still called it "defined", which is literally
; false: a caller may pass `poison` to any parameter, and the flatten's
; `select(a, b, false)` -> `and(a, b)` canonicalization then OBSERVES the shielded
; `%b` on basis states the source's short circuit excluded.
;
; INCREMENT 2 REPLACED THE ENUMERATION WITH ONE QUESTION. An `Argument` is a
; defined cone leaf IFF it carries `noundef` — LangRef's direct statement that the
; value representation contains no undefined or poison bits, on pain of IMMEDIATE
; UB rather than poison. That asks the CONVERSE question ("can this be proven
; defined WITHOUT any poison-conditional fact?") instead of scanning for channels,
; which is the bd s6ao lesson applied to this surface; and it stays correct when
; LLVM adds a fifth poison-generating attribute.
;
; WHY THE SWITCH WAS CHEAP, AND WHY THE OLD COST NUMBER SAID OTHERWISE. Increment
; 1's comment justified leaving this half open with "28 of the 49 shielded
; select-forms in the corpus reach a bare Argument ... refusing bare arguments
; would decline 28 REAL select-forms". The corpus was never named and is
; `ir-pass/test` — the pass's own hand-written fixtures — 19 of the 28 are
; exit-code-inverted decline rows, and a SHAPE census is not a FENCE measurement.
; The arm-kill is: closing this half changes THREE of 1050 fixtures — this row and
; the two bd u1rp controls, both restored by adding the `noundef` that `clang -O1`
; emits for a real parameter anyway (lowering then identical, define line aside).
;
; *** DO NOT WRITE "AND ZERO REAL MODULES" HERE. An earlier draft did, and the
; Rule-13 round measured that it is a NO-REACH ZERO. *** With the MAXIMAL arm
; (`Fail` on EVERY `Argument`, the strictest this predicate can be) the 220 e2e
; stage-1 modules give 0 differ on exit code AND emitted IR — so no real-code
; corpus available here can distinguish ANY setting of this clause, and the zero
; says nothing about it. The same goes for "428/428 openlibm formal parameters
; carry `noundef`": that explains why two arms agree, never why every arm does.
;
; THE REAL COST IS NOT ZERO, and it is measured: `clang` omits `noundef` from
; every register-coerced by-value RECORD parameter, so ordinary C taking a
; `struct` by value now declines MODULE-wide where it previously lowered. That is
; the price, and it is the SAME CELL as the hole — clang omits the attribute there
; precisely because the coerced value may carry undef padding bits, so refusing it
; is refusing a genuinely unproven value rather than misfiring. The fence is
; coarse, not wrong: the cone usually reads a defined FIELD out of that value and
; CQ has no per-field proof. A field-granular admission is filed as its own
; additive increment.
;
; RED-GREEN: the previous commit ACCEPTS this module (`opt` exit 0) and flattens
; the diamond; add `noundef` to `%c` and it accepts again — that is
; control_predmux_accept_selectform_noundef_arg.ll, the paired control.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u, i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %cc = add i32 %c, 1          ; defined only if the caller passes a defined %c
  %b = icmp sgt i32 %q, %cc    ; the SHIELDED operand
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; The region is LEFT UNCLAIMED at the cone gate — never canonicalized:
; DBG: leave @probe entry=entry merge=merge gate=E6-condtree
