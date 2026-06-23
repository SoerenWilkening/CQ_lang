; lowering_reject_qram_heap.ll — DECLINE (Phase 7.5 Inc 3, the §2.8(iv)
; pattern-naming decline matrix): a tainted-index access into HEAP memory (the gep
; base is a `@malloc` result). A managed reversible memory needs a KNOWN compile-
; time shape (width × count) — Bennett's load-bearing precondition (§0) — but a heap
; block's shape is a runtime value; reversibility is impossible (no-cloning /
; linearity, [[pointer-boundary-linearity-bennett]]). The provenance walk hits the
; allocator call and loud-declines NAMING the heap origin (needs the post-freeze
; Persistent-DS strategy; §5). The realistic clang -O1 shape for `malloc(...)[q]`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare noalias ptr @malloc(i64)
declare i32 @cq_theta_si32(i32, double)

define i32 @heap(i32 %u0) {
entry:
  %m = call noalias ptr @malloc(i64 32)        ; heap block — runtime shape
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds i32, ptr %m, i64 %i
  %v = load i32, ptr %g, align 4
  ret i32 %v
}

; CHECK: error{{.*}}cq QRAM access: array has no compile-time shape (heap allocation)
