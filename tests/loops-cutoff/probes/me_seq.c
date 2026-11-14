/* tests/loops-cutoff probe (CR rules 2, 14; owner, cq-oiclq; cq-q7u9y): two measurements in sequence in the exit arm of a K-loop that
 * also returns past them, with (e) and without (e0) a classical conjunct in the loop's test. The first rewrite routes the second
 * measurement's value through a hub phi, which the second rewrite asks taint about (it crashed with "no taint answer").
 * Regenerate me_seq.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h me_seq.c -o me_seq.O1.ll */
unsigned e(unsigned x0, double th, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1, i;
  for (i = 0; ((m >> i) & 1) && x > 2; i++) { if (x == 8) return 77; x -= 3; s = s * 5 + x; }
  return cq_measure(x) * 4096 + cq_measure(s) * 16;
}
unsigned e0(unsigned x0, double th, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1, i;
  for (i = 0; x > 2; i++) { if (x == 8) return 77; x -= 3; s = s * 5 + x; }
  return cq_measure(x) * 4096 + cq_measure(s) * 16;
}
