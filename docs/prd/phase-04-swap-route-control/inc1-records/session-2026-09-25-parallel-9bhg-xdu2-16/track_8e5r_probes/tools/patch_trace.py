#!/usr/bin/env python3
"""Patch trace_src/ir-pass/include/ScrubOnDelete.h so KeyHook::deleted() prints
an unslid backtrace when CQ_SCRUB_TRACE is set (instrument only; never committed).
A callback fires only for a key NOBODY scrubbed explicitly (an explicit erase
disarms the hook first), so every trace is an erase site that relied on nothing
before bd 8e5r — the dynamic half of the j8sk enumeration."""
p = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r/trace_src/ir-pass/include/ScrubOnDelete.h"
s = open(p).read()
inc = '#include <utility>\n'
assert s.count(inc) == 1
s = s.replace(inc, inc + '''#include <execinfo.h>
#include <mach-o/dyld.h>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
inline void cqScrubTrace(const char *Kind) {
  static int On = -1;
  if (On < 0)
    On = std::getenv("CQ_SCRUB_TRACE") != nullptr;
  if (!On)
    return;
  void *BT[28];
  int N = backtrace(BT, 28);
  intptr_t Slide = _dyld_get_image_vmaddr_slide(0);
  std::fprintf(stderr, "SCRUB-TRACE %s", Kind);
  for (int i = 1; i < N; ++i)
    std::fprintf(stderr, " 0x%llx", (unsigned long long)((intptr_t)BT[i] - Slide));
  std::fprintf(stderr, "\\n");
}
''', 1)
# tag each Owner kind
for old, kind in [("      if (S.count(toStore(static_cast<KeyArg>(V))))\n        Dead.insert(V);", None)]:
    pass
old = "    setValPtr(nullptr);\n    O->keyDeleted(V);"
assert s.count(old) == 1
s = s.replace(old, "    setValPtr(nullptr);\n    cqScrubTrace(\"key\");\n    O->keyDeleted(V);")
open(p, "w").write(s)
print("patched")
