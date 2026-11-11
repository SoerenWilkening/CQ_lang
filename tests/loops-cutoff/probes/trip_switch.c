/* tests/loops-cutoff case atoms carried to a classical join (cq-7jd1z, CR rules 8, 9, 13 with rule 14's K trips): a
 * quantum switch's case flag (rule 13: the equality template on the scrutinee) read past a classical branch where the
 * flag's atoms do not reach is carried there by a phi in the scrutinee's own type, a seed of the case value or of
 * another value on an edge that does not read it. Musl wcsrtombs: a K-loop over a quantum bound whose exit arms store
 * (one hub after the trips, switching on which exit came in) behind a classical `n >= 4`, then a second K-loop. Also
 * switches in a K-trip on a widened and a narrowed scrutinee, with a default arm and two cases sharing a successor.
 * Each entry is checked §6 against its own C program (cqcheck user).
 * Regenerate trip_switch.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec trip_switch.c -o trip_switch.O1.ll */
#include "CQ.h"

/* (a) The bead's shape: musl wcsrtombs' two loops, the first behind a classical bound test. */
__attribute__((noinline)) static unsigned sa_put(char *s, unsigned c) {
  if (c < 0x80) { *s = (char)c; return 1; }
  if (c < 0x800) { s[0] = (char)(0xc0 | (c >> 6)); s[1] = (char)(0x80 | (c & 0x3f)); return 2; }
  return (unsigned)-1;
}
__attribute__((noinline)) static unsigned sa_conv(char *s, const unsigned **ws, unsigned n) {
  unsigned N = n, l;
  while (n >= 4) {
    if (**ws - 1u >= 0x7fu) {
      if (!**ws) { *s = 0; *ws = 0; return N - n; }
      l = sa_put(s, **ws);
      if (!(l + 1)) return (unsigned)-1;
      s += l; n -= l;
    } else {
      *s++ = (char)**ws; n--;
    }
    (*ws)++;
  }
  while (n) {
    if (**ws - 1u >= 0x7fu) {
      if (!**ws) { *s = 0; *ws = 0; return N - n; }
      l = sa_put(s, **ws);
      if (l == (unsigned)-1) return (unsigned)-1;
      s += l; n -= l;
    } else {
      *s++ = (char)**ws; n--;
    }
    (*ws)++;
  }
  return N;
}
unsigned sa_wcs(unsigned c0, double th, unsigned n) {
  char out[16] = {0};
  unsigned w[8] = {0x41, 0x100, 0x42, 0x43, 0x44, 0x45, 0, 0};
  w[1] = c0; cq_theta(&w[1], th);
  const unsigned *p = w;
  unsigned r = sa_conv(out, &p, n & 7);
  return cq_measure(r) * 4096 + cq_measure((unsigned char)out[1]) * 16 + cq_measure(p ? (unsigned)(p - w) : 15u);
}

/* (b) A switch inside a K-trip on a narrowed quantum scrutinee (i8), with a default arm and two cases sharing one
 * successor, behind a classical branch; a store in an arm keeps the branches at -O1. */
unsigned sb_narrow(unsigned x0, double th, unsigned k, int c) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned cell[4] = {1, 2, 3, 4};
  unsigned *volatile vp = cell;
  unsigned *f = vp;
  unsigned n = 0;
  while (x > k) {
    x >>= 1;
    if (c & 1) {
      switch ((unsigned char)(x + n)) {
      case 1: case 5: f[0] += x; break;
      case 2: f[1] ^= n; break;
      case 200: f[2] += 7; break;
      default: f[3] += 1; break;
      }
    }
    n++;
  }
  return cq_measure(n) * 4096 + cq_measure(f[0] + f[1] * 3 + f[2] * 5 + f[3] * 7);
}

/* (c) The same on a widened scrutinee (i64 from a 16-bit value), the switch after the classical join. */
unsigned sc_wide(unsigned short x0, double th, unsigned k, int c) {
  unsigned short x = x0; cq_theta(&x, th);
  unsigned cell[4] = {1, 2, 3, 4};
  unsigned *volatile vp = cell;
  unsigned *f = vp;
  unsigned n = 0;
  while (x > k) {
    x >>= 1;
    if (c & 2) f[3] ^= 9;
    switch ((long long)x * 3 - (long long)n) {
    case 0: case 3: f[0] += 2; break;
    case 6: f[1] += x; break;
    case -1: f[2] ^= 5; break;
    default: break;
    }
    n++;
  }
  return cq_measure(n) * 4096 + cq_measure(f[0] + f[1] * 3 + f[2] * 5 + f[3] * 7);
}
