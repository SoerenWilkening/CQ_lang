; lowering_stale_speccall_reject_crossed_atomic_helper.ll — DECLINE (bd
; test_C_libtooling-r2j3.6, review round 4 R4-1; OWNER RULING 2026-10-08, bd memory
; owner-ruling-gates-ordered-vs-volatile-atomic-2026-10-08).
;
;   int calls;
;   __attribute__((noinline)) void tick(void) {
;     __atomic_fetch_add(&calls, 1, __ATOMIC_RELAXED);    // a MONOTONIC atomic
;   }
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     tick();
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + calls;
;   }
;
; The twin of lowering_stale_speccall_crossed_helper_accept.ll with the increment
; made a relaxed (monotonic) atomic. The ruling covers "an atomic access" of any
; ordering, and LLVM's `nosync` admits a monotonic one, so the crossing test reads
; the helper's visible body (`callCrossable`: `isObservableOrderedEvent` on
; `atomicrmw ... monotonic` to `@calls`, a global) and refuses; the stale fence
; declines. `@tick`'s `nosync` is HAND-ADDED (clang -O1
; does not infer it here; LangRef permits it beside a monotonic atomic), so a
; crossing test that trusted `nosync` for a visible body would accept this file.
; RETIREMENT TRIGGER (L7): 57ch (B) flips this file to an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

@calls = global i32 0, align 4

define void @tick() local_unnamed_addr #0 {
  %1 = atomicrmw add ptr @calls, i32 1 monotonic, align 4
  ret void
}

define i32 @f(i32 noundef %0) local_unnamed_addr #1 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main() local_unnamed_addr #2 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #3
  tail call void @tick()
  %3 = tail call i32 @f(i32 noundef %1)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %5 = tail call i32 @cq_measure_si32(i32 noundef %2) #4
  %6 = add nsw i32 %5, %4
  %7 = load i32, ptr @calls, align 4
  %8 = add nsw i32 %6, %7
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
