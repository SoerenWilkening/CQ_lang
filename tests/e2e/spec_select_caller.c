/* spec_select_caller.c — the CQ translation unit for the Phase 6 / issue 5po2
   golden: a plain C function with IN-BODY CONTROL lifted into a reversible
   quantum clone. Mirrors specialize_caller's quantum core (theta -> helper ->
   phase -> measure) but the helper `foo` (spec_select_lib.c) contains a tainted
   `select` — `foo(b) = (b<5)?b:0`, the clang -O1 lowering of `if(b<5) a+=b`.

   Because `b` is TAINTED when it reaches `foo(b)`, the specializer lifts `foo`
   into `__cq_q_foo_1`, emitting the select as a 4.4 controlled-XOR copy
   `out = flag ? b : 0` and Bennett-wrapping it (compute -> copy-out -> reverse:
   the self-inverse controlled copy zeroes the out rail, the compare `_unc`
   zeroes the flag -> free both scratch rails). The borrowed quantum input `b` is
   preserved (read-only) and left allocated (a safe leak, Rule 6) — never freed
   dirty. This is the ONLY layer that LINK-proves @__cq_q_foo_1 +
   cqrt_copy_i32_controlled + the compare `_unc` twin resolve and signature-match
   across llvm-link. `foo` is DECLARED (not defined) here, so opt sees an
   un-inlined callee body (Rule 9). */
int foo(int b);

int slice(void) {
    int b = 3;
    b = cq_theta(b, 0.5);
    int a = foo(b);
    a = cq_phi(a, 3.14);
    int z = cq_measure(a);
    return z;
}

int main(void) { (void) slice(); return 0; }
