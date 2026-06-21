; lowering_reject_io_store_pointer.ll — DECLINE (Phase 7.6 boundary): coherent
; string output (`puts` / `printf("%s")`) is OUT of scope. Taint never lives on a
; pointer; the only way a quantum value reaches a `%s` print is by being STORED
; into a buffer first — which declines UPSTREAM at the store guard (`kMsgStore`),
; before the print. The 7.6 `printf` carve does not touch stores, so this still
; declines. Coherent string output is a reversible-memory problem owned by Phase
; 7.5, not 7.6.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @printf(ptr, ...)
@.s = private constant [3 x i8] c"%s\00"
@buf = global [8 x i8] zeroinitializer

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  store i32 %q, ptr @buf
  %r = call i32 (ptr, ...) @printf(ptr @.s, ptr @buf)
  ret void
}

; CHECK: error{{.*}}cq taint escape: tainted value stored to memory
