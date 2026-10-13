; lowering_stale_speccall_reject_crossed_stale_nocapture_atomic.ll — DECLINE (bd
; test_C_libtooling-57ch.7, batch 053; the kill fixture of round-1 mutant M2).
; HAND IR: a callee parameter carries a STALE `nocapture` while the body publishes
; the pointer before its atomic.
;
;   int *seen;
;   void bump(int *p /* declared nocapture, wrongly */) {
;     seen = p; __atomic_fetch_add(p, 1, __ATOMIC_SEQ_CST); seen = 0;
;   }
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);
;     int a = 0; bump(&a);             // CROSSED
;     int r = f(q);                    // stale q
;     return (int)cq_measure(r) + (int)cq_measure(q2) + a;
;   }
;
; The 57ch.7 ruling admits an atomic in a callee on a pointer argument the callee
; does NOT capture that points at a never-escaping caller local. The caller-side
; test trusts the attribute: `PointerMayBeCaptured(%1)` in `main` reads the call's
; `nocapture` and calls `a` local. What refuses is the callee-side question,
; `PointerMayBeCaptured` asked of `bump`'s own argument, which walks the body and
; finds the store to `@seen`: the atomic may be visible outside, an observable
; ordered event, so the placement refuses and the stale fence declines. Asking only
; the attribute (round-1 mutant M2) makes this module accept.
; Accept twin (the parameter genuinely not captured):
; lowering_stale_speccall_crossed_arg_local_atomic_accept.ll; C-reachable decline
; twin (the attribute absent): lowering_stale_speccall_reject_crossed_arg_captured_atomic.ll.
; ⚠ CLASS (batch 053 round-1 F3): this module VIOLATES its own `nocapture` (the body
; stores the pointer), which is IR-level UB that `clang -O1` never emits; the
; shape is reachable only through hand IR or a stale attribute. It belongs with
; the r2j3 section-D latent holes (like r2j3.22, a forged `!cq.specsafe.twin`
; tag): the callee-side capture test keeps it loud, and this file pins that test.
; RETIREMENT TRIGGER (L7): 57ch (B) flips this file to an accept with a warning.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: in function main i32 (): cq opcode lowering: operand predates a non-diagonal gate

@seen = local_unnamed_addr global ptr null, align 8

define void @bump(ptr nocapture noundef %0) local_unnamed_addr #0 {
  store ptr %0, ptr @seen, align 8
  %2 = atomicrmw add ptr %0, i32 1 seq_cst, align 4
  store ptr null, ptr @seen, align 8
  ret void
}

define i32 @f(i32 noundef %0) local_unnamed_addr #1 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main() local_unnamed_addr #2 {
  %1 = alloca i32, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01) #3
  store i32 0, ptr %1, align 4
  call void @bump(ptr noundef nonnull %1)
  %4 = call i32 @f(i32 noundef %2)
  %5 = call i32 @cq_measure_si32(i32 noundef %4) #4
  %6 = call i32 @cq_measure_si32(i32 noundef %3) #4
  %7 = add nsw i32 %6, %5
  %8 = load i32, ptr %1, align 4
  %9 = add nsw i32 %7, %8
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nounwind willreturn }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }
