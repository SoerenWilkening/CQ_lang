// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include <cstdint>
#include <string>

#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"

// Common.h
namespace cq {
[[noreturn]] void unimplemented(llvm::StringRef what, const llvm::Value *at = nullptr); // "cq: unimplemented: ..."
[[noreturn]] void internalError(llvm::StringRef what, const llvm::Value *at = nullptr);
enum class Kind : uint8_t { Int, Fp, BFloat };
struct RailType { Kind kind; unsigned bits; };      // i<N> (N >= 1), f16, f32, f64, f80, bf16 (BFloat: bits == 16)
RailType railTypeOf(llvm::Type *);                  // iN/half/float/double/x86_fp80/bfloat
llvm::Type *irTypeOf(llvm::LLVMContext &, RailType);
llvm::IntegerType *handleTy(llvm::LLVMContext &);   // i32
using Mask = std::string;                           // CR §1.4 digits, '1' = quantum, left to right
struct Operand { llvm::Value *v; bool handle; };    // a rail handle, or a classical value of the new IR
// cq-my17 (rule 16, 99): F is a library function LLVM knows (TargetLibraryInfo for the module's triple,
// prototype checked), its LibFunc in lf; a Mach-O asm label "\01_n" names C function n.
bool libFuncOf(const llvm::Function &F, llvm::LibFunc &lf);
// cq-z6q1 (CR rule 14; 189): the exit of the loop headed by `header` from block `exiting` has an exit count
// SCEV computes (its symbolic maximum): a classical exit test that bounds the trip count. A classical exit
// whose count LLVM cannot compute (189's NULL read from memory) is no classical bound. Its own analyses.
bool exitCountKnown(const llvm::BasicBlock &header, const llvm::BasicBlock &exiting);
}
