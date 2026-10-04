/* slice_loop_break_qram_index_i64.c — bd test_C_libtooling-01po.3. The i64-rail
   Q==Q value-arm `break` of slice_loop_break_qq_i64.c whose escaping answer then
   SUBSCRIPTS a const table (a QROM read at a quantum index):

       long long p = cq_theta(pseed, 0.5);
       long long q = cq_theta(seed, 0.25);
       for (int i = 0; i < n; i++) {
           q = q ^ 5;                       // in-place i64 value rail
           if (q == p) break;               // TAINTED i64 Q==Q break flag
       }
       return cq_measure(tbl[q]);           // i64 break answer as the QRAM index

   The break's answer is the pass-minted `cq.brk.out` rail (cqrt_alloc_i64). The
   runtime contract (runtime/cq_runtime.h, QRAM preamble) fixes every QRAM index at
   LOGICAL width 32, so the load must be bracketed by the per-call
   `cq_template_trunc_i64_to_i32` + `_unc` + `cqrt_free`. Before the fix the break
   rails carried no `HandleWidth` record and the 64-bit rail went to
   `cqrt_qram_load_i32` as the index unbracketed.

   WHY THIS IS THE RIGHT LAYER: the lit fixture
   lowering_loop_break_qram_index_i64.ll pins the IR; this golden is the only layer
   that LINKS the composed break + QROM + bracket path (every symbol must resolve
   against the runtime) and shows the bracket's place in the trace: after the
   break's exit consolidation copied the answer into `out` and after the
   reverse-play freed R/idx, immediately around the load.

   The bound `n` is a runtime 4 for a deterministic trace; ZERO measurements
   inserted; `noinline` keeps the function boundary. */
static const int tbl[8] = {10, 11, 12, 13, 14, 15, 16, 17};

__attribute__((noinline))
int run(long long seed, long long pseed, int n) {
    long long p = pseed; cq_theta(&p, 0.5); /* 64-bit loop-invariant qubit */
    long long q = seed; cq_theta(&q, 0.25);
    for (int i = 0; i < n; i++) {
        q = q ^ 5;                          /* in-place i64 value rail self-update */
        if (q == p)                         /* TAINTED i64 Q==Q break flag */
            break;
    }
    return cq_measure(tbl[q]);              /* i64 break answer as a QRAM index */
}
int main(void) { (void) run(3, 7, 4); return 0; }
