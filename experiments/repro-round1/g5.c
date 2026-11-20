typedef unsigned u32;
#define ROTL(a,b) (((a) << (b)) | ((a) >> (32 - (b))))
static void chacha_block(u32 *out, const u32 *in) {
  u32 x[2];
  __builtin_memcpy(x, in, 2 * 4);
  for (int i = 0; i < 10; i++) {
    x[0] += x[1]; x[1] ^= x[0];
  }
  for (int i = 0; i < 2; i++) out[i] = x[i] + in[i];
}
static struct { u32 s[2]; u32 out[2]; unsigned char n; } P;
void f(int N) {
  while (1) {
    if (N <= P.n) {
      P.n -= N;
      break;
    }
    N -= P.n;
    P.s[1]++;
    chacha_block(P.out, P.s);
    P.n = 64;
  }
}
