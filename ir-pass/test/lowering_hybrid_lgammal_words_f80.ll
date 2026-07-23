; lowering_hybrid_lgammal_words_f80.ll — ACCEPT (bd 20xt.8 Inc 4): the
; lowering-layer regression for the GET_LDOUBLE_WORDS 3-sub-word f80 union read
; — the fingerprint the HYBRID lgammal slice (tests/e2e/slice_hybrid_lgammal.c)
; adds on top of the three branchless leaves. The real openlibm ld80
; lgammal_r/sin_pi outer ladder decomposes x with
; `GET_LDOUBLE_WORDS(se, i0, i1, x)` = read THREE views of ONE x86_fp80 through a
; `union IEEEl2bits`: se = xbits.expsign (the 16-bit exp+sign at byte 8),
; i0 = bits.manh (high 32 mantissa), i1 = bits.manl (low 32) — then rebuilds the
; comparison key `ix = (se & 0x7fff) << 16 | (i0 >> 16)`. No existing leaf fixture
; covers this 3-word read (the blogl fixture reads+writes only the exponent).
;
; clang -O1 lowers that union read to an `alloca`+`store x86_fp80`+two `load i64`
; (offset 0 and offset 8) partial-overlap pattern that plain SROA does NOT
; promote (reproduced verbatim below). cq-lowering's promoteFp80Union MUST
; promote it to PURE register bit-surgery on the tainted f80 —
; cq_template_{bitcast,lshr,shl,trunc,zext,and,or}_i80/i64/i32 on register
; handles — with NO residual Shadow: NO alloca, NO qram, NO surviving
; `store`/`load` instruction, NO `@llvm.*` intrinsic call. The reconstructed key
; then feeds a representative constant/value fp select (the sin_pi
; `ix < 0x3ffd8000` fast-path guard) which lowers as the kjd1 fp-DATA controlled-
; copy merge (a libm body mints no Rz/Ry → fcmp-condition/const-arm accept shape):
; icmp flag → |0> out rail → two cqrt_copy_f80_controlled (¬flag cqrt_x-bracketed)
; → compare `_inv` strip → one cqrt_free.
;
; This is the top-level tainted path (the outer ladder inlines into the seed, NOT
; a Phase-6 clone). Leaf twins: lowering_branchless_{sinl,cosl,logl}_f80.ll.
;
; The --implicit-check-not guards are GLOBAL and NON-VACUOUS (red-green verified
; by injection): a residual alloca / store / load / qram / surviving @llvm.* call
; all go RED. opt must exit 0 (no decline) and the result must verify clean.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --implicit-check-not='call{{.*}}@llvm.' --implicit-check-not='cqrt_qram' --implicit-check-not='alloca' --implicit-check-not=' store ' --implicit-check-not='= load '
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%union.IEEEl2bits = type { x86_fp80 }

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @lgammal_words_probe() {
entry:
  %box = alloca %union.IEEEl2bits, align 16
  %q   = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  ; --- GET_LDOUBLE_WORDS(se, i0, i1, x): store f80, read the two i64 words ---
  store x86_fp80 %q, ptr %box, align 16
  %ep  = getelementptr inbounds i8, ptr %box, i64 8
  %ew  = load i64, ptr %ep, align 8          ; byte 8..15 → xbits.expsign in the low 16
  %se  = trunc i64 %ew to i32
  %lw  = load i64, ptr %box, align 16        ; byte 0..7 → manl(0..31) | manh(32..63)
  %i1  = trunc i64 %lw to i32                ; i1 = manl
  ; --- ix = (se & 0x7fff) << 16 | (i0 >> 16) ---
  %shl  = shl i32 %se, 16
  %ixm  = and i32 %shl, 2147418112           ; (se << 16) & 0x7FFF0000
  %i0hi = lshr i64 %lw, 48                    ; manh >> 16  (bits 48..63 of the low word)
  %i0t  = trunc i64 %i0hi to i32
  %ix   = or disjoint i32 %ixm, %i0t
  ; --- sin_pi fast-path guard select: (ix < 0x3ffd8000) ? x : (long double)(i1 & 1) ---
  %lt   = icmp ult i32 %ix, 1073577984
  %par  = and i32 %i1, 1
  %parf = uitofp i32 %par to x86_fp80
  %sel  = select i1 %lt, x86_fp80 %q, x86_fp80 %parf
  %r    = call x86_fp80 @cq_measure_f80(x86_fp80 %sel)
  ret x86_fp80 %r
}

; The seed becomes an f80 allocation + Ry.
; CHECK: call i32 @cqrt_alloc_f80(x86_fp80 0xK3FFE8000000000000000)
; CHECK: call void @cqrt_ry_f80(
; The union 3-word read promotes to REGISTER-ONLY reversible bit surgery — no Shadow.
; CHECK: %[[BC:.*]] = call i32 @cq_template_bitcast_f80_to_i80(i32 %h)
; se = xbits.expsign : the byte-8 word (lshr 64), narrowed to 16 then widened back.
; CHECK: %[[SHR:.*]] = call i32 @cq_template_lshr_i80_hl(i32 %[[BC]], i80 64)
; CHECK: %[[E16:.*]] = call i32 @cq_template_trunc_i80_to_i16(i32 %[[SHR]])
; CHECK: %[[EZ:.*]] = call i32 @cq_template_zext_i16_to_i64(i32 %[[E16]])
; CHECK: %[[SE:.*]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[EZ]])
; the low word = manl|manh : trunc i80→i64 then the two field extractions.
; CHECK: %[[LW:.*]] = call i32 @cq_template_trunc_i80_to_i64(i32 %[[BC]])
; CHECK: %[[I1:.*]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[LW]])
; CHECK: %[[SHL:.*]] = call i32 @cq_template_shl_i32_hl(i32 %[[SE]], i32 16)
; CHECK: %[[IXM:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[SHL]], i32 2147418112)
; CHECK: %[[I0HI:.*]] = call i32 @cq_template_lshr_i64_hl(i32 %[[LW]], i64 48)
; CHECK: %[[I0T:.*]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[I0HI]])
; CHECK: %[[IX:.*]] = call i32 @cq_template_or_i32(i32 %[[IXM]], i32 %[[I0T]])
; i1 & 1 → uitofp i32→f80 (the word-derived select value).
; CHECK: %[[PAR:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[I1]], i32 1)
; CHECK: %[[PARF:.*]] = call i32 @cq_template_uitofp_i32_to_f80(i32 %[[PAR]])
; the key compare is the kjd1 select flag; its |0> rail is stripped + freed.
; CHECK: %[[FLG:.*]] = call i32 @cq_template_icmp_ult_i32_hl(i32 %[[IX]], i32 1073577984)
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK: call void @cqrt_copy_f80_controlled(i32 %[[FLG]],
; CHECK: call void @cqrt_x(i32 %[[FLG]])
; CHECK: call void @cqrt_copy_f80_controlled(i32 %[[FLG]],
; CHECK: call void @cqrt_x(i32 %[[FLG]])
; CHECK: call i32 @cq_template_icmp_ult_i32_hl_inv(i32 %[[IX]], i32 1073577984)
; CHECK: call void @cqrt_free(i32 %[[FLG]])
; CHECK: call x86_fp80 @cqrt_measure_f80(
