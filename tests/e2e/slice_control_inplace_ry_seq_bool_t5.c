/* slice_control_inplace_ry_seq_bool_t5.c — THE REPORTER'S t5.c (bd dm7f.53, CQ_FINDINGS F3).

   Two controlled-Ry regions on ONE `_Bool` under complementary quantum
   conditions: the natural spelling of "the rotation angle depends on a
   quantum counter" (Dicke: `for v: if (c == v) cq_theta(&q, ang(v))`). It
   declined `value-arm swap-route under quantum control` because -O1 keeps a
   `_Bool` written by two diamonds in an `i8` storage-width phi web
   (`trunc`/`zext` around each arm theta); `narrowBoolStoragePhis` restores the
   `i1` spelling -O1 uses for one diamond, and both regions then lower as the
   shipped in-place controlled Ry on q1's ONE rail. Harness edit only:
   `main` -> `slice`, `printf` -> the returned sum.

   READ THE GOLDEN:
      1-2   q0's rail + Ry(1.0).
      3-4   q1's rail, minted |0>, Ry(.3) UNCONDITIONALLY ...
      5     ... then Ry(-.3) controlled by q0: region 1 is `if (c == 0)`, i.e.
            the ANTI-control, spelled by Ry additivity (never a `cqrt_x` on a
            user register).
      6     Ry(.7) controlled by q0 — region 2, `if (c == 1)`, on the SAME rail.
      7-8   the two measurements.
   Analytic: q0=0: Ry(.3)|0> = cos(.15)|0>+sin(.15)|1>; q0=1: Ry(.3-.3+.7) =
   Ry(.7)|0> = cos(.35)|0>+sin(.35)|1>. No ancilla, no free; both user rails
   left allocated (Rule 5). */
int slice(void) {
    _Bool q0 = 0, q1 = 0;
    int c = 0;
    cq_theta(&q0, 1.0);
    c += q0;
    if (c == 0) cq_theta(&q1, 0.3);
    if (c == 1) cq_theta(&q1, 0.7);
    return (int) cq_measure(q0) + (int) cq_measure(q1);
}
int main(void) { (void) slice(); return 0; }
