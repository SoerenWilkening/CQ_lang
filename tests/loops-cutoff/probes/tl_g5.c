/* tests/loops-cutoff probe (CR rules 9, 14), cq-12u5n: nested loop tails. v = b0|b1<<1|b2<<2|b3<<3.
 * Regenerate tl_g5.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h tl_g5.c */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3;
int s=0; int wn=3; int r;
 for (;;) { if (!wn) { r=99; goto R; } while (wn>=2 && !((v>>s)&3)) { s+=1; wn-=1; } if ((v>>s)&1) { s++; wn--; continue; } break; } 
 r = s;
R: return cq_measure(r);
}
