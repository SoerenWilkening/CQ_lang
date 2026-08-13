; lowering_fp80_union_rmw.ll — bd 3c6m.51 Inc 3 ACCEPT: the single-block LIVE-RMW
; fp80 union (`u.e = x; u.bits.exp = k; return u.e`) promotes. Inc 2 declined this
; shape OffPattern (live store-back → kMsgStore); Inc 3's canonicalize +
; PromoteMemToReg promotion rewrites the field-insert store-back as the register
; i80 pack (zext → shl → or into the and-cleared register) and the reload PACK as
; the `bitcast i80 -> x86_fp80` of the inserted value — the exact template stream
; pre-validated by lowering_fp80_i80_field_insert.ll. The straddle word's diverged
; bits [16,64) are KEPT by `and -32768` and stored back, but they land at storage
; bits [80,128) (>= 80, dropped into padding) and the reload never observes them —
; the widened §4.1 per-bit padding-taint walk proves this SOUND (the Inc-1
; everyUserMasksPadding fence would have declined the `and -32768` keep-mask).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @rmw() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca { x86_fp80 }, align 16
  store x86_fp80 %q, ptr %u, align 16
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %hi = load i64, ptr %p8, align 8              ; offset-8 straddle (RMW read)
  %exp = and i64 %hi, 32767                     ; extract exp field (clears padding)
  %k = add i64 %exp, 2                          ; new exponent
  %keep = and i64 %hi, -32768                   ; keep sign+junk (diverged bits KEPT)
  %fld = and i64 %k, 32767
  %w = or i64 %keep, %fld
  store i64 %w, ptr %p8, align 8                ; LIVE field-insert store-back
  %e = load x86_fp80, ptr %u, align 16          ; reload PACK (`return u.e`)
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %e)
  ret x86_fp80 %m
}

; The union memory is fully promoted away; the RMW becomes the i80 field-insert
; register pack and the reload the i80->f80 relabel.
; CHECK-NOT: alloca
; CHECK-NOT: store
; CHECK: call i32 @cq_template_bitcast_f80_to_i80
; CHECK-DAG: call i32 @cq_template_lshr_i80_hl
; CHECK-DAG: call i32 @cq_template_trunc_i80_to_i16
; CHECK-DAG: call i32 @cq_template_zext_i16_to_i64
; CHECK-DAG: call i32 @cq_template_add_i64_hl
; CHECK-DAG: call i32 @cq_template_or_i64
; CHECK: call i32 @cq_template_and_i80_hl
; CHECK-DAG: call i32 @cq_template_zext_i64_to_i80
; CHECK-DAG: call i32 @cq_template_shl_i80_hl
; CHECK: call i32 @cq_template_or_i80
; CHECK: call i32 @cq_template_bitcast_i80_to_f80
; CHECK: call x86_fp80 @cqrt_measure_f80
; CHECK-NOT: error
; CHECK-NOT: alloca
; CHECK-NOT: store x86_fp80
