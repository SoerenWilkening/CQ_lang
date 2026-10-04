/* slice_loop_value_accum.c — issue dtzb (the in-place reversible arithmetic
   strategy). The VALUE twin of slice_loop_phase_accum: a classically-bounded
   loop over an in-place-mutated VALUE rail `q = q ^ 9`. Today (7.3) this is the
   X1 cross-iteration dirty rail (a fresh out-of-place template handle per
   iteration) and LOUD-declines. dtzb recognizes the loop-rail self-update and
   lowers it IN PLACE — one rail handle, `cqrt_xorc_i32(h0, 9)` rolled in the
   body (the value analogue of Case A's `cqrt_rz` accumulator), the loop-carried
   header phi + zero-trip/exit merge phi collapse to the single rail, ZERO
   uncompute, ZERO measurements inserted. The golden trace (running the rolled
   loop a FIXED 4 times) is BYTE-IDENTICAL to the manually-unrolled 4×cqrt_xorc
   form — Bennett.jl's in-place adder, src/adder.jl: the result overwrites the
   rail in place rather than minting a fresh wire.

   The bound `n` is a RUNTIME parameter (the harder shape: clang -O1 emits the
   zero-trip guard + the exit merge phi), passed a fixed 4 from main so the trace
   is deterministic. `noinline` keeps the function boundary so clang -O1 lowers
   the rolled loop directly. cq_theta/cq_measure resolve from CQ.h, force-included
   by run_slice.sh. */
__attribute__((noinline))
int accum(int seed, int n) {
    int q = seed; cq_theta(&q, 0.25);
    for (int i = 0; i < n; i++)
        q = q ^ 9;               /* in-place reversible self-update (xor const) */
    return cq_measure(q);
}
int main(void) { (void) accum(3, 4); return 0; }
