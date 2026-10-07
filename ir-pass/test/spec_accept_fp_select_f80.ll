; spec_accept_fp_select_f80.ll — ACCEPT (bd adia, 3c6m.55 Lever C): an
; x86_fp80 (long double) fp select inside a Phase-6 lifted clone — the
; `fabsl` if-conversion shape (`(n<0) ? -x : x` over f80), followed by a
; `fptosi x86_fp80 → i32` reading the select's merge rail (the openlibm expl
; `n = (int)floorl(...)` exponent cast). Pins THREE Lever-C composes at once:
;   * `isLiftableFpSelect` (`isAdmissibleCloneSelect` since bd p3kd.7.1) admits f80 (was the kmdc {f32,f64} slice-1
;     whitelist); the emission mints `cqrt_copy_f80_controlled` — the kjd1
;     frozen select-local family, via `copyControlledFpFn` ONLY (the shared
;     integer minter's fp-null classifier is untouched);
;   * the clone select out-rail records its LOGICAL width (p119.6, clone
;     edition) so the downstream `fptosi` resolves
;     `cq_template_fptosi_f80_to_i32` off the laundered i32 handle;
;   * the Bennett wrap reverses the whole stream (`_unc` twins + re-bracketed
;     self-inverse copies) and frees every scratch rail proven-|0>.
; f16 stays declined (spec_reject_fp_select_f16.ll). Formerly
; spec_reject_fp_select_f80.ll (the slice-1 whitelist decline).
;
; bd p3kd.7.8: main's 4.4 `SelectMergeEmit` now lowers the clone's select (still
; minting `cqrt_copy_f80_controlled`, and the fptosi still resolves f80 off the merge
; rail); the merge's trailing `cqrt_x` strip is elided in the forward and the mirror
; replays the copies around one `cqrt_x`. Hand trace, |n>: SEL = [n<0]·(−x) ⊕ ¬[n<0]·x
; with x = (f80)n; R = fptosi(SEL) copied out; the mirror zeroes R, SEL, the flag,
; −x and x in reverse, and every freed rail is |0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x  = sitofp i32 %n to x86_fp80
  %c  = icmp slt i32 %n, 0
  %nx = fneg x86_fp80 %x
  %a  = select i1 %c, x86_fp80 %nx, x86_fp80 %x
  %r  = fptosi x86_fp80 %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK-LABEL: define internal i32 @__cq_q_mhelper_1(i32 %n)
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f80(i32 %n)
; CHECK-NEXT: %[[NX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fneg_f80(i32 %[[X]])
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %n, i32 0)
; The f80 |0> rail + the two-copy fp merge (¬flag copy after one `cqrt_x`; strip elided).
; CHECK-NEXT: %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK-NEXT: call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[NX]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[X]], i32 %[[SEL]])
; The p119.6 clone-HandleWidth compose: the fptosi resolves f80 off the rail.
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f80_to_i32(i32 %[[SEL]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[R]], i32 %[[OUT]])
; Bennett mirror: the fptosi `_unc`, the copies replayed around the `cqrt_x`, the
; flag/cast `_unc` twins, then proven-|0> frees; the out handle returns.
; CHECK-NEXT: call void @cq_template_fptosi_f80_to_i32_unc(i32 %[[R]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[X]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[NX]], i32 %[[SEL]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F]], i32 %n, i32 0)
; CHECK-NEXT: call void @cq_template_fneg_f80_unc(i32 %[[NX]], i32 %[[X]])
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f80_unc(i32 %[[X]], i32 %n)
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[NX]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: ret i32 %[[OUT]]
; CHECK-NEXT: }
