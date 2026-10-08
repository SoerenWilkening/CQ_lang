; lowering_stale_speccall_reject_volatile_operand.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 2 R2-1: the round-1 snapshot 8c517ac4
; silently REORDERED a volatile read above a gate).
;
;   volatile int status_reg;
;   __attribute__((noinline)) int f(int x, int k) { return x * 3 + k; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int r = f(q, status_reg * 3);    // stale q + a VOLATILE read after the gate
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; A volatile access to an externally visible object is observable (CLAUDE.md R16):
; an event ordered against the gate stream, which clang keeps after the theta and
; LLVM would not move across it (the theta's memory effects are unknown to LLVM).
; Carrying it to the placement slot reorders the two events, so the placement
; refuses a carried operand that is an observable ordered event
; (StaleReadPlacement.cpp `carriableEffects`: `isObservableOrderedEvent` false, and a
; call only if `callCrossable`; since review round 5 a carried call may read and
; write ordinary memory, its conflicts being clause (e)'s), and the stale fence
; declines. A volatile access is always observable. Consistent with
; the OWNER RULING 2026-10-08 (bd memory
; owner-ruling-gates-ordered-vs-volatile-atomic-2026-10-08: gate emission is ordered
; against volatile, atomic and fence events in both directions); this file is the
; "event moved above the gates" direction, lowering_stale_speccall_reject_crossed_
; volatile.ll / _crossed_atomic.ll the "gates moved above the event" one.
; RETIREMENT TRIGGER (L7): 57ch (B) (a kept pre-gate snapshot, the read left in
; place) flips this file to an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

@status_reg = global i32 0, align 4

define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = mul nsw i32 %0, 3
  %4 = add nsw i32 %3, %1
  ret i32 %4
}

define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %3 = load volatile i32, ptr @status_reg, align 4
  %4 = mul nsw i32 %3, 3
  %5 = tail call i32 @f(i32 noundef %1, i32 noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #3
  %7 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
