/* slice_i128_mulhi.c — Phase 7.1 follow-up n0ui (Tier-1) e2e link proof: a
   128-bit INTERMEDIATE round-trips with NO new core ABI. The classic widening
   "mulhi": square a quantum unsigned long and observe the high 64 bits of the
   128-bit product.

   clang -O1 keeps the source/sink at i64 (clean ABI: cq_theta_sll/cq_measure_sll)
   and emits the 128-bit work as single clean ops:
     zext i64 -> i128 ; mul i128 ; lshr i128, 64 ; trunc i128 -> i64
   all lowered to the FROZEN cq_template_*_i128 producers — there is NO
   cqrt_alloc_i128 / cqrt_measure_i128 / cqrt_copy_i128 (the i128 SOURCE/SINK
   __int128 {i64,i64} ABI shred is Tier-2, deferred). This is the ONLY layer that
   LINKS, so the only proof that cq_template_zext_i64_to_i128 / mul_i128 /
   lshr_i128_hl / trunc_i128_to_i64 resolve and signature-match the generated ABI
   (the i128 _hl literal carries as an __int128 param; Rules 2, 16).

   cq_theta/cq_measure resolve from CQ.h (force-included by run_slice.sh). */
typedef unsigned __int128 u128;

__attribute__((noinline))
void slice(unsigned long x) {
    unsigned long a = x; cq_theta(&a, 0.25);
    u128 wide = (u128)a * (u128)a;          /* 128-bit product (clean i128 ops) */
    unsigned long hi = (unsigned long)(wide >> 64);
    (void) cq_measure(hi);
}
int main(void) { slice(0x123456789aUL); return 0; }
