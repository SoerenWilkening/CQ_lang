; lowering_branchless_tanl_f80.ll — ACCEPT (bd 20xt.9): the lowering-layer regression
; for the AUTHORED branchless f80 `tanl` leaf (tools/library_coverage/branchless/tanl.c;
; e2e twin tests/e2e/slice_branchless_tanl.c) — the missing trio leaf beside
; lowering_branchless_{sinl,cosl}_f80.ll. Pins that the leaf's construct fingerprint is
; PURE-REGISTER at x86_fp80, same as sinl/cosl, PLUS the tanl-specific tail: tan is
; reconstructed as a RATIO of the k_sinl/k_cosl kernels (NOT openlibm's branchy
; ld80/k_tanl.c polynomial), so the distinguishing op is ONE unconditional QQ division
; num/den -> cq_template_fdiv_f80 (both operands tainted handles).
;
;   * the keep-set reduction/parity leaves rintl/floorl/fminl/fmaxl codegen to
;     `callq _{rint,floor,fmin,fmax}l` LIBCALLS, BUT cq-lowering rewrites the
;     @llvm.{rint,floor,minnum,maxnum}.f80 intrinsics to cq_template_*_f80 (curated
;     f80 bodies in runtime/cq_intrinsic_templates.c) BEFORE codegen — no Shadow/i80;
;   * the fp-const-select parity blend (useT=(par<0.5)?1:0) is the kjd1 fp-DATA select
;     controlled-copy merge at f80 -> cqrt_copy_f80_controlled (a libm body mints no
;     Rz/Ry, so the fcmp-condition / const-arm accept shape applies);
;   * num/den are UNCONDITIONAL weighted sums over always-computed S,C, and the final
;     num/den is a QQ fdiv -> cq_template_fdiv_f80.
;
; Top-level tainted path (the branchless body inlines into the taint seed, NOT a
; Phase-6 clone). S,C here are minimal computed proxies for the kernels — the fixture
; pins the construct fingerprint (rint/fmin/fmax/floor + const-select + QQ fdiv), not
; the full polynomial (the e2e golden slice_branchless_tanl.expected.log pins that).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s --implicit-check-not='call{{.*}}@llvm.' --implicit-check-not='cqrt_qram' --implicit-check-not='cq_template_tanl' < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)
declare x86_fp80 @llvm.rint.f80(x86_fp80)
declare x86_fp80 @llvm.floor.f80(x86_fp80)
declare x86_fp80 @llvm.minnum.f80(x86_fp80, x86_fp80)
declare x86_fp80 @llvm.maxnum.f80(x86_fp80, x86_fp80)

define x86_fp80 @branchless_tanl_leaf(x86_fp80 %u) {
entry:
  %q    = call x86_fp80 @cq_theta_f80(x86_fp80 %u, double 5.000000e-01)
  ; fn = rintl(q * 2/pi)  — the Cody–Waite quarter-turn count
  %qs   = fmul x86_fp80 %q, 0xK3FFEA2F9836E4E44152A
  %fn   = call x86_fp80 @llvm.rint.f80(x86_fp80 %qs)
  ; yc = fmaxl(-PIO4, fminl(fn, PIO4))  — the finite clamp (keep-set fmin/fmax)
  %ymin = call x86_fp80 @llvm.minnum.f80(x86_fp80 %fn, x86_fp80 0xK3FFEC90FDAA22168C235)
  %yc   = call x86_fp80 @llvm.maxnum.f80(x86_fp80 %ymin, x86_fp80 0xKBFFEC90FDAA22168C235)
  ; S,C — minimal computed proxies for the k_sinl/k_cosl kernels (two tainted handles)
  %S    = fmul x86_fp80 %yc, %yc
  %C    = fadd x86_fp80 %yc, %yc
  ; par = floorl(yc); useT = (par < 0.5) ? 1.0 : 0.0  — the kjd1 const-operand fp-select
  %par  = call x86_fp80 @llvm.floor.f80(x86_fp80 %yc)
  %pf   = fcmp olt x86_fp80 %par, 0xK3FFE8000000000000000
  %useT = select i1 %pf, x86_fp80 0xK3FFF8000000000000000, x86_fp80 0xK00000000000000000000
  %om   = fsub x86_fp80 0xK3FFF8000000000000000, %useT
  ; num = useT*S + (1-useT)*(-C)
  %negC = fneg x86_fp80 %C
  %nA   = fmul x86_fp80 %useT, %S
  %nB   = fmul x86_fp80 %om, %negC
  %num  = fadd x86_fp80 %nA, %nB
  ; den = useT*C + (1-useT)*S
  %dA   = fmul x86_fp80 %useT, %C
  %dB   = fmul x86_fp80 %om, %S
  %den  = fadd x86_fp80 %dA, %dB
  ; tan = num / den  — the ONE unconditional QQ division (the tanl fingerprint)
  %r    = fdiv x86_fp80 %num, %den
  %m    = call x86_fp80 @cq_measure_f80(x86_fp80 %r)
  ret x86_fp80 %m
}

; The taint seed becomes an f80 allocation + Ry; the reduction multiply is HL.
; CHECK: call i32 @cqrt_alloc_f80(x86_fp80 %u)
; CHECK: call void @cqrt_ry_f80(
; CHECK: %[[QS:.*]] = call i32 @cq_template_fmul_f80_hl(
; The keep-set intrinsic leaves lower to their curated f80 templates.
; CHECK: %[[FN:.*]] = call i32 @cq_template_rint_f80(i32 %[[QS]])
; CHECK: %[[YMIN:.*]] = call i32 @cq_template_fmin_f80_hl(i32 %[[FN]], x86_fp80 0xK3FFEC90FDAA22168C235)
; CHECK: %[[YC:.*]] = call i32 @cq_template_fmax_f80_hl(i32 %[[YMIN]], x86_fp80 0xKBFFEC90FDAA22168C235)
; CHECK: call i32 @cq_template_floor_f80(
; The const-operand fp select becomes the kjd1 two-copy merge on a |0> f80 rail:
; the flag mint (fcmp olt HL), the |0> alloc, the two ¬flag-bracketed copies.
; CHECK: %[[FLG:.*]] = call i32 @cq_template_fcmp_olt_f80_hl(
; CHECK: call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK: call void @cqrt_copy_f80_controlled(i32 %[[FLG]],
; CHECK: call void @cqrt_x(i32 %[[FLG]])
; CHECK: call void @cqrt_copy_f80_controlled(i32 %[[FLG]],
; CHECK: call void @cqrt_x(i32 %[[FLG]])
; The tanl fingerprint: num/den is ONE unconditional QQ division (both handles).
; CHECK: call i32 @cq_template_fdiv_f80(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK: call x86_fp80 @cqrt_measure_f80(
;
; (The "no intrinsic call survives / no Shadow / no per-fn tanl" negatives are the
; --implicit-check-not guards on the RUN line above — enforced GLOBALLY.)
