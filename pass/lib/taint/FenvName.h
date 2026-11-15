// Rule 23's <fenv.h> functions by symbol name, the one test taint, the spine's classify and eff-fenv use (cq-ten4).
// Header-only: the C oracle links taint as the single unit Taint.cpp (checker/cqcheck/oracle.py PASS_SOURCES).
#pragma once

#include "llvm/ADT/StringRef.h"

namespace cq::taint_detail {

// The C name a function symbol stands for: a Mach-O asm label "\01_n" names C function n (cq-my17).
inline llvm::StringRef cFunctionName(llvm::StringRef sym) { return sym.starts_with("\01_") ? sym.drop_front(2) : sym; }

// The index of the C17 7.6 function (C name or asm label) in kFenvNames, or -1. Not the trap-enable extensions
// (feenableexcept, fedisableexcept, fegetexcept): no musl body, rule 27 like any bodiless callee (CR rule 23, cq-hzji).
inline constexpr const char *kFenvNames[] = {"feclearexcept", "fegetexceptflag", "feraiseexcept", "fesetexceptflag",
                                             "fetestexcept",  "fegetround",      "fesetround",    "fegetenv",
                                             "feholdexcept",  "fesetenv",        "feupdateenv"};
inline int fenvIndex(llvm::StringRef sym) {
  llvm::StringRef n = cFunctionName(sym);
  for (int i = 0; i < int(sizeof(kFenvNames) / sizeof(kFenvNames[0])); ++i)
    if (n == kFenvNames[i])
      return i;
  return -1;
}
inline bool isFenvName(llvm::StringRef sym) { return fenvIndex(sym) >= 0; }

} // namespace cq::taint_detail
