; lowering_stale_speccall_reject_memory_conflict.ll — DECLINE (bd
; test_C_libtooling-r2j3.6): a stale lifted call that may READ memory, with a STORE
; between the staling gate and the call. Hand IR (no C spelling: a lifted callee may
; not load mutable memory, `scanBody`'s `memory access` reject, and -O1 gives a callee
; that reads only constant tables `memory(none)`); the subject is the placement's
; memory clause, asked from the call's own effect summary (`memory(read)` here).
;
; Moving the call above the store could change what it reads, so the 57ch (A)
; placement refuses (a read may not cross a write; a write may not cross any access —
; the array-order rule of 57ch (A), conservatively over all memory), and the stale
; fence declines with its one string.
; MUTANT KILLED: a placement without the memory clause moves the call and accepts.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (i32): cq opcode lowering: operand predates a non-diagonal gate

@G = global i32 0, align 4

define i32 @f(i32 noundef %x) local_unnamed_addr #0 {
  %m = mul nsw i32 %x, 3
  %r = add nsw i32 %m, 1
  ret i32 %r
}

define i32 @main(i32 noundef %a) local_unnamed_addr #1 {
  %q = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %q2 = tail call i32 @cq_theta_si32(i32 noundef %q, double noundef 3.000000e-01) #2
  store i32 %a, ptr @G, align 4
  %r = tail call i32 @f(i32 noundef %q)
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %r) #3
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %q2) #3
  %s = add nsw i32 %m2, %m1
  ret i32 %s
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(read) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
