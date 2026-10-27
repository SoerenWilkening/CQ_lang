// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include "llvm/IR/Module.h"

// Verify.h
namespace cq {
struct VerifyOptions { bool reference = false; };
void verifyLowered(const llvm::Module &, const VerifyOptions & = {});   // report_fatal_error naming check + instruction
}
