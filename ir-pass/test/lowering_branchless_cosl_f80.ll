; lowering_branchless_cosl_f80.ll — ACCEPT (bd 20xt.8 Inc 1): the lowering-layer
; regression for the AUTHORED branchless f80 `cosl` leaf
; (tools/library_coverage/branchless/cosl.c; e2e twin
; tests/e2e/slice_branchless_cosl.c). cos = sin(x + π/2): the SAME pure-register
; keep-set reduction + kjd1 fp-const-select quadrant blend as the sinl leaf
; (lowering_branchless_sinl_f80.ll), differing ONLY by the +1 quadrant offset —
; the `fq = fn + 1.0` (cq_template_fadd_f80_hl) feeding the quadrant floorl. This
; pins that the offset is a stock reversible fadd (no new construct) and the leaf
; stays PURE-REGISTER at x86_fp80 (keep-set intrinsics → cq_template_*_f80, the
; fp-const-select → cqrt_copy_f80_controlled; no Shadow/i80/memcpy, never declines).
;
; The --implicit-check-not guards are GLOBAL (every point of the output, not just the
; post-`measure` tail a trailing CHECK-NOT would scan): no keep-set intrinsic CALL
; survives the rewrite (the input `declare @llvm.*.f80` lines legitimately remain, so
; the guard targets `call ... @llvm.` only), no Shadow/QROM memory, no per-fn cosl body.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --implicit-check-not='call{{.*}}@llvm.' --implicit-check-not='cqrt_qram' --implicit-check-not='cq_template_cosl'
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)
declare x86_fp80 @llvm.rint.f80(x86_fp80)
declare x86_fp80 @llvm.floor.f80(x86_fp80)
declare x86_fp80 @llvm.minnum.f80(x86_fp80, x86_fp80)
declare x86_fp80 @llvm.maxnum.f80(x86_fp80, x86_fp80)

define x86_fp80 @branchless_cosl_leaf(x86_fp80 %u) {
entry:
  %q    = call x86_fp80 @cq_theta_f80(x86_fp80 %u, double 5.000000e-01)
  ; fn = rintl(q * 2/pi)  — the SAME Cody–Waite quarter-turn count as sinl
  %qs   = fmul x86_fp80 %q, 0xK3FFEA2F9836E4E44152A
  %fn   = call x86_fp80 @llvm.rint.f80(x86_fp80 %qs)
  ; yc = fmaxl(-PIO4, fminl(fn, PIO4))  — the finite clamp (keep-set fmin/fmax)
  %ymin = call x86_fp80 @llvm.minnum.f80(x86_fp80 %fn, x86_fp80 0xK3FFEC90FDAA22168C235)
  %yc   = call x86_fp80 @llvm.maxnum.f80(x86_fp80 %ymin, x86_fp80 0xKBFFEC90FDAA22168C235)
  ; cos = sin(x+π/2): quadrant on fq = fn + 1.0 (the ONLY delta from sinl)
  %fq   = fadd x86_fp80 %fn, 0xK3FFF8000000000000000
  %qf   = call x86_fp80 @llvm.floor.f80(x86_fp80 %fq)
  ; useS = (par < 0.5) ? 1.0 : 0.0  — the kjd1 const-operand fp-select blend
  %par  = fcmp olt x86_fp80 %qf, 0xK3FFE8000000000000000
  %useS = select i1 %par, x86_fp80 0xK3FFF8000000000000000, x86_fp80 0xK00000000000000000000
  %mag  = fmul x86_fp80 %useS, %yc
  %m    = call x86_fp80 @cq_measure_f80(x86_fp80 %mag)
  ret x86_fp80 %m
}

; CHECK: call i32 @cqrt_alloc_f80(x86_fp80 %u)
; CHECK: call void @cqrt_ry_f80(
; CHECK: %[[QS:.*]] = call i32 @cq_template_fmul_f80_hl(
; CHECK: %[[FN:.*]] = call i32 @cq_template_rint_f80(i32 %[[QS]])
; CHECK: %[[YMIN:.*]] = call i32 @cq_template_fmin_f80_hl(i32 %[[FN]], x86_fp80 0xK3FFEC90FDAA22168C235)
; CHECK: %[[YC:.*]] = call i32 @cq_template_fmax_f80_hl(i32 %[[YMIN]], x86_fp80 0xKBFFEC90FDAA22168C235)
; The cos +1 quadrant offset is a stock reversible fadd (HL), then the floorl.
; CHECK: %[[FQ:.*]] = call i32 @cq_template_fadd_f80_hl(i32 %[[FN]], x86_fp80 0xK3FFF8000000000000000)
; CHECK: %[[QF:.*]] = call i32 @cq_template_floor_f80(i32 %[[FQ]])
; The kjd1 two-copy fp-select merge on a |0> f80 rail.
; CHECK: %[[FLG:.*]] = call i32 @cq_template_fcmp_olt_f80_hl(i32 %[[QF]], x86_fp80 0xK3FFE8000000000000000)
; CHECK: %[[SEL:.*]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK: call void @cqrt_copy_f80_controlled(i32 %[[FLG]],
; CHECK: call void @cqrt_x(i32 %[[FLG]])
; CHECK: call void @cqrt_copy_f80_controlled(i32 %[[FLG]],
; CHECK: call void @cqrt_x(i32 %[[FLG]])
; CHECK: call x86_fp80 @cqrt_measure_f80(
;
; (The "no intrinsic call survives / no Shadow / no per-fn cosl" negatives are the
; --implicit-check-not guards on the RUN line above — enforced GLOBALLY, so a stray
; intrinsic/QROM call anywhere in the body, not just the tail, would go RED.)
