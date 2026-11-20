/* cq-03rdt: a classically bounded mixing loop (ChaCha's double rounds, cut to two words) inside a
   K-loop's trip. The outer loop's recordDeferred took over the inner loop's rails (ownedBy), so the
   inner reverse counted its own trip's rail (b ^= a reads a) as a reader outside it: "mirror would
   free %N while a rail outside the scope still reads it" (SQLite sqlite3_randomness). */
typedef unsigned u32;
static void blk(u32 *out, const u32 *in) {
  u32 x[2];
  __builtin_memcpy(x, in, 8);
  for (int i = 0; i < 10; i++) {
    x[0] += x[1];
    x[1] ^= x[0];
  }
  for (int i = 0; i < 2; i++)
    out[i] = x[i] + in[i];
}
static struct { u32 s[2]; u32 out[2]; unsigned char n; } P;
int chacha_mini(int N0, double th) {
  int N = N0;
  cq_theta(&N, th);
  while (1) {
    if (N <= P.n) {
      P.n -= N;
      break;
    }
    N -= P.n;
    P.s[1]++;
    blk(P.out, P.s);
    P.n = 64;
  }
  return cq_measure(N);
}
