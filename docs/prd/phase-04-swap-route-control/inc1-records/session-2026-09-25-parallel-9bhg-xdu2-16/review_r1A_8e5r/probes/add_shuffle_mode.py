#!/usr/bin/env python3
"""REVIEW-ONLY: add CQ_OPT_DEBUG_ALLOC=shuffle[:SEED] to a private copy of cq_debug_alloc.cpp.
Nothing is freed (no reuse), and every allocation is served from one of 8 bump arenas
chosen PSEUDO-RANDOMLY (xorshift seeded from SEED), each arena 1 TiB apart in a lazily
committed reservation -- so the ADDRESS ORDER of IR objects is a seed-dependent
permutation of their creation order. An emitted stream that moves between seeds depends
on heap addresses (address-ordered std::set / hash-ordered DenseMap iteration feeding
emission) -- nondeterministic by construction (Rule 9)."""
import sys
p = sys.argv[1]
s = open(p).read()
def sub(a, b):
    global s
    assert s.count(a) == 1, a[:60]
    s = s.replace(a, b)
sub('#include <new>\n', '#include <new>\n#include <cstdint>\n#include <sys/mman.h>\n')
sub('CAM_Scribble = 3 };', 'CAM_Scribble = 3, CAM_Shuffle = 4 };\nuint64_t CqShufState = 88172645463325292ull;\nchar *CqArenaBase = nullptr;\nsize_t CqArenaOff[8];\nconstexpr size_t CqArenaSpan = (size_t)1 << 36;  // 64 GiB per arena (virtual)\n')
sub('''    if (E && !std::strcmp(E, "scribble"))
      CqAllocModeV = CAM_Scribble;''', '''    if (E && !std::strcmp(E, "scribble"))
      CqAllocModeV = CAM_Scribble;
    if (E && !std::strncmp(E, "shuffle", 7)) {
      CqAllocModeV = CAM_Shuffle;
      if (E[7] == ':')
        CqShufState ^= (uint64_t)std::strtoull(E + 8, nullptr, 10) * 0x9E3779B97F4A7C15ull;
      void *R = mmap(nullptr, CqArenaSpan * 8, PROT_READ | PROT_WRITE,
                     MAP_ANON | MAP_PRIVATE | MAP_NORESERVE, -1, 0);
      if (R == MAP_FAILED)
        std::abort();
      CqArenaBase = static_cast<char *>(R);
    }''')
sub('''void *cqNew(std::size_t N) {
  if (N == 0)
    N = 1;''', '''void *cqNew(std::size_t N) {
  if (N == 0)
    N = 1;
  if (cqAllocMode() == CAM_Shuffle) {
    CqShufState ^= CqShufState << 13;
    CqShufState ^= CqShufState >> 7;
    CqShufState ^= CqShufState << 17;
    unsigned A = (unsigned)(CqShufState >> 32) & 7u;
    size_t Sz = (N + 15) & ~(size_t)15;
    if (CqArenaOff[A] + Sz > CqArenaSpan)
      std::abort();
    void *P = CqArenaBase + (size_t)A * CqArenaSpan + CqArenaOff[A];
    CqArenaOff[A] += Sz;
    return P;
  }''')
sub('''  switch (cqAllocMode()) {
  case CAM_NoFree:
    return;''', '''  switch (cqAllocMode()) {
  case CAM_Shuffle:
    return;
  case CAM_NoFree:
    return;''')
open(p, 'w').write(s)
print("ok")
