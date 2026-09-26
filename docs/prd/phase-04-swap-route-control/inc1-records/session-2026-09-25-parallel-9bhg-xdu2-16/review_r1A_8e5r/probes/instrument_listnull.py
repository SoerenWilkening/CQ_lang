#!/usr/bin/env python3
"""REVIEW-ONLY, applied AFTER instrument_scrub.py: log every ThetaCalls/PhiCalls/
MeasureCalls/PhaseCalls slot NULLED by a deletion (a user intrinsic call deleted while
still listed, i.e. with no prior erase_value), with the DELETER's backtrace (slide-
adjusted return addresses, resolved offline with atos). The owners (lowerRotations,
lowerMeasures) are expected; any other deleter is a vanished user intrinsic that the
unfixed binary would have left as a dangling slot for its owner to dereference."""
import sys
p = sys.argv[1]
s = open(p).read()
a = '''        if (Slot && asValue(Slot) == V) {
          Slot = nullptr;
          DeadAddrs.insert(V);
        }'''
assert s.count(a) == 1
s = s.replace(a, '''        if (Slot && asValue(Slot) == V) {
          Slot = nullptr;
          DeadAddrs.insert(V);
          if (std::FILE *F = reviewLogF()) {
            void *BT[14];
            int NF = ::backtrace(BT, 14);
            std::fprintf(F, "LISTNULL");
            for (int K = 2; K < NF; ++K)
              std::fprintf(F, " 0x%lx", (unsigned long)((uintptr_t)BT[K] -
                                     (uintptr_t)_dyld_get_image_vmaddr_slide(0)));
            std::fprintf(F, "\\n");
            std::fflush(F);
          }
        }''')
b = '#include <mach-o/dyld.h>\n'
assert s.count(b) == 1
s = s.replace(b, b + '#include <execinfo.h>\n')
open(p, 'w').write(s)
print("ok")
