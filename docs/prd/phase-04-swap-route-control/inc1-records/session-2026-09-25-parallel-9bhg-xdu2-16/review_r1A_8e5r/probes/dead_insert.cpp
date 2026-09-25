// dead_insert.cpp — REVIEW-ONLY (r1A on bd 8e5r), F-EA-5. A raw pointer container
// stores a pointer to an already-DELETED Value inertly; a scrub:: container
// DEREFERENCES it on insert (CallbackVH registration reads V->getContext()).
// Argument: "raw" or "scrub". Run under CQ_OPT_DEBUG_ALLOC=scribble (freed blocks
// overwritten with 0xA5, never reused) to make the dereference deterministic.
#include "llvm/IR/Instructions.h"
#include "ScrubOnDelete.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include <cstdio>
#include <cstring>
#include <set>
using namespace llvm;
int main(int argc, char **argv) {
  LLVMContext Ctx;
  Module M("m", Ctx);
  Type *I32 = Type::getInt32Ty(Ctx);
  Function *F = Function::Create(FunctionType::get(I32, {I32}, false), Function::ExternalLinkage, "f", M);
  BasicBlock *BB = BasicBlock::Create(Ctx, "e", F);
  IRBuilder<> B(BB);
  Value *Add = B.CreateAdd(F->getArg(0), B.getInt32(1));
  B.CreateRet(F->getArg(0));
  Instruction *Dead = cast<Instruction>(Add);
  Dead->eraseFromParent();  // `Dead` is now a pointer to a deleted Value.
  bool Scrub = argc > 1 && !std::strcmp(argv[1], "scrub");
  if (!Scrub) {
    std::set<Value *> Raw;
    Raw.insert(Dead);
    std::printf("raw std::set: inserted a deleted pointer inertly, size=%zu\n", Raw.size());
  } else {
    cq::TaintedValueSet S;
    S.insert(Dead);  // registers a CallbackVH on freed memory
    std::printf("scrub::Set: inserted a deleted pointer, size=%zu (reached only if the freed bytes were readable)\n", S.size());
  }
  return 0;
}
