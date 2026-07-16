; lowering_fp80_union_crossunion.ll — bd 3c6m.51 Inc 3 ACCEPT: the copysignl
; two-union skeleton. `ux` is seeded with a CLASSICAL constant (huge) and takes a
; field-insert whose inserted sign bit comes from the TAINTED sibling union `uy`
; (a cross-union word flow); `uy` is a tainted read-only extraction union. The
; promotion handles multiple concurrent union allocas in one function: uy's word
; extracts to the i80 read surface, ux's constant half constant-folds at emission,
; and the insert lowers as a mixed classical/tainted i80 or. The diverged straddle
; bits of BOTH unions land at >= 80 or are masked — sound under the §4.1 walk.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %cq-opt -passes=verify -S %t.ll -o /dev/null

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @cpsgn() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %ux = alloca { x86_fp80 }, align 16
  %uy = alloca { x86_fp80 }, align 16
  store x86_fp80 0xK3FFF8000000000000000, ptr %ux, align 16  ; classical seed (1.0L)
  store x86_fp80 %q, ptr %uy, align 16                       ; tainted seed
  %py8 = getelementptr inbounds i8, ptr %uy, i64 8
  %sy = load i64, ptr %py8, align 8              ; uy straddle read (sign word)
  %sbit = and i64 %sy, 32768                     ; uy.bits.sign
  %px8 = getelementptr inbounds i8, ptr %ux, i64 8
  %sx = load i64, ptr %px8, align 8              ; ux straddle read (RMW)
  %mag = and i64 %sx, -32769                     ; clear ux sign bit
  %w = or i64 %mag, %sbit                        ; cross-union insert word
  store i64 %w, ptr %px8, align 8                ; ux field-insert
  %e = load x86_fp80, ptr %ux, align 16          ; ux.e reload
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %e)
  ret x86_fp80 %m
}

; CHECK-NOT: alloca
; CHECK-NOT: store
; CHECK: call i32 @cq_template_bitcast_f80_to_i80
; CHECK-DAG: call i32 @cq_template_and_i64_hl
; CHECK-DAG: call i32 @cq_template_or_i64
; CHECK-DAG: call i32 @cq_template_zext_i64_to_i80
; CHECK-DAG: call i32 @cq_template_or_i80
; CHECK: call i32 @cq_template_bitcast_i80_to_f80
; CHECK: call x86_fp80 @cqrt_measure_f80
; CHECK-NOT: error
; CHECK-NOT: alloca
; CHECK-NOT: store x86_fp80
