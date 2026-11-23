#include "cq.hpp"
#include <cstdint>
#include <span>
static uint32_t mix(std::span<const uint32_t> w) { uint32_t a = 0x6a09e667, b = 0xbb67ae85; for (auto x : w) { uint32_t t = (a >> 6 | a << 26) ^ (b & x); a = b + t; b = t ^ (x << 3); } return a ^ b; }
ENTRY int f(int x, int y) { uint32_t w[8]; for (int i = 0; i < 8; i++) w[i] = i * y; w[1] = q((unsigned)x); return (int)mix(w); }
