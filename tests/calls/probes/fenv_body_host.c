/* cq-rrc52 (CR rule 16): a body the bundle has for fesetround (musl's src/fenv/fesetround.c shape over a no-op
   __fesetround) is never lifted for the call: the call is rule 23's, a rail operation on the quantum mode. */
__attribute__((noinline)) int __fesetround(int r) { (void)r; return 0; }
__attribute__((noinline)) int fesetround(int r) { if (r & ~0xc00) return -1; return __fesetround(r); }
int e(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    return cq_measure(fesetround(x));
}
