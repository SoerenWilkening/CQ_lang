// cq-w0-taint: runs computeTaint on one .ll file and prints TaintInfo::print (the -cq-dump-taint
// text). Used by check_taint.py; computeTaint runs twice to check it is a pure function of the
// module (cq-5k5): both dumps must be identical.
#include "cq/Taint.h"

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

int main(int argc, char **argv) {
  if (argc != 2) {
    llvm::errs() << "usage: cq_taint_dump <module.ll>\n";
    return 2;
  }
  llvm::LLVMContext Ctx;
  llvm::SMDiagnostic Err;
  std::unique_ptr<llvm::Module> M = llvm::parseIRFile(argv[1], Err, Ctx);
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
  return 0;
}
