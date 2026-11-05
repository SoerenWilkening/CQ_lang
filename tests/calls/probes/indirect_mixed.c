/* tests/calls probe (cq-s2zz, CR rule 19): a call through a classical function pointer: a struct result merged field by field
 * (a handle field and a classical field). Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0
 * -I ../../../../CQ_spec indirect_mixed.c -o indirect_mixed.O1.ll */
#include "CQ.h"
typedef struct { long a, b; } two;
__attribute__((noinline)) static two mk1(int v) { two t = {v + 1, 5}; return t; }
__attribute__((noinline)) static two mk2(int v) { two t = {v * 3, 6}; return t; }
long im_struct(long x0, double th, int k) {
    long x = x0;
    cq_theta(&x, th);
    two (*f)(int) = k ? mk1 : mk2;
    two t = f(x);
    return cq_measure(t.a) + t.b;
}
