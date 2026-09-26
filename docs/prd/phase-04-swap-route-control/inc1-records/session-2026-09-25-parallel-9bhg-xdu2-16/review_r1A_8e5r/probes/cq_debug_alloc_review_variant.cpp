// cq_debug_alloc.cpp — the TEST-ONLY deterministic allocator, linked into the
// test drivers `cq-opt` and `cq-scrub-selftest` and NEVER into `libCQPass.so`.
//
// bd test_C_libtooling-8e5r / -um24 / -j8sk.
//
// WHY IT EXISTS. The defect class those beads name is a pointer to a DELETED
// `llvm::Value` kept as a key of a pass side table (`taint.Tainted`, ...). What
// that stale key does depends entirely on what the system allocator puts at the
// freed address next: nothing (the stale key is inert), an unrelated object (a
// use-after-free read, bd um24), or a fresh instruction of the same size that
// then answers `taint.Tainted.count() == true` (a silent miscompile, bd 8e5r —
// measured 7/10 runs on one binary, 10/10 on another). A fixture run under the
// system allocator therefore pins the defect by LOTTERY (Rule-13 r1B F-9B-3).
// This allocator removes the lottery, so a regression pin can be a plain lit
// fixture:
//
//   CQ_OPT_DEBUG_ALLOC=lifo    every freed block is handed to the very next
//                              allocation of the SAME size class (LIFO, exact
//                              class): MAXIMAL, deterministic address reuse.
//   CQ_OPT_DEBUG_ALLOC=nofree  nothing is ever freed, so no address is ever
//                              reused: the no-aliasing REFERENCE. (A deleted
//                              object's bytes stay mapped, so a dereference of
//                              a stale key reads the dead object — whose parent
//                              pointer `removeFromParent` has already nulled.)
//   unset (or any other value) plain malloc/free — the shipped behaviour.
//
// ⚠ SCOPE. This file replaces the global `operator new`/`delete` of the TEST
// DRIVERS only. `libCQPass.so` — what `opt -load-pass-plugin` and every user of
// the pass loads — contains none of it. With the variable unset every allocation
// is exactly one `malloc` and every free one `free`, and the
// `cq-opt-equivalence` gate (cq-opt vs opt+plugin: stdout, stderr and exit code)
// is the witness that this default path changed nothing observable.
//
// ⚠ THE MODE IS FIXED AT THE FIRST ALLOCATION (static-init time, before `main`),
// from the environment, so every block the process ever frees was allocated
// under the same mode. `lifo` needs the platform's block-size query and is
// honoured on macOS only; elsewhere it degrades to the system allocator (a pin
// then passes without exercising reuse — it cannot go falsely RED).
// ⚠ In `lifo` mode a freed block's FIRST WORD holds the free-list link, so a
// stale dereference reads a pointer there; that is part of what makes a UAF read
// crash deterministically, and it is not a correctness property of anything.

#include <cstdlib>
#include <cstring>
#include <new>
#include <cstdint>
#include <sys/mman.h>
#if defined(__APPLE__)
#include <malloc/malloc.h>
#endif

namespace {
enum CqAllocMode : int { CAM_Unset = -1, CAM_System = 0, CAM_NoFree = 1, CAM_Lifo = 2, CAM_Scribble = 3, CAM_Shuffle = 4 };
uint64_t CqShufState = 88172645463325292ull;
char *CqArenaBase = nullptr;
size_t CqArenaOff[8];
constexpr size_t CqArenaSpan = (size_t)1 << 36;  // 64 GiB per arena (virtual)

int CqAllocModeV = CAM_Unset;

int cqAllocMode() {
  if (CqAllocModeV == CAM_Unset) {
    const char *E = std::getenv("CQ_OPT_DEBUG_ALLOC");
    CqAllocModeV = CAM_System;
    if (E && !std::strcmp(E, "nofree"))
      CqAllocModeV = CAM_NoFree;
    if (E && !std::strcmp(E, "scribble"))
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
    }
#if defined(__APPLE__)
    if (E && !std::strcmp(E, "lifo"))
      CqAllocModeV = CAM_Lifo;
#endif
  }
  return CqAllocModeV;
}

#if defined(__APPLE__)
// One intrusive LIFO free list per 16-byte class, for blocks up to 4 KiB (every
// `Instruction`/`User` allocation is far below that). A freed block's class is
// its OWN `malloc_size`, and a request is served from the class
// `malloc_good_size(n)` names — the size `malloc(n)` itself would have returned —
// so the list is exact-class.
constexpr size_t CqQuantum = 16, CqMaxPooled = 4096;
void *CqFreeList[CqMaxPooled / CqQuantum + 1];  // static storage: zero-initialized
#endif

void *cqNew(std::size_t N) {
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
  }
#if defined(__APPLE__)
  if (cqAllocMode() == CAM_Lifo) {
    size_t G = malloc_good_size(N);
    if (G <= CqMaxPooled && G % CqQuantum == 0) {
      if (void *B = CqFreeList[G / CqQuantum]) {
        CqFreeList[G / CqQuantum] = *static_cast<void **>(B);
        return B;
      }
    }
  }
#else
  (void)cqAllocMode();
#endif
  void *P = std::malloc(N);
  if (!P)
    throw std::bad_alloc();
  return P;
}

void cqDelete(void *P) noexcept {
  if (!P)
    return;
  switch (cqAllocMode()) {
  case CAM_Shuffle:
    return;
  case CAM_NoFree:
    return;
#if defined(__APPLE__)
  case CAM_Scribble:
    std::memset(P, 0xA5, malloc_size(P));
    return;
#endif
#if defined(__APPLE__)
  case CAM_Lifo: {
    size_t G = malloc_size(P);
    if (G <= CqMaxPooled && G % CqQuantum == 0 && G >= sizeof(void *)) {
      *static_cast<void **>(P) = CqFreeList[G / CqQuantum];
      CqFreeList[G / CqQuantum] = P;
      return;
    }
    std::free(P);
    return;
  }
#endif
  default:
    std::free(P);
    return;
  }
}
}  // namespace

void *operator new(std::size_t N) { return cqNew(N); }
void *operator new[](std::size_t N) { return cqNew(N); }
void *operator new(std::size_t N, const std::nothrow_t &) noexcept {
  try {
    return cqNew(N);
  } catch (...) {
    return nullptr;
  }
}
void *operator new[](std::size_t N, const std::nothrow_t &) noexcept {
  try {
    return cqNew(N);
  } catch (...) {
    return nullptr;
  }
}
void operator delete(void *P) noexcept { cqDelete(P); }
void operator delete[](void *P) noexcept { cqDelete(P); }
void operator delete(void *P, std::size_t) noexcept { cqDelete(P); }
void operator delete[](void *P, std::size_t) noexcept { cqDelete(P); }
void operator delete(void *P, const std::nothrow_t &) noexcept { cqDelete(P); }
void operator delete[](void *P, const std::nothrow_t &) noexcept { cqDelete(P); }
