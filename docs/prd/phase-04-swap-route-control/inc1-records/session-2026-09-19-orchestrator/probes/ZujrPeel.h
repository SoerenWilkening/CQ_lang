// SCRATCH INSTRUMENT — wall-mapping for bd `zujr`. NOT FOR LANDING.
// `CQ_ZUJR_PEEL` is a comma-separated list of wall tags; `cqPeel("tag")` is true
// when that tag is listed, and the caller then SKIPS its decline so the NEXT
// wall becomes visible in one binary (LLVMContext::diagnose EXITS on the first
// DS_Error, so without this each wall costs a rebuild).
#ifndef CQ_ZUJR_PEEL_H
#define CQ_ZUJR_PEEL_H
#include <cstdlib>
#include <cstring>
#include "llvm/Support/raw_ostream.h"
namespace cq {
inline bool cqPeel(const char *Tag) {
  const char *E = ::getenv("CQ_ZUJR_PEEL");
  if (!E)
    return false;
  size_t TL = ::strlen(Tag);
  for (const char *P = E; *P;) {
    const char *Q = ::strchr(P, ',');
    size_t L = Q ? (size_t)(Q - P) : ::strlen(P);
    if (L == TL && ::strncmp(P, Tag, TL) == 0) {
      llvm::errs() << "CQ_ZUJR_PEEL: skipping wall [" << Tag << "]\n";
      return true;
    }
    if (!Q)
      break;
    P = Q + 1;
  }
  return false;
}
}  // namespace cq
#endif
