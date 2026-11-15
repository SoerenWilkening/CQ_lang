/* tests/spine probe (CR rules 3, 18, 26; cq-le2c, cq-ejne): a clone returns one rail per field of its result layout, so a
 * packed small struct whose returns the layout does not split ({short, short, char} as i48 with a constant field) is one
 * rail, and every byte of it the caller reads is computed from that rail: t.a and t.c are templates on it, never a
 * classical instruction handed the rail ('a rail handle reaching a classical instruction').
 * Regenerate packed_result_classical_bytes.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h packed_result_classical_bytes.c */
struct P { short a; short b; char c; };
__attribute__((noinline)) struct P f(short x, short y) { struct P t = { x + 1, y * 2, 5 }; return t; }
int s7(int p, int q) { short y = q; cq_theta(&y, 1.0); struct P t = f(p, y); return t.a + cq_measure(t.b) + t.c; }
