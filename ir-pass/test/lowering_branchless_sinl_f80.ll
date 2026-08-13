; lowering_branchless_sinl_f80.ll — ACCEPT (bd 20xt.8 Inc 1): the lowering-layer
; regression for the AUTHORED branchless f80 `sinl` leaf
; (tools/library_coverage/branchless/sinl.c; e2e twin
; tests/e2e/slice_branchless_sinl.c). Pins that the leaf's construct fingerprint is
; PURE-REGISTER at x86_fp80 — the whole Bennett-parity recipe rests on this:
;
;   * the keep-set reduction/quadrant leaves rintl/floorl/fminl/fmaxl codegen to
;     `callq _{rint,floor,fmin,fmax}l` LIBCALLS, BUT cq-lowering rewrites the
;     @llvm.{rint,floor,minnum,maxnum}.f80 intrinsics to cq_template_*_f80 (curated
;     f80 bodies in runtime/cq_intrinsic_templates.c) BEFORE codegen — so the
;     "f80-floor-is-a-libcall" worry is MOOT and no Shadow/i80/memcpy appears;
;   * the fp-const-select quadrant blend (useS=(par<0.5)?1:0) is the kjd1 fp-DATA
;     select controlled-copy merge at f80 → cqrt_copy_f80_controlled (a libm body
;     mints no Rz/Ry, so the fcmp-condition / const-arm accept shape applies).
;
; This is the top-level tainted path (the branchless body inlines into the taint
; seed, NOT a Phase-6 clone). The cosl twin is lowering_branchless_cosl_f80.ll.
; Constants are the real ones clang emits for the leaf (PIO4, 0.5, 1.0, invpio2).
;
; The --implicit-check-not guards are GLOBAL (every point of the output, not just the
; post-`measure` tail a trailing CHECK-NOT would scan): no keep-set intrinsic CALL
; survives the rewrite (the input `declare @llvm.*.f80` lines legitimately remain, so
; the guard targets `call ... @llvm.` only), no Shadow/QROM memory, no per-fn sinl body.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s --implicit-check-not='call{{.*}}@llvm.' --implicit-check-not='cqrt_qram' --implicit-check-not='cq_template_sinl' < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)
declare x86_fp80 @llvm.rint.f80(x86_fp80)
declare x86_fp80 @llvm.floor.f80(x86_fp80)
declare x86_fp80 @llvm.minnum.f80(x86_fp80, x86_fp80)
declare x86_fp80 @llvm.maxnum.f80(x86_fp80, x86_fp80)

define x86_fp80 @branchless_sinl_leaf(x86_fp80 %u) {
entry:
  %q    = call x86_fp80 @cq_theta_f80(x86_fp80 %u, double 5.000000e-01)
  ; fn = rintl(q * 2/pi)  — the Cody–Waite quarter-turn count
  %qs   = fmul x86_fp80 %q, 0xK3FFEA2F9836E4E44152A
  %fn   = call x86_fp80 @llvm.rint.f80(x86_fp80 %qs)
  ; yc = fmaxl(-PIO4, fminl(fn, PIO4))  — the finite clamp (keep-set fmin/fmax)
  %ymin = call x86_fp80 @llvm.minnum.f80(x86_fp80 %fn, x86_fp80 0xK3FFEC90FDAA22168C235)
  %yc   = call x86_fp80 @llvm.maxnum.f80(x86_fp80 %ymin, x86_fp80 0xKBFFEC90FDAA22168C235)
  ; qf = floorl(yc)  — the fp quadrant leaf (no fptosi)
  %qf   = call x86_fp80 @llvm.floor.f80(x86_fp80 %yc)
  ; useS = (par < 0.5) ? 1.0 : 0.0  — the kjd1 const-operand fp-select blend
  %par  = fcmp olt x86_fp80 %qf, 0xK3FFE8000000000000000
  %useS = select i1 %par, x86_fp80 0xK3FFF8000000000000000, x86_fp80 0xK00000000000000000000
  %mag  = fmul x86_fp80 %useS, %yc
  %m    = call x86_fp80 @cq_measure_f80(x86_fp80 %mag)
  ret x86_fp80 %m
}

; The taint seed becomes an f80 allocation + Ry; the reduction multiply is HL.
; CHECK: call i32 @cqrt_alloc_f80(x86_fp80 %u)
; CHECK: call void @cqrt_ry_f80(
; CHECK: %[[QS:.*]] = call i32 @cq_template_fmul_f80_hl(
; The four keep-set intrinsic leaves lower to their curated f80 templates.
; CHECK: %[[FN:.*]] = call i32 @cq_template_rint_f80(i32 %[[QS]])
; CHECK: %[[YMIN:.*]] = call i32 @cq_template_fmin_f80_hl(i32 %[[FN]], x86_fp80 0xK3FFEC90FDAA22168C235)
; CHECK: %[[YC:.*]] = call i32 @cq_template_fmax_f80_hl(i32 %[[YMIN]], x86_fp80 0xKBFFEC90FDAA22168C235)
; CHECK: %[[QF:.*]] = call i32 @cq_template_floor_f80(i32 %[[YC]])
; The const-operand fp select becomes the kjd1 two-copy merge on a |0> f80 rail:
; the flag mint (fcmp olt HL), the |0> alloc, the two ¬flag-bracketed copies.
; CHECK: %[[FLG:.*]] = call i32 @cq_template_fcmp_olt_f80_hl(i32 %[[QF]], x86_fp80 0xK3FFE8000000000000000)
; CHECK: %[[SEL:.*]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK: call void @cqrt_copy_f80_controlled(i32 %[[FLG]],
; CHECK: call void @cqrt_x(i32 %[[FLG]])
; CHECK: call void @cqrt_copy_f80_controlled(i32 %[[FLG]],
; CHECK: call void @cqrt_x(i32 %[[FLG]])
; CHECK: call x86_fp80 @cqrt_measure_f80(
;
; (The "no intrinsic call survives / no Shadow / no per-fn sinl" negatives are the
; --implicit-check-not guards on the RUN line above — enforced GLOBALLY, so a stray
; intrinsic/QROM call anywhere in the body, not just the tail, would go RED.)
