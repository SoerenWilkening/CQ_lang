; lowering_reject_f16_return.ll — Phase 7.1 Increment D: a tainted `half` RETURN
; declines. Now that f16 is a recognized width, a live tainted half can reach a
; `ret half`; but the runtime handle is ALWAYS i32 (RotationLowering RAUWs every
; tainted value to its i32 alloc handle), and a `ret` is never erased, so
; returning a tainted value at a non-i32 width would leave `ret half <i32
; handle>` — a broken module. The kMsgNonI32Return gate declines pre-RAUW
; (TaintPropagation.cpp), converting that abort into a clean source-located
; decline. i32-width tainted rets stay accepted; a measured (classical) half
; return is untouched (lowering_measure_f16.ll covers that ACCEPT).
;
; bd p3kd.21 / bd jx32 (2026-10-14) — NOW AN ACCEPT; the file name and the
; DECLINE text above are history. The function has no in-module use (an entry
; point / export, `declineQuantumReturnCalls`' Escaped contract), so its non-i32
; tainted `ret` returns the register's i32 runtime HANDLE: the return is
; re-declared `i32` after lowering (`retypeQuantumExportReturns`,
; SpecializeGateInline.h) and the verifier-abort hazard described above cannot
; arise (a `ret` still carrying a non-i32 value there fails loudly with the same
; non-i32 string). The gate stream is the one the i32-typed twin of the same body
; emits (measured on the value diamond: identical, call for call; the twin's arm
; chain is left allocated exactly as there). The non-i32 decline remains for a
; function WITH an in-module use: spec_reject_gate_sub_indirect_nonI32.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(half %s)
; CHECK: [[R:%[a-z0-9_.]+]] = call i32 @cq_template_fadd_f16_hl(
; CHECK-NEXT: ret i32 [[R]]

declare half @cq_theta_f16(half, double)

define half @example(half %s) {
entry:
  %a = call half @cq_theta_f16(half %s, double 5.000000e-01)
  %b = fadd half %a, 0xH3C00
  ret half %b
}
