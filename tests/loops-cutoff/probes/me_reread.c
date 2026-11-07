/* tests/loops-cutoff probe (CR rules 2, 14; owner, cq-2z29a): a loop-carried value with a rail incoming stays a rail (v >>= 1 is the template, the exit
 * test quantum, K trips). All of it is computed from the first measured rail, so the first cq_measure measures and the later ones re-read it.
 * Regenerate me_reread.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h me_reread.c -o me_reread.O1.ll */
int f(unsigned c) { unsigned v = c; cq_theta(&v,1.0);
int n=0; while (v & 1) { n += cq_measure(v); v >>= 1; }
 return n;
}
