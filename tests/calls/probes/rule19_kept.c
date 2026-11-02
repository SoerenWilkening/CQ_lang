/* tests/calls probe (cq-i9wk, CR rule 19: the compiler never inlines). A callee reached with no quantum argument
 * whose body rotates is called as it is. A result that is a register the callee minted or its rule-6 image is
 * FROZEN: the caller keeps it like its own register (k_frozen, k_frozen_rot: 162's shape, then rotated again in
 * the caller). Any other result comes from the callee's kept clone, which returns after it the registers still
 * allocated; the caller keeps those and its twin cleans the result against them (k_twin, k_twin2: one and two
 * registers; k_meas: measured, no twin). Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0
 * -I ../../../../CQ_spec rule19_kept.c -o rule19_kept.O1.ll */
#include "CQ.h"

__attribute__((noinline)) int image(int x0, double t, int c) {
    int x = x0;
    cq_theta(&x, t);
    return x + c;   /* rule 6: x is cleaned against x + c, the image of the register */
}

__attribute__((noinline)) int square(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    return x * x;   /* not a bijection: x stays allocated, the result is not frozen */
}

__attribute__((noinline)) int mix(int a0, double ta, int b0, double tb) {
    int a = a0, b = b0;
    cq_theta(&a, ta);
    cq_theta(&b, tb);
    return (a & 7) * (b | 1);
}

int k_frozen(int x0, double t, int c) {
    int q = image(x0, t, c);
    return cq_measure(q * 3);
}

int k_frozen_rot(int x0, double t, int c, double t2) {
    int q = image(x0, t, c);
    cq_theta(&q, t2);
    return cq_measure(q);
}

int k_twin(int x0, double t, int c) {
    int y = square(x0, t);
    return cq_measure(y + c);
}

int k_meas(int x0, double t) {
    return cq_measure(square(x0, t));
}

int k_twin2(int a0, double ta, int b0, double tb) {
    int y = mix(a0, ta, b0, tb);
    return cq_measure(y ^ 5);
}
