// cq_debug_alloc.cpp — the TEST-ONLY deterministic allocator, linked into the
// test drivers `cq-opt-debugalloc` and `cq-scrub-selftest` and NEVER into
// `cq-opt` or `libCQPass.so`.
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
//                              class): deterministic, maximal address reuse FOR
//                              THE BLOCKS IT MANAGES (see SCOPE below).
//   CQ_OPT_DEBUG_ALLOC=nofree  nothing is ever freed, so no address is ever
//                              reused: the no-aliasing REFERENCE. (A deleted
//                              object's bytes stay mapped, so a dereference of
//                              a stale key reads the dead object — whose parent
//                              pointer `removeFromParent` has already nulled.)
//   unset or empty             plain malloc/free — the shipped behaviour.
//   ANY OTHER VALUE            a LOUD exit (status 2, a message on stderr) at the
//                              first allocation — never a silent fallback
//                              (Rule-13 r1B F-EB-10: `LIFO` used to degrade to
//                              the system allocator and pass vacuously).
//
// ⚠ SCOPE OF THE REPLACEMENT (Rule-13 r1B F-EB-5). Only the NON-ALIGNED global
// `operator new`/`new[]`/`nothrow` and their deletes are replaced. LLVM 19's
// `allocate_buffer` uses ALIGNED `operator new(size_t, align_val_t)` under C++17
// (DenseMap/DenseSet buckets, StringMap entries, BumpPtrAllocator slabs), and
// `SmallVector` / big-mode `SmallPtrSet` use `malloc` — those stay on the system
// allocator in every mode. What IS pooled is this defect class's population:
// `User`/`Instruction` objects (`::operator new(Size + uses)`), `BasicBlock`s,
// std node containers and the `ScrubOnDelete.h` hooks. So "maximal reuse" means
// maximal among THOSE blocks, not every heap byte.
//
// ⚠ SCOPE OF THE BINARIES. This file replaces the global `operator new`/`delete`
// of the TEST DRIVERS only. `libCQPass.so` — what `opt -load-pass-plugin` and every user of
// the pass loads — contains none of it. With the variable unset every allocation
// is exactly one `malloc` and every free one `free`, and the
// `cq-opt-equivalence` gate (cq-opt vs opt+plugin: stdout, stderr and exit code)
// is the witness that this default path changed nothing observable.
//
// ⚠ THE MODE IS FIXED AT THE FIRST ALLOCATION (static-init time, before `main`),
// from the environment, so every block the process ever frees was allocated
// under the same mode. `lifo` needs the platform's block-size query and is
// honoured on macOS only; elsewhere it is a LOUD exit, like an unknown value — a
// silent degrade would let a pin pass VACUOUSLY GREEN (r1B F-EB-4: "cannot go
// falsely RED" was the wrong half to promise).
// ⚠ In `lifo` mode a freed block's FIRST WORD holds the free-list link, so a
// stale dereference reads a pointer there; that is part of what makes a UAF read
// crash deterministically, and it is not a correctness property of anything.

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <new>
#if defined(__APPLE__)
#include <malloc/malloc.h>
#endif

namespace {
enum CqAllocMode : int { CAM_Unset = -1, CAM_System = 0, CAM_NoFree = 1, CAM_Lifo = 2 };
int CqAllocModeV = CAM_Unset;

[[noreturn]] void cqAllocRefuse(const char *E, const char *Why) {
  // No allocation here: this runs from inside `operator new`.
  std::fputs("cq_debug_alloc: CQ_OPT_DEBUG_ALLOC='", stderr);
  std::fputs(E, stderr);
  std::fputs("' ", stderr);
  std::fputs(Why, stderr);
  std::fputs(" — refusing to run (expected unset, 'lifo' or 'nofree')\n", stderr);
  std::_Exit(2);
}

int cqAllocMode() {
  if (CqAllocModeV == CAM_Unset) {
    const char *E = std::getenv("CQ_OPT_DEBUG_ALLOC");
    CqAllocModeV = CAM_System;
    if (!E || !*E) {
      // the shipped behaviour
    } else if (!std::strcmp(E, "nofree")) {
      CqAllocModeV = CAM_NoFree;
    } else if (!std::strcmp(E, "lifo")) {
#if defined(__APPLE__)
      CqAllocModeV = CAM_Lifo;
#else
      cqAllocRefuse(E, "is not supported on this platform (no malloc_size)");
#endif
    } else {
      cqAllocRefuse(E, "is not a known mode");
    }
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
  case CAM_NoFree:
    return;
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
