#!/usr/bin/env python3
"""F-EB-4 / F-EB-5 / F-EB-10 on cq_debug_alloc.cpp: an unknown CQ_OPT_DEBUG_ALLOC
value (and `lifo` where it cannot be honoured) is a LOUD exit, never a silent
fallback; the scope of the replacement (non-aligned new/delete only) is stated."""
p = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2/ir-pass/tools/cq_debug_alloc.cpp"
s = open(p).read()


def rep(a, b):
    global s
    assert s.count(a) == 1, (a[:70], s.count(a))
    s = s.replace(a, b)


rep("""// cq_debug_alloc.cpp — the TEST-ONLY deterministic allocator, linked into the
// test drivers `cq-opt` and `cq-scrub-selftest` and NEVER into `libCQPass.so`.""",
    """// cq_debug_alloc.cpp — the TEST-ONLY deterministic allocator, linked into the
// test drivers `cq-opt-debugalloc` and `cq-scrub-selftest` and NEVER into
// `cq-opt` or `libCQPass.so`.""")
rep("""//   CQ_OPT_DEBUG_ALLOC=lifo    every freed block is handed to the very next
//                              allocation of the SAME size class (LIFO, exact
//                              class): MAXIMAL, deterministic address reuse.""",
    """//   CQ_OPT_DEBUG_ALLOC=lifo    every freed block is handed to the very next
//                              allocation of the SAME size class (LIFO, exact
//                              class): deterministic, maximal address reuse FOR
//                              THE BLOCKS IT MANAGES (see SCOPE below).""")
rep("""//   unset (or any other value) plain malloc/free — the shipped behaviour.""",
    """//   unset or empty             plain malloc/free — the shipped behaviour.
//   ANY OTHER VALUE            a LOUD exit (status 2, a message on stderr) at the
//                              first allocation — never a silent fallback
//                              (Rule-13 r1B F-EB-10: `LIFO` used to degrade to
//                              the system allocator and pass vacuously).""")
rep("""// ⚠ SCOPE. This file replaces the global `operator new`/`delete` of the TEST
// DRIVERS only.""", """// ⚠ SCOPE OF THE REPLACEMENT (Rule-13 r1B F-EB-5). Only the NON-ALIGNED global
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
// of the TEST DRIVERS only.""")
rep("""// under the same mode. `lifo` needs the platform's block-size query and is
// honoured on macOS only; elsewhere it degrades to the system allocator (a pin
// then passes without exercising reuse — it cannot go falsely RED).""",
    """// under the same mode. `lifo` needs the platform's block-size query and is
// honoured on macOS only; elsewhere it is a LOUD exit, like an unknown value — a
// silent degrade would let a pin pass VACUOUSLY GREEN (r1B F-EB-4: "cannot go
// falsely RED" was the wrong half to promise).""")
rep("""#include <cstdlib>
#include <cstring>
#include <new>
#if defined(__APPLE__)""", """#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <new>
#if defined(__APPLE__)""")
rep("""int cqAllocMode() {
  if (CqAllocModeV == CAM_Unset) {
    const char *E = std::getenv("CQ_OPT_DEBUG_ALLOC");
    CqAllocModeV = CAM_System;
    if (E && !std::strcmp(E, "nofree"))
      CqAllocModeV = CAM_NoFree;
#if defined(__APPLE__)
    if (E && !std::strcmp(E, "lifo"))
      CqAllocModeV = CAM_Lifo;
#endif
  }
  return CqAllocModeV;
}""", """[[noreturn]] void cqAllocRefuse(const char *E, const char *Why) {
  // No allocation here: this runs from inside `operator new`.
  std::fputs("cq_debug_alloc: CQ_OPT_DEBUG_ALLOC='", stderr);
  std::fputs(E, stderr);
  std::fputs("' ", stderr);
  std::fputs(Why, stderr);
  std::fputs(" — refusing to run (expected unset, 'lifo' or 'nofree')\\n", stderr);
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
}""")
open(p, "w").write(s)
print("ok")
