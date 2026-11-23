/* tests/loops-classical probe (cq-krhay; CR rules 3 "Loops", 6, 14 case 3, 21): a walked pointer with a quantum exit read
 * after the loop. pe_start, pe_fwd, pe_mix: the pointer itself is read (it was taken as the classical last trip's).
 * pe_phi: -O1 makes an exit phi, whose ptrtoint the subtraction cleaned by rule 6 in every trip (rails freed dirty).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec ptr_exit.c -o ptr_exit.O1.ll */
#include "CQ.h"
#include <stdint.h>
long pe_start(uint8_t pos, uint8_t n) {
  char s[9] = "ab/cd/ef"; uint8_t q = 0; cq_theta(&q, 0.5);
  s[pos % 8] = (q & 1) ? '/' : (char)('a' + (q >> 5));
  char *p = s + (n % 9);
  while (p > s && p[-1] != '/') --p;
  return cq_measure((long)(p - s));
}
long pe_phi(uint8_t pos) {
  char s[9] = "ab/cd/ef"; uint8_t q = 0; cq_theta(&q, 0.5);
  s[pos % 8] = (q & 1) ? '/' : (char)('a' + (q >> 5));
  char *p = s + 8;
  while (p > s && p[-1] != '/') --p;
  return cq_measure((long)(p - s));
}
/* forward, the cell the exit pointer names loaded after the loop */
int pe_fwd(uint8_t pos, uint8_t n) {
  char s[9] = "ab/cd/ef"; uint8_t q = 0; cq_theta(&q, 0.5);
  s[pos % 8] = (q & 1) ? '/' : (char)('a' + (q >> 5));
  char *p = s + (n % 8), *e = s + 8;
  while (p < e && *p != '/') ++p;
  return cq_measure((int)*p);
}
/* one exit test with a classical and a quantum conjunct: the pointer is a capture rail of the latch */
int pe_mix(uint8_t n) {
  uint8_t q = 0; cq_theta(&q, 0.5);
  char s[9] = "abcdefgh", *p = s + 1 + (n % 8);
  int i = 0;
  do { --p; ++i; } while ((p > s) & ((q >> i) & 1));
  return cq_measure((int)*p);
}
