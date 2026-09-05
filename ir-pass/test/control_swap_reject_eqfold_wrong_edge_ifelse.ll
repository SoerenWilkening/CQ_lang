; control_swap_reject_eqfold_wrong_edge_ifelse.ll — D8 POLARITY decline on the
; IF/ELSE, where ONE arm's fold is valid and the SIBLING's is not
; (bd test_C_libtooling-ogw2).
;
; The diamond probes (control_swap_reject_eqfold_wrong_edge_{eq,ne}.ll) put the
; single folded arm on the wrong edge. This one is the harder shape, and the
; reason it earns its own fixture: the `then` arm IS a genuine fold (`q == 7`
; holds there, D1–D8 all pass, `tryEqFoldArm` ACCEPTS it and anchors `Routed` to
; `%q`), so a polarity clause that reasoned about the REGION — "does this region
; have a valid eq-fold arm?" — would answer yes and wave the sibling through.
; D8 is asked PER ARM, of the block it was handed, which is what catches the
; second one.
;
; WHAT THE SHAPE MEANS. The `else` arm is the `q != 7` region, so its
; `cq_phi(i32 7, θ)` is a VALUE CLOBBER (discard `q`, take the phase-rotated
; literal 7), not a phase on `q`. Accepting it re-anchors that gate to `%q` and
; emits `cqrt_rz_i32_controlled(¬flag, q, b)` — a phase on `q` on precisely the
; branch where the source replaces `q` with a constant.
;
; WHY HAND-IR ONLY. `clang -O1` folds an arm gate only where it PROVED the
; equality holds in that arm; a fold to `7` in the `q != 7` arm is not a shape it
; can emit. Hand-IR reachable only, and still owed a loud decline.
;
; MEASURED ON THE PRE-FIX BINARY (HEAD 24bb42d): this module LOWERED, `opt` exit
; 0, emitting BOTH arms as controlled phases on the same register —
;     %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 7)
;     call void @cqrt_rz_i32_controlled(i32 %h_cmp, i32 %h, double %a)
;     call void @cqrt_x(i32 %h_cmp)
;     call void @cqrt_rz_i32_controlled(i32 %h_cmp, i32 %h, double %b)
;     call void @cqrt_x(i32 %h_cmp)
;     call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 7)
;     call void @cqrt_free(i32 %h_cmp)
; — indistinguishable, gate for gate, from the fully-valid @ifelse_eq of
; control_swap_eqfold_ifelse.ll, which is exactly why no golden trace and no
; `free_pairing_check.py` run could have told the two apart. Only the SECOND
; `cqrt_rz` is wrong, and only in which basis it names.
;
; Post-D8 the `then` arm still accepts and the `else` arm falls through to the
; closing generic decline, so the whole region declines — the correct answer: an
; if/else whose two arms disagree about the fold has no single routable phase
; base (Prime Directive; over-declining is safe).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; Neither arm may be emitted — a PARTIAL lowering (the valid `then` arm alone)
; would be the same silent miscompile with one gate fewer.
; CHECK-NOT: cqrt_rz_i32_controlled
; CHECK-NOT: cqrt_cswap
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %then, label %else
then:
  call void @cq_phi(double %a)  ; VALID fold — q == 7 holds here
  br label %merge
else:
  call void @cq_phi(double %b)  ; INVALID — q != 7 holds here
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 7)
  ret i32 %m
}
