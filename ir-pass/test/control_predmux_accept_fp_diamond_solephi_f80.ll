; control_predmux_accept_fp_diamond_solephi_f80.ll — ACCEPT (bd vyqi, W5): the
; x86_fp80 sibling of control_predmux_accept_fp_diamond_solephi.ll — the exact
; type of openlibm ld80 log10l's `z` accumulator. The kjd1 frozen family
; carries `cqrt_copy_f80_controlled`, so the flattened select lowers at f80
; with no new symbol.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi x86_fp80' < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @probe(x86_fp80 %u0) {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %c = fcmp olt x86_fp80 %q, 0xK3FFE8000000000000000
  br i1 %c, label %lo, label %hi
lo:
  %a = fadd x86_fp80 %q, 0xKBFFE8000000000000000
  br label %merge
hi:
  %b = fmul x86_fp80 %q, 0xK40008000000000000000
  br label %merge
merge:
  %zv = phi x86_fp80 [ %a, %lo ], [ %b, %hi ]
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %zv)
  ret x86_fp80 %m
}

; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f80_hl(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK:     call void @cqrt_copy_f80_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_copy_f80_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call x86_fp80 @cqrt_measure_f80(i32 %[[OUT]])
