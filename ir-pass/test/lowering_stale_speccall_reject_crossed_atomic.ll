; lowering_stale_speccall_reject_crossed_atomic.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 3 R3-1; OWNER RULING 2026-10-08, bd memory
; owner-ruling-gates-ordered-vs-volatile-atomic-2026-10-08).
;
;   #include <stdatomic.h>
;   _Atomic int ready;
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     atomic_store(&ready, 1);         // a seq_cst publication, after the gate
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; Gate emission is ordered against atomic events (CLAUDE.md R16: atomics stay
; observable). Placing the stale lifted call before the gate would move its gates
; above the `store atomic ... seq_cst` the source orders after the gate; the snapshot
; ed6d4c2e did (exit 0). The placement refuses (clause (d),
; `isObservableOrderedEvent`: an atomic on `@ready`, a global, is observable) and the
; stale fence declines. Twin:
; lowering_stale_speccall_reject_crossed_volatile.ll.
; RETIREMENT TRIGGER (L7): 57ch (B) flips this file to an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

@ready = local_unnamed_addr global i32 0, align 4

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  store atomic i32 1, ptr @ready seq_cst, align 4
  %3 = tail call i32 @f(i32 noundef %1)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %6 = add nsw i32 %5, %4
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
