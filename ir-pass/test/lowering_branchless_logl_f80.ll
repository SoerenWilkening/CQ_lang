; lowering_branchless_logl_f80.ll — ACCEPT (bd 20xt.8 Inc 2): the lowering-layer
; regression for the AUTHORED branchless f80 `logl` leaf
; (tools/library_coverage/branchless/logl.c; e2e twin
; tests/e2e/slice_branchless_logl.c). Pins the recipe's load-bearing claim: the
; frexp mantissa/exponent split reads x's raw bits through a `union IEEEl2bits`,
; and clang -O1's SROA promotes that union round-trip (store f80 · load i64@8 ·
; rewrite the exponent field · reload f80 — reproduced verbatim below) to PURE
; SSA integer surgery on the f80. cq-lowering must lower that surgery to the
; reversible cq_template_{bitcast,lshr,shl,and,or,trunc,zext}_i80/i64/i32 family
; on register handles — with NO Shadow, NO qram, NO residual alloca/store/load.
; That is what makes the union split the correct choice over a 10-byte fp80
; __builtin_memcpy (which straddles the 80→128 padding into a pattern SROA cannot
; always promote — the kMsgStore risk).
;
;   * the exponent is recovered as (bits>>64 & 0x7FFF) − 16382 → sitofp i32→f80;
;   * the mantissa is rebuilt by overwriting the exponent field with 16382
;     (and-mask the low 64 bits, or-in (16382<<64)) then bitcast i80→f80;
;   * the √2/2 centering hi = (m < SQRTH) ? 1 : 0 is the kjd1 fp-DATA select
;     controlled-copy merge at f80 → cqrt_copy_f80_controlled (a libm body mints
;     no Rz/Ry, so the fcmp-condition / const-arm accept shape applies), its |0>
;     flag rail stripped by fcmp_olt..._inv and freed.
;
; This is the top-level tainted path (the branchless body inlines into the taint
; seed, NOT a Phase-6 clone). The sinl/cosl twins are
; lowering_branchless_{sinl,cosl}_f80.ll.
;
; The --implicit-check-not guards are GLOBAL: NO Shadow memory survives the union
; promotion (`alloca`, `cqrt_qram`, a residual `store`/`load` instruction all
; absent → the split is register-only), no keep-set intrinsic CALL leaks, and no
; per-fn logl body is emitted.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s --implicit-check-not='call{{.*}}@llvm.' --implicit-check-not='cqrt_qram' --implicit-check-not='alloca' --implicit-check-not=' store ' --implicit-check-not='= load ' --implicit-check-not='cq_template_logl' < %t.cqd0.ll

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%union.anon = type { x86_fp80 }

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @branchless_logl_leaf(x86_fp80 %u) {
entry:
  %q    = call x86_fp80 @cq_theta_f80(x86_fp80 %u, double 5.000000e-01)
  ; --- frexp split via union IEEEl2bits (the SROA-promoted round-trip) ---
  %box  = alloca %union.anon, align 16
  store x86_fp80 %q, ptr %box, align 16
  %ep   = getelementptr inbounds i8, ptr %box, i64 8
  %ew   = load i64, ptr %ep, align 8
  %et   = trunc i64 %ew to i32
  %ex   = and i32 %et, 32767
  %e    = add nsw i32 %ex, -16382               ; exponent, frexp convention
  %clr  = and i64 %ew, -32768
  %set  = or disjoint i64 %clr, 16382           ; exp field := 16382
  %ep2  = getelementptr inbounds i8, ptr %box, i64 8
  store i64 %set, ptr %ep2, align 8
  %m    = load x86_fp80, ptr %box, align 16     ; mantissa in [0.5,1)
  ; --- √2/2 centering: constant-operand fp select (kjd1) ---
  %lt   = fcmp olt x86_fp80 %m, 0xK3FFEB504F333F9DE6484   ; SQRTH = 1/sqrt(2)
  %hi   = select i1 %lt, x86_fp80 0xK3FFF8000000000000000, x86_fp80 0xK00000000000000000000
  ; ef = (long double)e - hi ; a representative f + ef combination feeds measure
  %ef0  = sitofp i32 %e to x86_fp80
  %ef   = fsub x86_fp80 %ef0, %hi
  %fm1  = fadd x86_fp80 %m, 0xKBFFF8000000000000000       ; m - 1
  %val  = fadd x86_fp80 %ef, %fm1
  %r    = call x86_fp80 @cq_measure_f80(x86_fp80 %val)
  ret x86_fp80 %r
}

; The taint seed becomes an f80 allocation + Ry.
; CHECK: call i32 @cqrt_alloc_f80(x86_fp80 %u)
; CHECK: call void @cqrt_ry_f80(
; The union frexp split lowers to REGISTER-ONLY reversible bit surgery — no Shadow.
; CHECK: %[[BC:.*]] = call i32 @cq_template_bitcast_f80_to_i80(i32 %h)
; CHECK: %[[SHR:.*]] = call i32 @cq_template_lshr_i80_hl(i32 %[[BC]], i80 64)
; CHECK: %[[T16:.*]] = call i32 @cq_template_trunc_i80_to_i16(i32 %[[SHR]])
; CHECK: %[[Z64:.*]] = call i32 @cq_template_zext_i16_to_i64(i32 %[[T16]])
; CHECK: %[[T32:.*]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[Z64]])
; CHECK: %[[EX:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[T32]], i32 32767)
; CHECK: %[[E:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[EX]], i32 -16382)
; CHECK: %[[CLR:.*]] = call i32 @cq_template_and_i64_hl(i32 %[[Z64]], i64 -32768)
; CHECK: %[[SET:.*]] = call i32 @cq_template_or_i64_hl(i32 %[[CLR]], i64 16382)
; CHECK: %[[MAN:.*]] = call i32 @cq_template_and_i80_hl(i32 %[[BC]], i80 18446744073709551615)
; CHECK: %[[ZE80:.*]] = call i32 @cq_template_zext_i64_to_i80(i32 %[[SET]])
; CHECK: %[[SHL:.*]] = call i32 @cq_template_shl_i80_hl(i32 %[[ZE80]], i80 64)
; CHECK: %[[OR:.*]] = call i32 @cq_template_or_i80(i32 %[[MAN]], i32 %[[SHL]])
; CHECK: %[[MBC:.*]] = call i32 @cq_template_bitcast_i80_to_f80(i32 %[[OR]])
; The √2/2 select is the kjd1 controlled-copy merge; its flag rail is stripped+freed.
; CHECK: %[[FLG:.*]] = call i32 @cq_template_fcmp_olt_f80_hl(i32 %[[MBC]], x86_fp80 0xK3FFEB504F333F9DE6484)
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK: call void @cqrt_copy_f80_controlled(i32 %[[FLG]],
; CHECK: call void @cqrt_x(i32 %[[FLG]])
; CHECK: call void @cqrt_copy_f80_controlled(i32 %[[FLG]],
; CHECK: call void @cqrt_x(i32 %[[FLG]])
; CHECK: call void @cq_template_fcmp_olt_f80_hl_unc(i32 %[[FLG]], i32 %[[MBC]], x86_fp80 0xK3FFEB504F333F9DE6484)
; CHECK: call void @cqrt_free(i32 %[[FLG]])
; The exponent is carried to fp with sitofp i32->f80 (an i80->fp convert is unsupported).
; CHECK: call i32 @cq_template_sitofp_i32_to_f80(i32 %[[E]])
; CHECK: call x86_fp80 @cqrt_measure_f80(
