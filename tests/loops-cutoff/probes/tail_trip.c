/* tests/loops-cutoff probe (CR rules 8, 9, 14; cq-t30vh): a K-loop with two exits inside another loop's trip, whose exit arm is also
 * entered from outside the K-loop (its guard's skip): the arm's tail on the paths that skip the loop. Inside a classical trip: tt_skip,
 * a rotation in the tail (tt_rot), a classical branch of the tail into the continuation (tt_arm), a classical skip of a do/while
 * (tt_cskip). Inside a K-loop's trip: tt_kk, tt_kk_arm.
 * Regenerate tail_trip.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec -include CQ.h tail_trip.c -o tail_trip.O1.ll */
#define Q _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
#define INNER unsigned w=v; int n=0; while (w & 1) { if (b3 && n==1) { t+=100; goto N; } w>>=1; n++; }
int tt_skip(unsigned c) { Q int t=0; for (unsigned k=0;k<2+(c&1);k++) { INNER t += n+k; N: ; v ^= c; } return cq_measure(t); }
int tt_rot(unsigned c) { Q _Bool r=0; int t=0; for (unsigned k=0;k<2+(c&1);k++) { INNER t += n+k; cq_theta(&r, 0.25*(k+1)); N: ; v ^= c; } return cq_measure(t) + cq_measure(r)*256; }
int tt_arm(unsigned c) { Q int t=0; for (unsigned k=0;k<2+(c&1);k++) { INNER t += n+k; if (c&4) t ^= 5; else t += 1; N: ; v ^= c; } return cq_measure(t); }
int tt_cskip(unsigned c) { Q int t=0; for (unsigned k=0;k<2+(c&1);k++) { unsigned w=v; int n=0; if (c&2) { do { if (b3 && n==1) { t+=100; goto N; } w>>=1; n++; } while (w&1); } t += n+k; N: ; v ^= c; } return cq_measure(t); }
int tt_kk(unsigned c) { Q int t=0; unsigned y=v^c; while (y&1) { INNER t += n+1; N: ; v ^= c; y>>=1; } return cq_measure(t); }
int tt_kk_arm(unsigned c) { Q int t=0; unsigned y=v^c; while (y&1) { INNER t += n+1; if (c&4) t ^= 5; else t += 1; N: ; v ^= c; y>>=1; } return cq_measure(t); }
