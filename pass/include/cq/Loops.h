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
struct KOptions { std::map<std::string, unsigned> perFunction; std::optional<unsigned> global; };
Case classify(const llvm::Loop &, const TaintInfo &, const Specialization &);
void lowerClassical(LoweringContext &, llvm::Loop &, Case);
void lowerCutoff(LoweringContext &, llvm::Loop &, unsigned K, std::optional<uint64_t> B);
std::optional<uint64_t> tripBound(const llvm::Loop &, llvm::ScalarEvolution &);
unsigned resolveK(const llvm::Function &, const KOptions &);   // flag, CQ_K, global, default 4
}
