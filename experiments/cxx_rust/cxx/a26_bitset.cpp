#include "cq.hpp"
#include <bitset>
#include <bit>
ENTRY int f(int x, int y) { std::bitset<16> b((unsigned)q((unsigned short)x)); b ^= std::bitset<16>(y & 0xffff); return (int)b.count() * 100 + std::countl_zero((unsigned)b.to_ulong()) + std::rotl((unsigned)b.to_ulong(), 3); }
