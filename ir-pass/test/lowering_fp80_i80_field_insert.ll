; lowering_fp80_i80_field_insert.ll — bd 3c6m.51 Inc 2 ACCEPT: the i80 field-insert
; (WRITE) surface the promoteFp80Union RMW pack needs. Inc 1 shipped the i80 read
; ops (bitcast f80->i80, lshr, trunc-from-i80, and); Inc 2 adds the three write ops
; the `u.bits.exp = k; return u.e` PACK emits as a register field-insert:
;   `zext iN -> i80` (widen the store-back word), `shl i80` (move it to bits
;   [off*8,80)), `or i80` (OR it into the cleared register). This fixture is the
; hand-promoted single-block RMW form — exactly what next session's multi-block
; `canonicalize + PromoteMemToReg` promotion will emit — so it double-validates the
; template stream lowers + verifies clean, with NO decline. The union-promotion
; ACCEPT predicate itself is NOT yet broadened (this session ships only the width
; surface); this pins the register-resident WRITE path the way lowering_bitcast_
; f80_i80.ll pinned the READ path.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

; The register form of `u.e = x; k = u.bits.exp; u.bits.exp = k & 0x7fff; return u.e`
; (padding [80,128) modelled 0, sound under the mask fence — enforced next session).
define x86_fp80 @field_insert() {
entry:
  %q  = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %bc = bitcast x86_fp80 %q to i80              ; V0 (read surface, Inc 1)
  ; extract the offset-8 exp|sign word (bits [64,80) meaningful, padding zeroed):
  %sh = lshr i80 %bc, 64
  %w16 = trunc i80 %sh to i16
  %w  = zext i16 %w16 to i64
  %nf = and i64 %w, 32767                        ; new field value (15-bit exp mask)
  ; field-insert into bits [64,80) of the i80 register (write surface, Inc 2):
  %iz = zext i64 %nf to i80                      ; NEW: cq_template_zext_i64_to_i80
  %is = shl i80 %iz, 64                          ; NEW: cq_template_shl_i80_hl
  %im = and i80 %is, 1208907372870555465154560   ; mask = 0xFFFF<<64 (bits [64,80))
  %clr = and i80 %bc, 18446744073709551615       ; ~mask = bits [0,64) (clear field)
  %v1 = or i80 %clr, %im                         ; NEW: cq_template_or_i80
  %f  = bitcast i80 %v1 to x86_fp80              ; the PACK / reload (read surface)
  %m  = call x86_fp80 @cq_measure_f80(x86_fp80 %f)
  ret x86_fp80 %m
}

; CHECK: call i32 @cqrt_alloc_f80
; CHECK: call void @cqrt_ry_f80
; CHECK: call i32 @cq_template_bitcast_f80_to_i80
; CHECK: call i32 @cq_template_lshr_i80
; CHECK: call i32 @cq_template_trunc_i80_to_i16
; CHECK: call i32 @cq_template_zext_i16_to_i64
; CHECK: call i32 @cq_template_zext_i64_to_i80
; CHECK: call i32 @cq_template_shl_i80
; CHECK: call i32 @cq_template_and_i80
; CHECK: call i32 @cq_template_or_i80
; CHECK: call i32 @cq_template_bitcast_i80_to_f80
; CHECK: call x86_fp80 @cqrt_measure_f80
; CHECK-NOT: error
