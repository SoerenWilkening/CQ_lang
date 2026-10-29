// cq-w0-taint: runs computeTaint on one .ll file and prints TaintInfo::print (the -cq-dump-taint
// text). Used by check_taint.py; computeTaint runs twice to check it is a pure function of the
// module (cq-5k5): both dumps must be identical.
// --values (cq-bxc4): also print, per specialization, the field mask of every non-void instruction
// and whether each block is control tainted, for corpus-wide taint diffs.
#include "cq/Taint.h"

#include "llvm/IR/InstIterator.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ModuleSlotTracker.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

int main(int argc, char **argv) {
  bool values = argc == 3 && llvm::StringRef(argv[1]) == "--values";
  if (argc != 2 && !values) {
    llvm::errs() << "usage: cq_taint_dump [--values] <module.ll>\n";
    return 2;
  }
  llvm::LLVMContext Ctx;
  llvm::SMDiagnostic Err;
  std::unique_ptr<llvm::Module> M = llvm::parseIRFile(argv[argc - 1], Err, Ctx);
  if (!M) {
    Err.print(argv[0], llvm::errs());
    return 2;
  }
  std::string a, b;
  {
    llvm::raw_string_ostream os(a);
    cq::computeTaint(*M, {}).print(os);
  }
  {
    llvm::raw_string_ostream os(b);
    cq::computeTaint(*M, {}).print(os);
  }
  if (a != b) {
    llvm::errs() << "cq_taint_dump: computeTaint is not a pure function of the module\n";
    return 1;
  }
  llvm::outs() << a;
  if (values) {
    cq::TaintInfo T = cq::computeTaint(*M, {});
    llvm::ModuleSlotTracker MST(M.get());
    for (const cq::Specialization &S : T.specializations()) {
      llvm::outs() << "spec @" << S.F->getName() << " mask=";
      llvm::outs() << S.mask;
      llvm::outs() << (S.ctl ? " ctl" : "") << "\n";
      MST.incorporateFunction(*S.F);
      for (llvm::BasicBlock &BB : *S.F) {
        llvm::outs() << "  block ";
        BB.printAsOperand(llvm::outs(), false, MST);
        llvm::outs() << " ct=" << T.controlTainted(&BB, S) << "\n";
        for (llvm::Instruction &I : BB) {
          if (I.getType()->isVoidTy())
            continue;
          llvm::outs() << "    ";
          I.printAsOperand(llvm::outs(), false, MST);
          llvm::outs() << " ";
          for (bool b : T.fieldMask(&I, S))
            llvm::outs() << (b ? 'q' : 'c');
          llvm::outs() << "\n";
        }
      }
    }
  }
  return 0;
}
