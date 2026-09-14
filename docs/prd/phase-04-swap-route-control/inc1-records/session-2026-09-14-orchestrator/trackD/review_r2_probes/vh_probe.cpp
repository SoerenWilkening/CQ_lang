// Decisive measurement for bd 3d8q F-D1-2: what does LLVM 19's WeakVH do on RAUW?
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/ValueHandle.h"
#include <cstdio>
using namespace llvm;
int main() {
  LLVMContext C; Module M("m", C);
  auto *FT = FunctionType::get(Type::getInt32Ty(C), {Type::getInt32Ty(C)}, false);
  auto *F = Function::Create(FT, Function::ExternalLinkage, "f", &M);
  auto *BB = BasicBlock::Create(C, "entry", F);
  IRBuilder<> B(BB);
  Value *Arg = F->getArg(0);
  auto *A = cast<Instruction>(B.CreateAdd(Arg, B.getInt32(1), "a"));
  auto *Z = cast<Instruction>(B.CreateAdd(Arg, B.getInt32(2), "z"));
  B.CreateRet(A);
  WeakVH W(A); WeakTrackingVH T(A);
  printf("before      : WeakVH=%p WeakTrackingVH=%p  A=%p Z=%p\n",
         (void*)(Value*)W, (void*)(Value*)T, (void*)A, (void*)Z);
  A->replaceAllUsesWith(Z);                 // RAUW to ANOTHER INSTRUCTION
  printf("after RAUW  : WeakVH=%s  WeakTrackingVH=%s\n",
         (Value*)W == nullptr ? "NULL" : ((Value*)W == A ? "still A (no tracking)" : "moved to Z"),
         (Value*)T == nullptr ? "NULL" : ((Value*)T == A ? "still A" : "moved to Z"));
  // now RAUW to a NON-INSTRUCTION (a Constant) — the outcome-3 case
  WeakVH W2(Z); WeakTrackingVH T2(Z);
  Z->replaceAllUsesWith(ConstantInt::get(Type::getInt32Ty(C), 7));
  printf("after RAUW→const: WeakVH=%s  WeakTrackingVH=%s\n",
         (Value*)W2 == nullptr ? "NULL" : ((Value*)W2 == Z ? "still Z (no tracking)" : "moved to the constant"),
         (Value*)T2 == nullptr ? "NULL" : ((Value*)T2 == Z ? "still Z" : "moved to the constant"));
  return 0;
}
