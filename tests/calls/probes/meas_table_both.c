/* cq-md33a (rule 18, §1.4, ruling cq-t2jj2): a table clone that measures both its formal and a rail that is not a formal, the
   non-formal one first (measured after x, y would be a classical read of x's outcome, cq-ihlt).
   The formal's measurement leaves _t no rule-18 twin (measuresFormalCopy), so neither measured copy is pushed (mintSites is
   empty) and _t_unc only pops what _t pushed: nothing in both (f); in bothrot (g) the register cq_theta minted, listed
   (listMint) and pushed with its count at the return (pushListedMints), which _t_unc pops (popsMints). */
__attribute__((noinline)) int both(int x){ int y = x * 3 + 1; int my = cq_measure(y); return my + cq_measure(x); }
__attribute__((noinline)) int other(int x){ return x + 5; }
int f(int a, int k){
  int (*p)(int) = k ? both : other;
  cq_theta(&a, 1.0);
  int r = p(a + 1);
  return r + cq_measure(a);
}
__attribute__((noinline)) int bothrot(int x){ int y = x ^ 5; cq_theta(&y, 0.5); int my = cq_measure(y); return my + cq_measure(x); }
int g(int a, int k){
  int (*p)(int) = k ? bothrot : other;
  cq_theta(&a, 1.0);
  int r = p(a + 1);
  return r + cq_measure(a);
}
