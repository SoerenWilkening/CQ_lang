// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include <cstdint>
#include <map>
#include <optional>
#include <string>

#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"

namespace llvm { class Loop; class ScalarEvolution; }

// Loops.h  (rule 14; classify is spine-owned)
namespace cq::loops {
enum class Case : uint8_t { ClassicalBound, ClassicalBoundQuantumExit, QuantumExit };
struct KOptions { std::map<std::string, unsigned> perFunction; std::optional<unsigned> global;
                  // §0 K2: -cq-k2=<fn>=<k>, -cq-k2-default=<k>; bus::K2 resolves them with CQ_K2 and the default 4096.
                  std::map<std::string, unsigned> k2PerFunction; std::optional<unsigned> k2Global; };
Case classify(const llvm::Loop &, const TaintInfo &, const Specialization &);
void lowerClassical(LoweringContext &, llvm::Loop &, Case);
void lowerCutoff(LoweringContext &, llvm::Loop &, unsigned K, std::optional<uint64_t> B);
std::optional<uint64_t> tripBound(const llvm::Loop &, llvm::ScalarEvolution &);
unsigned resolveK(const llvm::Function &, const KOptions &);   // flag, CQ_K, global, default 4
}
