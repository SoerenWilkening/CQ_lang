// cq-w0-abi acceptance over the pinned corpus: for every function named cqrt_*, cq_template_* or
// __cq_q_* in examples/*/*.lowered.ll, the parser accepts it and name(parse(sym)) == sym; for every
// declared template and core gate, declare() yields the same function type (FunctionType ignores
// signext/zeroext, which CR §1.2 allows either way).
#include "cq/Abi.h"

#include <cstdio>
#include <set>
#include <string>
#include <vector>

#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

int main(int argc, char **argv) {
  if (argc != 2) {
    errs() << "usage: abi_corpus <CQ_spec>/examples\n";
    return 2;
  }
  std::vector<std::string> files;
  std::error_code ec;
  for (sys::fs::directory_iterator d(argv[1], ec), e; d != e && !ec; d.increment(ec)) {
    std::string dir = d->path();
    for (sys::fs::directory_iterator f(dir, ec), fe; f != fe && !ec; f.increment(ec))
      if (StringRef(f->path()).ends_with(".lowered.ll"))
        files.push_back(f->path());
  }
  std::sort(files.begin(), files.end());
  if (files.empty()) {
    errs() << "abi_corpus: no .lowered.ll under " << argv[1] << "\n";
    return 1;
  }

  unsigned fails = 0, declTmpl = 0, declCore = 0, declClone = 0, defClone = 0;
  std::set<std::string> uniqTmpl, uniqCore, uniqClone;
  for (const std::string &path : files) {
    LLVMContext C;
    SMDiagnostic err;
    std::unique_ptr<Module> M = parseAssemblyFile(path, err, C);
    if (!M) {
      err.print("abi_corpus", errs());
      ++fails;
      continue;
    }
    Module scratch("scratch", C);
    for (Function &F : *M) {
      StringRef n = F.getName();
      auto bad = [&](const Twine &why) {
        errs() << "FAIL " << sys::path::filename(path) << " @" << n << ": " << why << "\n";
        ++fails;
      };
      if (n.starts_with("cq_template_")) {
        bool unc = false;
        auto s = cq::abi::parseTemplate(n, &unc);
        if (!s) { bad("parseTemplate rejected"); continue; }
        if (cq::abi::name(*s, unc) != n) { bad("name(parse) = " + cq::abi::name(*s, unc)); continue; }
        if (F.isDeclaration()) {
          ++declTmpl;
          uniqTmpl.insert(n.str());
          FunctionCallee fc = cq::abi::declare(scratch, *s, unc);
          if (fc.getFunctionType() != F.getFunctionType()) {
            std::string a, b;
            raw_string_ostream(a) << *fc.getFunctionType();
            raw_string_ostream(b) << *F.getFunctionType();
            bad("declare() type " + a + " vs corpus " + b);
          }
        }
      } else if (n.starts_with("cqrt_")) {
        auto s = cq::abi::parseCore(n);
        if (!s) { bad("parseCore rejected"); continue; }
        if (cq::abi::name(*s) != n) { bad("name(parse) = " + cq::abi::name(*s)); continue; }
        if (F.isDeclaration()) {
          ++declCore;
          uniqCore.insert(n.str());
          FunctionCallee fc = cq::abi::declare(scratch, *s);
          if (fc.getFunctionType() != F.getFunctionType()) {
            std::string a, b;
            raw_string_ostream(a) << *fc.getFunctionType();
            raw_string_ostream(b) << *F.getFunctionType();
            bad("declare() type " + a + " vs corpus " + b);
          }
        }
      } else if (n.starts_with("__cq_q_")) {
        auto s = cq::abi::parseClone(n);
        if (!s) { bad("parseClone rejected"); continue; }
        if (cq::abi::name(*s) != n) { bad("name(parse) = " + cq::abi::name(*s)); continue; }
        uniqClone.insert(n.str());
        (F.isDeclaration() ? declClone : defClone)++;
      }
    }
  }
  outs() << "abi_corpus: " << files.size() << " lowered files; declarations checked: " << declTmpl
         << " template (" << uniqTmpl.size() << " symbols), " << declCore << " core (" << uniqCore.size()
         << " symbols), " << declClone << " clone; clone definitions round-tripped: " << defClone << " ("
         << uniqClone.size() << " clone symbols); failures: " << fails << "\n";
  return fails ? 1 : 0;
}
