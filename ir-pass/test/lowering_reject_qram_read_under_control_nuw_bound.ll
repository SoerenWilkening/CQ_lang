; lowering_reject_qram_read_under_control_nuw_bound.ll — DECLINE (bd s6ao).
; THE INDEX BOUND MAY NOT BE DERIVED FROM A POISON-GENERATING FLAG.
;
; `%sx = sub nuw i64 %hi, 1` with `%hi = lshr(bits,63)` ∈ {0,1}: `nuw` asserts the
; subtraction does not wrap, i.e. `%hi >= 1`, so `computeKnownBits` concludes
; `%sx == 0` and the claim reports Provable. THAT PROOF IS INVALID HERE, for the
; reason `classifyQromReadUnderControlImpl`'s own contract states
; (QramLowering.cpp): "the SPECULATED read runs on every basis state, so
; in-bounds must hold UNCONDITIONALLY (known-bits), not merely on the originally-
; guarded path". `nuw` is a promise about the paths the SOURCE executes — exactly
; the originally-guarded path — so the proof discharged its own obligation with
; the one class of fact that obligation excludes.
;
; Compounding it, Rule 15's width-only ABI THROWS THE FLAG AWAY: `sub nuw` lowers
; to the WRAPPING `cq_template_sub_i64_hl`. So the flag-derived bound described a
; value the emitted circuit does not compute. Before bd s6ao this module lowered
; at `opt` exit 0 to an UNMASKED `cqrt_qram_load_f64` into a THREE-cell table
; whose index rail carries 0xFFFF_FFFF_FFFF_FFFF on every basis state where bit
; 63 is clear — verify-clean, `free_pairing_check.py`-clean, golden-plausible, on
; a FROZEN-designate 7.5 symbol. That is the silent miscompile this pins.
;
; GREEN TWIN: control_predmux_accept_qrom_read_nonpow2_provable.ll drops the
; `sub` entirely and keeps the bare `lshr(bits,63)` bound, which still accepts
; unmasked. That is the capability this fence must not cost.
;
; *** WHAT THIS FIXTURE DOES NOT PIN, stated because an earlier header claimed
; the opposite. *** It is NOT true that `nuw` is "the sole discriminator": strip
; the token and the module STILL declines (measured, character-identical
; diagnostic), because `Sub` is not modelled by `unconditionalMax` and falls to
; `full()`. So this pins the OUTCOME (a flag-derived bound never lowers unmasked)
; and not the MECHANISM. If someone later teaches the walk to model `sub`, this
; fixture must be revisited — at that point the flag would become the
; discriminator and the header's original claim would finally be true.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@t3 = internal unnamed_addr constant [3 x double] [double 1.0, double 2.0, double 3.0]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %hi = lshr i64 %bits, 63
  %sx = sub nuw i64 %hi, 1                 ; the ONLY difference from the green twin
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

; The diagnostic is mirrored character-for-character from
; `kMsgQromUnderControlBounds` (QramLowering.cpp) so code and test cannot drift.
; CHECK: error: {{.*}}cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)
