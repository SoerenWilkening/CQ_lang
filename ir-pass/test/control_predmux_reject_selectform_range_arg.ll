; control_predmux_reject_selectform_range_arg.ll — DECLINE (bd 615s, Option 1).
; ARM: `classifyConeNode`'s ARGUMENT clause — a parameter carrying a
; poison-generating attribute is not an unconditionally defined cone leaf.
;
; THE OBLIGATION. `coneDefinedAfterFlagDrop` promises "this cone is DEFINED once
; its poison-generating annotations are dropped", and on the strength of that
; promise the flatten rewrites the poison-SHIELDED `select(a, b, false)` into a
; plain `and(a, b)` — which OBSERVES `%b` on the basis states the shield excluded.
; The old leaf rule shortcut EVERY non-Instruction with a bare
; `Constant / Argument leaf — defined`. A `range(i32 0, 10) i32 %c` parameter is
; poison whenever the caller passes 10 or more, so `%b`'s cone is defined only
; CONDITIONALLY, on a fact the callee cannot check and this pass cannot drop:
; `dropPoisonGeneratingAnnotations()` mutates INSTRUCTIONS, and the attribute that
; would have to go lives on the caller's CALL SITE, in another function.
;
; RED-GREEN, MEASURED BY ARM-KILL rather than asserted. With the Argument clause
; disabled this module is ACCEPTED (`opt` exit 0), the diamond is flattened, and
; `%cc = add i32 %c, 1` — whose definedness rests entirely on that attribute
; holding — lands in the emitted stream twice:
;
;   %h_cmp1 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %cc)
;   call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)     ; the `and`
;   call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp1, i32 %h, i32 %cc)
;   call void @cqrt_free(i32 %h_cmp1)
;
; BE PRECISE ABOUT WHICH DEFECT THIS IS. It is NOT the xy9n forward/adjoint pairing
; break: `%cc` is one SSA register read twice, so both gates see one value and
; `declineUnpairedUndefLiterals` correctly counts zero literal slots. The defect is
; the one `coneDefinedAfterFlagDrop` exists to prevent — the conjunction is now
; evaluated on basis states where the source's short circuit never evaluated `%b`
; at all, and on those states `%b` is derived from poison. The rail `%h_cmp1` is
; then compared, conjoined, strip-uncomputed and freed as if it were data.
;
; SCOPE — READ THIS BEFORE QUOTING THE FIXTURE. It closes the ATTRIBUTED argument,
; whose measured population is ZERO. A BARE `Argument` leaf is STILL called
; defined, which is false in exactly the same way (a caller may pass `poison` to
; any parameter). See control_predmux_accept_selectform_bare_arg.ll, which pins
; that residual deliberately and carries the corrected cost measurement, and bd
; 615s, which stays open for it. Do NOT repeat the "28 of 49 real select-forms"
; budget an earlier draft carried here: the Rule-13 round measured it over this
; pass's OWN hand-written fixtures and ~14x too high.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u, i32 range(i32 0, 10) %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %cc = add i32 %c, 1          ; defined only if the caller honours the range
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

; The region is LEFT UNCLAIMED at the cone gate — not claimed and then repaired:
; DBG: leave @probe entry=entry merge=merge gate=E6-condtree
