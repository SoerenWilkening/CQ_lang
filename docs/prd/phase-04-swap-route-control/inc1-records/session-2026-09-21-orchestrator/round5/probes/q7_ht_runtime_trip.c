// Q7 — ht_rolled with a RUNTIME trip bound (bd h1ip's guarded shape) crossed with
// (ii-d).  `-O1` emits a zero-trip GUARD; the mint of `p` is in the entry block, the
// consumer in the body, so LOut is the loop and the discharge lands at its exit --
// which, on the zero-trip path, is NOT EXECUTED AT ALL while the forward gate WAS.
// One forward gate, ZERO adjoints, on a path the compiler must still be right on.
#include "CQ.h"
int slice(int u, int n){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3); int p=q*3;
  for(int i=0;i<n;i++){ if((p>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  q=cq_theta(q,0.9); return cq_measure(q)+cq_measure(r); }
int main(int argc, char **argv){ (void)argv; return slice(4, argc-1); }
