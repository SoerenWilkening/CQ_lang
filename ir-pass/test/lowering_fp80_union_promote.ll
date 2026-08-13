; lowering_fp80_union_promote.ll — bd 3c6m.51 ACCEPT: the x86_fp80 `union
; IEEEl2bits` bit-pattern idiom promotes. A tainted `store x86_fp80` + integer
; `load iN` at constant byte offsets (offset-0 low word direct; offset-8 exponent
; word via a `getelementptr i8`) is rewritten by promoteFp80Union to
; `bitcast x86_fp80 -> i80` + trunc (offset 0) / lshr+trunc+zext (offset 8, the
; padding-straddle word, padding modelled as 0 — SOUND because `and 32767` masks
; bits >= 16). The union store/loads/geps/alloca/lifetime markers are erased. This
; is the register-resident form SROA leaves in memory at -O1 (the offset-8 word
; straddles the undefined padding bytes [10,16)); the peephole finishes it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i64 @cq_measure_sll(i64)
declare void @llvm.lifetime.start.p0(i64, ptr)
declare void @llvm.lifetime.end.p0(i64, ptr)

define i64 @extract() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %u = alloca %union.IEEEl2bits, align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr %u)
  store x86_fp80 %q, ptr %u, align 16
  %lo = load i64, ptr %u, align 16                     ; offset 0 (bits [0,64))
  %man = and i64 %lo, 4294967295                       ; manl (low 32)
  %p8 = getelementptr inbounds i8, ptr %u, i64 8
  %hi = load i64, ptr %p8, align 8                     ; offset 8 (straddles padding)
  %exp = and i64 %hi, 32767                             ; masks bits >= 16 (padding) — SOUND
  call void @llvm.lifetime.end.p0(i64 16, ptr %u)
  %r = add i64 %man, %exp
  %m = call i64 @cq_measure_sll(i64 %r)
  ret i64 %m
}

; The union memory is fully promoted away and each word is an i80 relabel/extract.
; CHECK-NOT: alloca
; CHECK-NOT: store x86_fp80
; CHECK: call i32 @cq_template_bitcast_f80_to_i80
; CHECK-DAG: call i32 @cq_template_trunc_i80_to_i64
; CHECK-DAG: call i32 @cq_template_lshr_i80_hl
; CHECK-DAG: call i32 @cq_template_trunc_i80_to_i16
; CHECK-DAG: call i32 @cq_template_zext_i16_to_i64
; CHECK: call i64 @cqrt_measure_i64
; CHECK-NOT: error
