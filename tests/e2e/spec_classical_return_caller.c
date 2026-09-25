/* spec_classical_return_caller.c — bd test_C_libtooling-9bhg e2e smoke: a function
   that RETURNS a specialization-classical call result, read by its caller, through
   the full multi-TU pipeline (clang -O1 per TU -> llvm-link -> opt cq-lowering ->
   link -> run; the ONLY layer that LINKS, Rule 2/16).

   `f` returns `t + cq_measure(q)` with `t = h(q, m)`: `h(q, m)` is a Phase-6 site
   whose clone `__cq_q_h_01` proves the classical `k + 1`, so `f` returns a
   CLASSICAL integer. bd 3jru's refusal (`quantum value returned across a function
   boundary`) ran on the pre-specialize conservative taint and declined this module
   on 983f9361; bd 9bhg does not let that provisional taint cross `f`'s return and
   re-asks the refusal after `specialize()`.

   TRACE CONTRACT (analytically audited): `main` rotates its own register `q2`
   (`cqrt_alloc_i32(5) -> h0` + `cqrt_ry_i32`), then calls `f(3)`, which rotates
   `q` (`cqrt_alloc_i32(3) -> h1` + `cqrt_ry_i32`), passes it to the classical
   clone (no gate — the clone ignores it), and measures it (`cqrt_measure_i32`,
   which the trace runtime answers 0). `f` returns 4 + 0 = 4, a CLASSICAL value,
   and `main`'s `q2 + f(3)` is therefore a MIXED add with the value 4 as its
   literal — lowered IN PLACE (M-C, `q2` is dead after it) as
   `cqrt_addc_i32(h0, 4)`. The literal 4 IS the witness: had the provisional taint
   crossed `f`'s return, the call result would have been a "handle" and the add a
   Q+Q add over the integer 4 used as a register id. The sum is measured; neither
   rail is freed (one is measured, the other Ry'd and borrowed — Rule 6). */
int h(int a, int k);

__attribute__((noinline)) int f(int m) {
    int q = cq_theta(m, .5);
    int t = h(q, m);
    return t + cq_measure(q);
}

int main(void) {
    int q2 = cq_theta(5, .25);
    int s = q2 + f(3);
    (void) cq_measure(s);
    return 0;
}
