#!/bin/bash
# Writes the fmt3 class probe family into src/.  (Kept as a script so the family is reproducible.)
set -eu
P=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aea6988dda116aa5b/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/fmt3_probes
Z=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/review_r1A_z0re/probes/src
S=$P/src
mkdir -p "$S"
cp -f "$Z/a6.c" "$Z/a6f.c" "$Z/a4.c" "$S/"

w() { cat > "$S/$1.c"; }

w n9 <<'EOF'
#include <stdlib.h>
/* fmt3 class: a6's inner if/else with NO outer region -> -O1 erases the branch entirely */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r;
  if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .9);
  return cq_measure(r) + cq_measure(t); }
EOF
w n10 <<'EOF'
#include <stdlib.h>
/* fmt3 class: a6's inner if/else under a CLASSICAL outer condition */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r = 5;
  if (c > 2) { if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .9); }
  return cq_measure(r) + cq_measure(t); }
EOF
w n1 <<'EOF'
#include <stdlib.h>
/* fmt3: a6 with the inner compare spelled != */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (t != 5) r = cq_theta(5, .9); else r = cq_theta(t, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
EOF
w n2 <<'EOF'
#include <stdlib.h>
/* fmt3: a6 with the inner branch a switch */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { switch (t) { case 5: r = cq_theta(t, .9); break; default: r = cq_theta(5, .9); break; } }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
EOF
w n3 <<'EOF'
#include <stdlib.h>
/* fmt3: a6 nested one level deeper */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int q3 = cq_theta(2, .3); int r = 5;
  if (q2 > 3) { if (q3 > 1) { if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .9); } }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2) + cq_measure(q3); }
EOF
w n4a <<'EOF'
#include <stdlib.h>
/* fmt3: a6 with literal 0 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 0;
  if (q2 > 3) { if (t == 0) r = cq_theta(t, .9); else r = cq_theta(0, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
EOF
w n4b <<'EOF'
#include <stdlib.h>
/* fmt3: a6 with literal -1, t = q ^ 3 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q ^ 3; int q2 = cq_theta(7, .4); int r = -1;
  if (q2 > 3) { if (t == -1) r = cq_theta(t, .9); else r = cq_theta(-1, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
EOF
w n5 <<'EOF'
#include <stdlib.h>
/* fmt3: fp member — d = (double)q, inner d == 5.0 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); double d = (double)q; int q2 = cq_theta(7, .4); double r = 5.0;
  if (q2 > 3) { if (d == 5.0) r = cq_theta(d, .9); else r = cq_theta(5.0, .9); }
  return (int)cq_measure(r) + (int)cq_measure(d) + cq_measure(q2); }
EOF
w n6 <<'EOF'
#include <stdlib.h>
#include <stdbool.h>
/* fmt3: i1 member — b = q & 1 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); bool b = q & 1; int q2 = cq_theta(7, .4); bool r = true;
  if (q2 > 3) { if (b) r = cq_theta(b, .9); else r = cq_theta(true, .9); }
  return cq_measure(r) + cq_measure(b) + cq_measure(q2); }
EOF
w n7 <<'EOF'
#include <stdlib.h>
/* fmt3: the drbq.13 angle-select counter-example (different angles) nested in a region */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .3); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
EOF
w n8 <<'EOF'
#include <stdlib.h>
/* fmt3: a6 inside a classically-bounded loop */
int main(int c, char **v) { int m = atoi(v[1]); int k = atoi(v[2]); int q = cq_theta(m, .5); int t = q / 4; int acc = 0;
  for (int i = 0; i < k; i++) { int q2 = cq_theta(i, .4); int r = 5;
    if (q2 > 3) { if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .9); }
    acc += cq_measure(r) + cq_measure(q2); }
  return acc + cq_measure(t); }
EOF
w n11 <<'EOF'
#include <stdlib.h>
/* fmt3: a6 without the later read of t */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .9); }
  return cq_measure(r) + cq_measure(q2); }
EOF
w n12 <<'EOF'
#include <stdlib.h>
/* the LEGITIMATE program a6 folds INTO: prep 5 under q2 > 3, t live and unrelated */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) r = cq_theta(5, .9);
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
EOF
w n13 <<'EOF'
#include <stdlib.h>
/* fmt3: a GENUINELY realizable rival: the inner condition reads q, the arm rotates t = q/4 (off the inner wire) */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (q == 20) r = cq_theta(t, .9); else r = cq_theta(5, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
EOF
w n13f <<'EOF'
#include <stdlib.h>
/* n13 flat: if (q == 20) r = cq_theta(t,.9); (the F-R1-1 shape) */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r = 5;
  if (q == 20) r = cq_theta(t, .9);
  return cq_measure(r) + cq_measure(t); }
EOF
w n14 <<'EOF'
#include <stdlib.h>
/* fmt3: pin through a forward function in the arm — cq_theta(t + 1) vs literal 6 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 6;
  if (q2 > 3) { if (t == 5) r = cq_theta(t + 1, .9); else r = cq_theta(6, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
EOF
w n15 <<'EOF'
#include <stdlib.h>
/* fmt3: pin on a WIDER register, arm reads a narrowing cast */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); long long t = (long long)q * 3; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (t == 5) r = cq_theta((int)t, .9); else r = cq_theta(5, .9); }
  return cq_measure(r) + (int)cq_measure(t) + cq_measure(q2); }
EOF
echo wrote; ls "$S"

# ---- second batch: the simplifyWithOpReplaced route (a REALIZABLE rival, W off the condition wire)
w n16 <<'EOF2'
#include <stdlib.h>
/* nested DIAMONDS (no inner else): the inner is a6f's prep, nested in q2>3 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (t == 5) r = cq_theta(t, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
EOF2
w n17 <<'EOF2'
#include <stdlib.h>
/* REALIZABLE rival: W = q + 1 is a separate rail OFF the inner condition's wire (q == 5);
   the source rotates W in place on q2>3 && q==5.  sink -> phi[W,6] -> select(q==5,W,6) -> simplifyWithOpReplaced -> 6 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int W = q + 1; int q2 = cq_theta(7, .4); int r = 6;
  if (q2 > 3) { if (q == 5) r = cq_theta(W, .9); else r = cq_theta(6, .9); }
  return cq_measure(r) + cq_measure(W) + cq_measure(q2); }
EOF2
w n17f <<'EOF2'
#include <stdlib.h>
/* n17 with NO outer region */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int W = q + 1; int r;
  if (q == 5) r = cq_theta(W, .9); else r = cq_theta(6, .9);
  return cq_measure(r) + cq_measure(W) + cq_measure(q); }
EOF2
w n17d <<'EOF2'
#include <stdlib.h>
/* n17's parts: the diamond (no else) — the in-place Ry arm on W under q == 5 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int W = q + 1; int r = W;
  if (q == 5) r = cq_theta(W, .9);
  return cq_measure(r) + cq_measure(q); }
EOF2
w n18 <<'EOF2'
#include <stdlib.h>
/* the Ry-stem angle select (shipped accept shape) — the nomerge cost probe */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = cq_theta(3, .2);
  if (q > 3) p = cq_theta(p, .9); else p = cq_theta(p, .3);
  return cq_measure(p) + cq_measure(q); }
EOF2
w n19 <<'EOF2'
#include <stdlib.h>
/* the owner-style bool cascade: a legitimate literal prep beside an OFF-wire live bool (coarse-fence cost probe) */
#include <stdbool.h>
int main(int c, char **v) { bool b0 = cq_theta(0, .5); bool b1 = 0; bool b2 = 0;
  if (b0) b1 = cq_theta(0, .7);
  if (b1) b2 = cq_theta(0, .3);
  return cq_measure(b0) + cq_measure(b1) + cq_measure(b2); }
EOF2
echo wrote2
