; control_swap_select_f80.ll — ACCEPT: the f80 (x86_fp80 long double) fp-DATA
; select, the §5 scope-widening edge (fp-data-select-PRD §2: §16.4 staged only
; {f32,f64}; this increment un-stages {f16,f32,f64,f80} on the strength of the
; existing cqrt_alloc_f80 + f80 rotation/measure ABI and the slice_f80 e2e host
; precedent — x86_64 with real x86_fp80). The §6 f80-edge lens: an 80-bit rail
; allocs/copies/frees through the SAME width-parametric six-step merge; the
; width tags only the symbol name (all handles i32, Rule 15).
;
; The classical false operand `%x` is materialized via `cqrt_alloc_f80` (the
; 4.4 copy-merge carve-out extended to fp). 0xK4001A000000000000000 = 5.0.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=UNC %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @example(x86_fp80 %u0, x86_fp80 %x) {
entry:
  %q   = call x86_fp80 @cq_theta_f80(x86_fp80 %u0, double 5.000000e-01)
  %c   = fcmp ogt x86_fp80 %q, 0xK4001A000000000000000     ; tainted condition
  %sel = select i1 %c, x86_fp80 %q, x86_fp80 %x            ; f80 DATA mux
  %m   = call x86_fp80 @cq_measure_f80(x86_fp80 %sel)      ; data sink
  ret x86_fp80 %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 %u0)
; CHECK:     call void @cqrt_ry_f80(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f80_hl(i32 %[[Q]], x86_fp80 0xK4001A000000000000000)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
; CHECK:     call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f80(x86_fp80 %x)
; CHECK:     call void @cqrt_copy_f80_controlled(i32 %[[F]], i32 %[[XH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_fcmp_ogt_f80_hl_unc(i32 %[[F]], i32 %[[Q]], x86_fp80 0xK4001A000000000000000)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call x86_fp80 @cqrt_measure_f80(i32 %[[OUT]])
; bd `8txa`: the flag STRIP is itself a `_unc` now, so the pre-8txa blanket
; `CHECK-NOT: _unc` cannot be restored verbatim. Pin the exact population
; instead — EXACTLY ONE `_unc` call in the module, and it is the compare
; strip. Strictly stronger than the blanket form for the double-strip case
; (a second strip on an already-freed rail is a UAF + wrong unitary), and
; it still forbids any DATA uncompute (that would be a second `_unc` call).
; UNC-COUNT-1: call void @cq_template_{{[if]}}cmp_{{[a-zA-Z0-9_]+}}_unc(
; UNC-NOT:     call {{.*}}_unc(
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_copy_i
