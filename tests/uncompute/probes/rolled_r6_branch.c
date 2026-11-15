/* cq-9kcq (CR rules 6, 14 case 2): a rolled K-loop whose carried accumulator has a bijective update (s ^= y) and whose
 * trip branches classically after the update. Rule 6's per-trip clean-up of the old rail is placed at the latch block's
 * end, where it cannot follow U's undo in an earlier block: the old rail is left to the reverse loop (was: "mirror would
 * free %47 while a rail outside the scope still reads it", stored_loops' sl_trip and sl_kloop after the rolled form).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h rolled_r6_branch.c */
int g[8];
int rb(int x0, double t) {
  int x = cq_theta_si32(x0, t);
  int s = 0;
  for (int i = 0; i < (x & 3); i++) {
    int y = x * (i + 3);
    s ^= y;
    if (i & 1)
      g[3] = i;
  }
  return cq_measure_si32(s + g[3]);
}
