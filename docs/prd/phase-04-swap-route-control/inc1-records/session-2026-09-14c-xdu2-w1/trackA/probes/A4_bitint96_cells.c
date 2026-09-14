/* ⚠ THIS PROBE DOES NOT COMPILE, AND THAT IS ITS RESULT — kept as the MEASUREMENT,
   not as a working probe (a deleted negative result is a negative result nobody can
   check). `CQ.h`'s `cq_theta` is a 14-type `_Generic` and a `_BitInt(96)` controlling
   expression is a hard COMPILE ERROR:

     A4_bitint96_cells.c:5:29: error: controlling expression type '_BitInt(96)'
     not compatible with any generic association type

   So clause C3's OTHER half — a cell type for which `abiWidthFromType` returns ""
   at all, as opposed to the `f64` cell that HAS a width and no reversible copy — is
   NOT reachable on the `clang -O1` floor and is pinned by hand IR instead:
   `ir-pass/test/lowering_reject_railbank_nowidth_cell.ll`, which mints the i96 rail
   the only way a real program could (a `zext` of a supported rail).
   ⚠ Do NOT add this file to a corpus sweep expecting a verdict; it reports CLANGERR. */
/* Track A, clause C3 negative (the second spelling): a _BitInt(96) cell, for which
   abiWidthFromType itself returns "" — the other half of the width axis. */
#include "CQ.h"
int main(void){ _BitInt(96) b[3]={0,0,0};
  for(int i=0;i<3;++i) b[i]=cq_theta(b[i],0.5);
  int s=0; for(int i=0;i<3;++i) s+=(int)cq_measure(b[i]); return s; }
