/* tests/loops-cutoff probe (CR rules 9, 14), cq-uang6: musl printf_core's digit loop. A K-loop nested in a K-loop's trip exits into a
 * join with other incomings, so the trip merges that phi itself on every trip: the merge of trip 1 on is not the sub-loop's binding.
 * Regenerate trip_merge.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h trip_merge.c */
int f(unsigned c) { _Bool b0=1,b1=1,b2=1,b3=1,b4=1;cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);cq_theta(&b4,1.0);unsigned v = b0|b1<<1|b2<<2|b3<<3|b4<<4;
 unsigned x = v; int n = 0;
 do { int p = 0; if (x & 1) { p = 1; x = (x >> 1) ^ (x >> 3); while (x & 1) { x = (x >> 1) ^ (x >> 3); p += 2; } } else if (x & 2) { p = 7; } n = n * 3 + p; x = x >> 1; } while (x);
 return cq_measure(n); }
