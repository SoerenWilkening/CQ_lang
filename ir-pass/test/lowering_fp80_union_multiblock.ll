; lowering_fp80_union_multiblock.ll — bd 3c6m.51 Inc 3 ACCEPT: the MULTI-BLOCK
; fp80 union (the scalbnl skeleton, compacted): one union alloca threaded across
; four blocks — seed store in entry, an fp80 RE-SEED (`u.e *= 0x1p+128`) plus a
; second straddle read in the subnormal arm, and a shared field-insert PACK +
; reload after the tainted merge. canonicalize + PromoteMemToReg rewrites every
; access to a full-width x86_fp80 load/store on a fresh promotable alloca and
; lets LLVM's own mem2reg build the merge phi (`phi x86_fp80` — NEVER an i80
; phi; the i80 extract/insert stays intra-block). PredMux then claims the
; tainted diamond (two merge phis: the i64 exponent + the mem2reg f80 value),
; flattens it to selects, and the kjd1 fp-select copy family lowers the f80
; merge via cqrt_copy_f80_controlled — the same downstream that already carries
; scalbn.f64.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @mb() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca %union.IEEEl2bits, align 16
  store x86_fp80 %q, ptr %u, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %hi = load i64, ptr %p8, align 8              ; straddle read #1
  %exp = and i64 %hi, 32767
  %c0 = icmp eq i64 %exp, 0                     ; tainted condition
  br i1 %c0, label %sub, label %norm

sub:                                            ; subnormal: rescale + re-extract
  %e0 = load x86_fp80, ptr %u, align 16
  %e1 = fmul x86_fp80 %e0, 0xK407F8000000000000000   ; u.e *= 0x1p+128
  store x86_fp80 %e1, ptr %u, align 16          ; fp80 RE-SEED in a non-entry block
  %hi2 = load i64, ptr %p8, align 8             ; straddle read #2
  %x2 = and i64 %hi2, 32767
  %k2 = add i64 %x2, 128
  br label %ins

norm:
  %k1 = add i64 %exp, 2
  br label %ins

ins:                                            ; shared field-insert + reload
  %k = phi i64 [ %k2, %sub ], [ %k1, %norm ]
  %hi3 = load i64, ptr %p8, align 8             ; RMW read
  %keep = and i64 %hi3, -32768
  %fld = and i64 %k, 32767
  %w = or i64 %keep, %fld
  store i64 %w, ptr %p8, align 8                ; field-insert store-back
  %e = load x86_fp80, ptr %u, align 16          ; reload (`return u.e`)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %e)
  ret x86_fp80 %m
}

; Promoted + flattened + lowered: no memory, no branches survive; the f80 merge
; goes through the kjd1 controlled-copy family and the RMW pack through the i80
; write surface.
; CHECK-NOT: alloca
; CHECK-NOT: store
; CHECK: call i32 @cq_template_bitcast_f80_to_i80
; CHECK-DAG: call i32 @cq_template_fmul_f80_hl
; CHECK-DAG: call void @cqrt_copy_f80_controlled
; CHECK-DAG: call i32 @cq_template_zext_i64_to_i80
; CHECK-DAG: call i32 @cq_template_shl_i80_hl
; CHECK-DAG: call i32 @cq_template_or_i80
; CHECK: call i32 @cq_template_bitcast_i80_to_f80
; CHECK: call x86_fp80 @cqrt_measure_f80
; CHECK-NOT: error
; CHECK-NOT: alloca
; CHECK-NOT: store x86_fp80
