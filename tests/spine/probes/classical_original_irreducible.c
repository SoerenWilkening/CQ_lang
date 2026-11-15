/* tests/spine probe (NORTHSTAR principle 1, CLAUDE.md pipeline; cq-mjw9): fix-irreducible and step 2's other CFG rewrites
 * serve the clones only. @irr has an irreducible cycle, a quantum clone (qfun passes it a rail) and a classical caller:
 * its own symbol stays as compiled (no irr.guard block), its clones are made reducible.
 * Regenerate classical_original_irreducible.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h classical_original_irreducible.c */
__attribute__((noinline)) int irr(int a, int n, int q) {
  int i = 0;
  if (a & 1) goto L2;
L1: i += 2; if (i > n) goto out;
L2: i += 3; if (i < 50) goto L1;
out:
  return i ^ q;
}
__attribute__((noinline)) int qfun(int n) {
  int x = 3;
  cq_theta(&x, 0.5);
  return cq_measure(irr(n, 9, x));
}
int classical_caller(int a) { return irr(a, 9, a) + qfun(a); }
