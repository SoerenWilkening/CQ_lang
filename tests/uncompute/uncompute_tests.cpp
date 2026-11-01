// Unit tests of the uncompute spine (cq-w0-uncompute, CR rules 5, 6, 7).
//
// Each case parses a forward IR (what the spine would have emitted, with no _unc and no free), drives
// Uncompute.h the way a construction does (records, roles, noted gates, flushes, scopes) and compares
// the function body after the flush line by line. The ex* cases rebuild a corpus example's forward
// code and expect exactly its reference lowered.ll body (comments stripped).
//
//   uncompute_tests            run every positive case
//   uncompute_tests <case>     run one case (positive or fatal)
#include <cstdio>
#include <cstdlib>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "cq/Abi.h"
#include "cq/Common.h"
#include "cq/Uncompute.h"

#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace cq;

namespace {

const char *kDecls = R"(
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_f64(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare i32 @cqrt_measure_i32(i32)
declare double @cqrt_measure_f64(i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_xorc_i32(i32, i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_store_i32_hl(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare i32 @cqrt_qram_realloc_i32(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare i32 @cq_template_fadd_f64_hl(i32, double)
)";

int failures = 0;

struct Fx {
  LLVMContext C;
  std::unique_ptr<Module> M;
  Function *F = nullptr;
  Uncompute U;

  explicit Fx(const std::string &fn) {
    SMDiagnostic err;
    M = parseAssemblyString(std::string(kDecls) + fn, err, C);
    if (!M) {
      err.print("uncompute_tests", errs());
      std::exit(2);
    }
    for (Function &f : *M)
      if (!f.isDeclaration()) {
        F = &f;
        break;
      }
  }

  Instruction *I(StringRef name) {
    for (Instruction &i : instructions(F)) {
      if (i.getName() == name)
        return &i;
      if (i.hasName() || i.getType()->isVoidTy())
        continue;
      std::string s;
      raw_string_ostream os(s);
      i.printAsOperand(os, false);
      if (os.str() == ("%" + name).str())
        return &i; // a numbered value
    }
    errs() << "no instruction %" << name << "\n";
    std::exit(2);
  }
  // The n-th call (0-based) to callee, for void calls that have no name.
  CallInst *call(StringRef callee, unsigned n = 0) {
    for (Instruction &i : instructions(F))
      if (auto *c = dyn_cast<CallInst>(&i))
        if (c->getCalledFunction() && c->getCalledFunction()->getName() == callee && n-- == 0)
          return c;
    errs() << "no call " << callee << "\n";
    std::exit(2);
  }
  ReturnInst *ret(unsigned n = 0) {
    for (Instruction &i : instructions(F))
      if (auto *r = dyn_cast<ReturnInst>(&i))
        if (n-- == 0)
          return r;
    std::exit(2);
  }
  // Records a template call; shape gives h (handle) or l (literal) per argument.
  RailId T(StringRef name, StringRef shape, abi::TemplateSpec spec = {}) {
    auto *c = cast<CallInst>(I(name));
    std::vector<Operand> ops;
    for (unsigned i = 0; i < c->arg_size(); ++i)
      ops.push_back({c->getArgOperand(i), shape[i] == 'h'});
    return U.recordTemplate(c, spec, ops);
  }
  RailId S(StringRef name) { return U.recordSeed(cast<CallInst>(I(name))); }
  RailId id(StringRef name) { return U.idOf(I(name)); }
  RailId core(CallInst *c, abi::Core op, StringRef shape, RailId out, bool ctl = false) {
    std::vector<Operand> ops;
    for (unsigned i = 0; i < c->arg_size(); ++i)
      ops.push_back({c->getArgOperand(i), shape[i] == 'h'});
    abi::CoreSpec spec{op, {Kind::Int, 32}, ctl};
    return U.recordCore(c, spec, ops, out);
  }
  // A theta-minted register: seed, rotated, a user register from here on.
  RailId reg(StringRef name, unsigned ryIndex) {
    RailId r = S(name);
    U.setRole(r, Role::UserRegister);
    return r;
  }

  void check(const char *tc, const std::vector<std::string> &want) {
    // CQ_UNC_DUMP=<dir>: write the module, for an independent run of -passes=cq-verify over it.
    if (const char *dir = std::getenv("CQ_UNC_DUMP")) {
      std::error_code ec;
      raw_fd_ostream os(std::string(dir) + "/" + tc + ".ll", ec);
      M->print(os, nullptr);
    }
    std::vector<std::string> got;
    for (Instruction &i : instructions(F)) {
      std::string s;
      raw_string_ostream os(s);
      i.print(os);
      os.flush();
      size_t b = s.find_first_not_of(' ');
      got.push_back(s.substr(b));
    }
    if (got == want)
      return;
    ++failures;
    errs() << "FAIL " << tc << "\n  want:\n";
    for (auto &w : want)
      errs() << "    " << w << "\n";
    errs() << "  got:\n";
    for (auto &g : got)
      errs() << "    " << g << "\n";
  }
};

Operand H(Value *v) { return {v, true}; }

abi::TemplateSpec tspec(const char *op, unsigned bits, const char *shape = "") {
  abi::TemplateSpec s;
  s.op = op;
  s.w = {Kind::Int, bits};
  s.shape = shape;
  return s;
}

// ---- rule 5: order ---------------------------------------------------------------------------------

void reverse_dependency_order() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)
  %r = call i32 @cq_template_sub_i32(i32 %q, i32 %p)
  %m = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("p", "hl");
  f.T("q", "hl");
  f.U.setRole(f.T("r", "hh"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)",
                        "%r = call i32 @cq_template_sub_i32(i32 %q, i32 %p)",
                        "call void @cq_template_mul_i32_hl_unc(i32 %q, i32 %p, i32 3)",
                        "call void @cqrt_free(i32 %q)",
                        "call void @cq_template_add_i32_hl_unc(i32 %p, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %p)",
                        "%m = call i32 @cqrt_measure_i32(i32 %r)",
                        "ret i32 %m",
                    });
}

void independent_most_recent_first() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %q = call i32 @cq_template_add_i32_hl(i32 %x, i32 2)
  %r = call i32 @cq_template_add_i32(i32 %p, i32 %q)
  %m = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("p", "hl");
  f.T("q", "hl");
  f.U.setRole(f.T("r", "hh"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%q = call i32 @cq_template_add_i32_hl(i32 %x, i32 2)",
                        "%r = call i32 @cq_template_add_i32(i32 %p, i32 %q)",
                        "call void @cq_template_add_i32_hl_unc(i32 %q, i32 %x, i32 2)",
                        "call void @cqrt_free(i32 %q)",
                        "call void @cq_template_add_i32_hl_unc(i32 %p, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %p)",
                        "%m = call i32 @cqrt_measure_i32(i32 %r)",
                        "ret i32 %m",
                    });
}

// ---- rule 5: no _unc before a read of its rail -------------------------------------------------

void last_use_ir() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)
  %mq = call i32 @cqrt_measure_i32(i32 %q)
  %s = call i32 @cq_template_shl_i32_hl(i32 %p, i32 2)
  %ms = call i32 @cqrt_measure_i32(i32 %s)
  %sum = add i32 %mq, %ms
  ret i32 %sum
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("p", "hl");
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.setRole(f.T("s", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)",
                        "%mq = call i32 @cqrt_measure_i32(i32 %q)",
                        "%s = call i32 @cq_template_shl_i32_hl(i32 %p, i32 2)",
                        "call void @cq_template_add_i32_hl_unc(i32 %p, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %p)",
                        "%ms = call i32 @cqrt_measure_i32(i32 %s)",
                        "%sum = add i32 %mq, %ms",
                        "ret i32 %sum",
                    });
}

void last_use_noted() {
  // A consumer that is not an IR user of the handle (a slot load, a pushed word) is a use too.
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)
  %mq = call i32 @cqrt_measure_i32(i32 %q)
  %later = add i32 %a0, 7
  ret i32 %mq
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  RailId p = f.T("p", "hl");
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.noteUse(p, f.I("later"));
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)",
                        "%mq = call i32 @cqrt_measure_i32(i32 %q)",
                        "%later = add i32 %a0, 7",
                        "call void @cq_template_add_i32_hl_unc(i32 %p, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %p)",
                        "ret i32 %mq",
                    });
}

// ---- rule 5: the non-diagonal invariant ----------------------------------------------------------

void nondiagonal_before() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, double %th2) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)
  call void @cqrt_ry_i32(i32 %x, double %th2)
  %m = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  f.T("p", "hl");
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 1));
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)",
                        "call void @cq_template_add_i32_hl_unc(i32 %p, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %p)",
                        "call void @cqrt_ry_i32(i32 %x, double %th2)",
                        "%m = call i32 @cqrt_measure_i32(i32 %q)",
                        "ret i32 %m",
                    });
}

void nondiagonal_kept() {
  // p is read after a second Ry on its source x: it cannot be cleaned (A4: KeptEntangled, never
  // freed). The seed y was rotated but its role was left Seed: a rotated seed is never freed either.
  const char *ir = R"(
define i32 @f(i32 %a0, i32 %a1, double %th, double %th2) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %y = call i32 @cqrt_alloc_i32(i32 %a1)
  call void @cqrt_ry_i32(i32 %y, double %th)
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  call void @cqrt_ry_i32(i32 %x, double %th2)
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)
  %r = call i32 @cq_template_add_i32(i32 %q, i32 %y)
  %m = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m
})";
  Fx f(ir);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  RailId y = f.S("y");
  f.U.noteNonDiagonal(y, f.call("cqrt_ry_i32", 1));
  f.T("p", "hl");
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 2));
  f.T("q", "hl");
  f.U.setRole(f.T("r", "hh"), Role::Measured);
  f.U.flushAtExit(f.ret());
  // q is clean: it reads p, which is never touched; p and y stay.
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%y = call i32 @cqrt_alloc_i32(i32 %a1)",
                        "call void @cqrt_ry_i32(i32 %y, double %th)",
                        "%p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "call void @cqrt_ry_i32(i32 %x, double %th2)",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)",
                        "%r = call i32 @cq_template_add_i32(i32 %q, i32 %y)",
                        "call void @cq_template_mul_i32_hl_unc(i32 %q, i32 %p, i32 3)",
                        "call void @cqrt_free(i32 %q)",
                        "%m = call i32 @cqrt_measure_i32(i32 %r)",
                        "ret i32 %m",
                    });
}

void nondiagonal_transitive() {
  // g's last read is h's forward, before the Ry on x; but h is live after the Ry and h's _unc reads
  // g, so g must outlive h's _unc: g is past the Ry and stays (KeptEntangled); h is clean.
  Fx f(R"(
define i32 @f(i32 %a0, double %th, double %th2) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %g = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %h = call i32 @cq_template_mul_i32_hl(i32 %g, i32 3)
  call void @cqrt_ry_i32(i32 %x, double %th2)
  %s = call i32 @cq_template_shl_i32_hl(i32 %h, i32 1)
  %m = call i32 @cqrt_measure_i32(i32 %s)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  f.T("g", "hl");
  f.T("h", "hl");
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 1));
  f.U.setRole(f.T("s", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%g = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%h = call i32 @cq_template_mul_i32_hl(i32 %g, i32 3)",
                        "call void @cqrt_ry_i32(i32 %x, double %th2)",
                        "%s = call i32 @cq_template_shl_i32_hl(i32 %h, i32 1)",
                        "call void @cq_template_mul_i32_hl_unc(i32 %h, i32 %g, i32 3)",
                        "call void @cqrt_free(i32 %h)",
                        "%m = call i32 @cqrt_measure_i32(i32 %s)",
                        "ret i32 %m",
                    });
}

void rule10_flag_kept() {
  // Rule 10: a flag that read the rotated register stays allocated.
  Fx f(R"(
define i32 @f(i32 %a0, double %th, double %th2) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %fl = call i32 @cq_template_icmp_eq_i32_hl(i32 %x, i32 3)
  call void @cqrt_ry_i32_controlled(i32 %fl, i32 %x, double %th2)
  %m = call i32 @cqrt_measure_i32(i32 %x)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("fl", "hl");
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32_controlled"));
  f.U.setRole(x, Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%fl = call i32 @cq_template_icmp_eq_i32_hl(i32 %x, i32 3)",
                        "call void @cqrt_ry_i32_controlled(i32 %fl, i32 %x, double %th2)",
                        "%m = call i32 @cqrt_measure_i32(i32 %x)",
                        "ret i32 %m",
                    });
}

void measure_is_not_a_barrier() {
  // A computational-basis measurement of a source is not a non-diagonal gate (42): p is uncomputed
  // after its last read even though x was measured in between.
  Fx f(R"(
define i32 @f(i32 %a0, i32 %a1, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %y = call i32 @cqrt_alloc_i32(i32 %a1)
  call void @cqrt_ry_i32(i32 %y, double %th)
  %p = call i32 @cq_template_add_i32(i32 %x, i32 %y)
  %mx = call i32 @cqrt_measure_i32(i32 %x)
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 5)
  %mq = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %mq
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  RailId y = f.reg("y", 1);
  f.U.noteNonDiagonal(y, f.call("cqrt_ry_i32", 1));
  f.T("p", "hh");
  f.U.setRole(x, Role::Measured);
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%y = call i32 @cqrt_alloc_i32(i32 %a1)",
                        "call void @cqrt_ry_i32(i32 %y, double %th)",
                        "%p = call i32 @cq_template_add_i32(i32 %x, i32 %y)",
                        "%mx = call i32 @cqrt_measure_i32(i32 %x)",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 5)",
                        "call void @cq_template_add_i32_unc(i32 %p, i32 %x, i32 %y)",
                        "call void @cqrt_free(i32 %p)",
                        "%mq = call i32 @cqrt_measure_i32(i32 %q)",
                        "ret i32 %mq",
                    });
}

// ---- rule 6 -------------------------------------------------------------------------------------

void rule6_sequence() {
  Fx f(R"(
define i32 @f(i32 %a0, i32 %a1, double %th, double %th2) {
  %y = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %y, double %th)
  %x = call i32 @cqrt_alloc_i32(i32 %a1)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %z = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %y2 = call i32 @cq_template_add_i32(i32 %y, i32 %z)
  call void @cqrt_ry_i32(i32 %y2, double %th2)
  %m = call i32 @cqrt_measure_i32(i32 %y2)
  ret i32 %m
})");
  RailId y = f.reg("y", 0);
  f.U.noteNonDiagonal(y, f.call("cqrt_ry_i32", 0));
  RailId x = f.reg("x", 1);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 1));
  f.T("z", "hl");
  RailId y2 = f.T("y2", "hh");
  f.U.setRole(y2, Role::UserRegister);
  f.U.cleanupBijective(y, tspec("sub", 32), {H(f.I("y2")), H(f.I("z"))});
  f.U.noteNonDiagonal(y2, f.call("cqrt_ry_i32", 2));
  f.U.setRole(y2, Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%y = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %y, double %th)",
                        "%x = call i32 @cqrt_alloc_i32(i32 %a1)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%z = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%y2 = call i32 @cq_template_add_i32(i32 %y, i32 %z)",
                        "%1 = call i32 @cq_template_sub_i32(i32 %y2, i32 %z)",
                        "call void @cqrt_copy_i32(i32 %1, i32 %y)",
                        "call void @cq_template_sub_i32_unc(i32 %1, i32 %y2, i32 %z)",
                        "call void @cqrt_free(i32 %1)",
                        "call void @cqrt_free(i32 %y)",
                        "call void @cq_template_add_i32_hl_unc(i32 %z, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %z)",
                        "call void @cqrt_ry_i32(i32 %y2, double %th2)",
                        "%m = call i32 @cqrt_measure_i32(i32 %y2)",
                        "ret i32 %m",
                    });
}

// ---- scopes and the mirror -----------------------------------------------------------------------

void scope_mirror_order() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  br label %body
body:
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)
  %r = call i32 @cq_template_add_i32(i32 %q, i32 %p)
  br label %rev
rev:
  %m = call i32 @cqrt_measure_i32(i32 %r)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  unsigned s = f.U.openScope();
  f.T("p", "hl");
  f.T("q", "hl");
  RailId r = f.T("r", "hh");
  f.U.closeScope(s);
  f.U.setRole(r, Role::Measured);
  ArrayRef<Record> recs = f.U.scopeRecords(s);
  if (recs.size() != 3 || recs[0].forward != f.I("p") || recs[1].forward != f.I("q") || recs[2].forward != f.I("r")) {
    ++failures;
    errs() << "FAIL scope_mirror_order: scopeRecords\n";
  }
  IRBuilder<> B(f.I("m"));
  f.U.emitMirror(s, B);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "br label %body",
                        "%p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)",
                        "%r = call i32 @cq_template_add_i32(i32 %q, i32 %p)",
                        "br label %rev",
                        "call void @cq_template_mul_i32_hl_unc(i32 %q, i32 %p, i32 3)",
                        "call void @cqrt_free(i32 %q)",
                        "call void @cq_template_add_i32_hl_unc(i32 %p, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %p)",
                        "%m = call i32 @cqrt_measure_i32(i32 %r)",
                        "ret i32 %m",
                    });
}

void scope_nested() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)
  %r = call i32 @cq_template_shl_i32_hl(i32 %q, i32 1)
  %res = call i32 @cq_template_add_i32(i32 %r, i32 %p)
  %inner = add i32 %a0, 1
  %outer = add i32 %a0, 2
  %m = call i32 @cqrt_measure_i32(i32 %res)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  unsigned so = f.U.openScope();
  f.T("p", "hl");
  unsigned si = f.U.openScope();
  f.T("q", "hl");
  f.T("r", "hl");
  f.U.closeScope(si);
  RailId res = f.T("res", "hh");
  f.U.closeScope(so);
  f.U.setRole(res, Role::Measured);
  if (f.U.scopeRecords(so).size() != 4 || f.U.scopeRecords(si).size() != 2 ||
      f.U.scopeRecords(si)[0].forward != f.I("q")) {
    ++failures;
    errs() << "FAIL scope_nested: scopeRecords\n";
  }
  IRBuilder<> Bi(f.I("inner"));
  f.U.emitMirror(si, Bi);
  IRBuilder<> Bo(f.I("outer"));
  f.U.emitMirror(so, Bo);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)",
                        "%r = call i32 @cq_template_shl_i32_hl(i32 %q, i32 1)",
                        "%res = call i32 @cq_template_add_i32(i32 %r, i32 %p)",
                        "call void @cq_template_shl_i32_hl_unc(i32 %r, i32 %q, i32 1)",
                        "call void @cqrt_free(i32 %r)",
                        "call void @cq_template_mul_i32_hl_unc(i32 %q, i32 %p, i32 3)",
                        "call void @cqrt_free(i32 %q)",
                        "%inner = add i32 %a0, 1",
                        "call void @cq_template_add_i32_hl_unc(i32 %p, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %p)",
                        "%outer = add i32 %a0, 2",
                        "%m = call i32 @cqrt_measure_i32(i32 %res)",
                        "ret i32 %m",
                    });
}

// ---- rule 7: seeds -------------------------------------------------------------------------------

void seed_direct() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %k = call i32 @cqrt_alloc_i32(i32 7)
  %p = call i32 @cq_template_add_i32(i32 %x, i32 %k)
  %m = call i32 @cqrt_measure_i32(i32 %p)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.S("k");
  f.U.setRole(f.T("p", "hh"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%k = call i32 @cqrt_alloc_i32(i32 7)",
                        "%p = call i32 @cq_template_add_i32(i32 %x, i32 %k)",
                        "call void @cqrt_free(i32 %k)",
                        "%m = call i32 @cqrt_measure_i32(i32 %p)",
                        "ret i32 %m",
                    });
}

void seed_xorc_direct() {
  // A seed after an uncontrolled xorc is still in a known basis state: freed directly.
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %k = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_xorc_i32(i32 %k, i32 5)
  %p = call i32 @cq_template_add_i32(i32 %x, i32 %k)
  %m = call i32 @cqrt_measure_i32(i32 %p)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  RailId k = f.S("k");
  f.core(f.call("cqrt_xorc_i32"), abi::Core::Xorc, "hl", k);
  f.U.setRole(f.T("p", "hh"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%k = call i32 @cqrt_alloc_i32(i32 0)",
                        "call void @cqrt_xorc_i32(i32 %k, i32 5)",
                        "%p = call i32 @cq_template_add_i32(i32 %x, i32 %k)",
                        "call void @cqrt_free(i32 %k)",
                        "%m = call i32 @cqrt_measure_i32(i32 %p)",
                        "ret i32 %m",
                    });
}

void seed_written_undone() {
  // A seed written by a copy is no longer known-basis: the copy is undone (an involution) first.
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %d = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %p, i32 %d)
  %q = call i32 @cq_template_mul_i32_hl(i32 %d, i32 2)
  %m = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("p", "hl");
  RailId d = f.S("d");
  f.core(f.call("cqrt_copy_i32"), abi::Core::Copy, "hh", d);
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%d = call i32 @cqrt_alloc_i32(i32 0)",
                        "call void @cqrt_copy_i32(i32 %p, i32 %d)",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %d, i32 2)",
                        "call void @cqrt_copy_i32(i32 %p, i32 %d)",
                        "call void @cqrt_free(i32 %d)",
                        "call void @cq_template_add_i32_hl_unc(i32 %p, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %p)",
                        "%m = call i32 @cqrt_measure_i32(i32 %q)",
                        "ret i32 %m",
                    });
}

// ---- A2: QRAM records ----------------------------------------------------------------------------

void qram_lifo() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %a = call i32 @cqrt_qram_alloc_i32(i32 4)
  %v1 = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  call void @cqrt_qram_store_i32_hl(i32 %a, i32 0, i32 %v1)
  %v2 = call i32 @cq_template_add_i32_hl(i32 %x, i32 2)
  call void @cqrt_qram_store_i32_hl(i32 %a, i32 1, i32 %v2)
  %l = call i32 @cqrt_qram_load_i32_hl(i32 %a, i32 0)
  %s = call i32 @cq_template_add_i32(i32 %l, i32 %x)
  %m = call i32 @cqrt_measure_i32(i32 %s)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  RailId a = f.core(f.call("cqrt_qram_alloc_i32"), abi::Core::QramAlloc, "l", ~0u);
  f.T("v1", "hl");
  f.core(f.call("cqrt_qram_store_i32_hl", 0), abi::Core::QramStore, "hlh", a);
  f.T("v2", "hl");
  f.core(f.call("cqrt_qram_store_i32_hl", 1), abi::Core::QramStore, "hlh", a);
  f.core(f.call("cqrt_qram_load_i32_hl"), abi::Core::QramLoad, "hl", ~0u);
  f.U.setRole(f.T("s", "hh"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%a = call i32 @cqrt_qram_alloc_i32(i32 4)",
                        "%v1 = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "call void @cqrt_qram_store_i32_hl(i32 %a, i32 0, i32 %v1)",
                        "%v2 = call i32 @cq_template_add_i32_hl(i32 %x, i32 2)",
                        "call void @cqrt_qram_store_i32_hl(i32 %a, i32 1, i32 %v2)",
                        "%l = call i32 @cqrt_qram_load_i32_hl(i32 %a, i32 0)",
                        "%s = call i32 @cq_template_add_i32(i32 %l, i32 %x)",
                        "call void @cqrt_qram_load_i32_hl_unc(i32 %l, i32 %a, i32 0)",
                        "call void @cqrt_free(i32 %l)",
                        "call void @cqrt_qram_store_i32_hl_unc(i32 %a, i32 1, i32 %v2)",
                        "call void @cq_template_add_i32_hl_unc(i32 %v2, i32 %x, i32 2)",
                        "call void @cqrt_free(i32 %v2)",
                        "call void @cqrt_qram_store_i32_hl_unc(i32 %a, i32 0, i32 %v1)",
                        "call void @cq_template_add_i32_hl_unc(i32 %v1, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %v1)",
                        "call void @cqrt_qram_free(i32 %a)",
                        "%m = call i32 @cqrt_measure_i32(i32 %s)",
                        "ret i32 %m",
                    });
}

// U6 (191's alias_params): a clone call reads the QRAM bus a and stores v into cell 0 inside the clone
// (recorded on the caller's bus after noteCallBusRead, forward = the call). The clone's store is popped
// before the twin, which recompute-reads the cells as at the call; the earlier store a[0] = s0 is popped
// after the twin.
void qram_call_bus_read() {
  Fx f(R"(
declare i32 @__cq_q_addto_0001(i32, i32, i32, i32, i32, i32)
define i32 @f(i32 %a0, double %th, i32 %b0) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %a = call i32 @cqrt_qram_alloc_i32(i32 2)
  %s0 = call i32 @cqrt_alloc_i32(i32 %b0)
  call void @cqrt_qram_store_i32_hl(i32 %a, i32 0, i32 %s0)
  %i = call i32 @cq_template_and_i32_hl(i32 %x, i32 1)
  %v = call i32 @__cq_q_addto_0001(i32 %a, i32 1, i32 0, i32 %a, i32 1, i32 %i)
  %l = call i32 @cqrt_qram_load_i32_hl(i32 %a, i32 0)
  %s = call i32 @cq_template_add_i32(i32 %l, i32 %x)
  %m = call i32 @cqrt_measure_i32(i32 %s)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  RailId a = f.core(f.call("cqrt_qram_alloc_i32"), abi::Core::QramAlloc, "l", ~0u);
  f.S("s0");
  f.core(f.call("cqrt_qram_store_i32_hl"), abi::Core::QramStore, "hlh", a);
  f.T("i", "hl");
  auto *fwd = cast<CallInst>(f.I("v"));
  f.U.recordCall(fwd, {fwd}, {}, {});
  f.U.noteCallBusRead(fwd, a);
  abi::CoreSpec st{abi::Core::QramStore, {Kind::Int, 32}, false, true};
  f.U.recordCore(fwd, st, {H(f.I("a")), Operand{ConstantInt::get(Type::getInt32Ty(f.C), 0), false}, H(fwd)}, a);
  f.core(f.call("cqrt_qram_load_i32_hl"), abi::Core::QramLoad, "hl", ~0u);
  f.U.setRole(f.T("s", "hh"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%a = call i32 @cqrt_qram_alloc_i32(i32 2)",
                        "%s0 = call i32 @cqrt_alloc_i32(i32 %b0)",
                        "call void @cqrt_qram_store_i32_hl(i32 %a, i32 0, i32 %s0)",
                        "%i = call i32 @cq_template_and_i32_hl(i32 %x, i32 1)",
                        "%v = call i32 @__cq_q_addto_0001(i32 %a, i32 1, i32 0, i32 %a, i32 1, i32 %i)",
                        "%l = call i32 @cqrt_qram_load_i32_hl(i32 %a, i32 0)",
                        "%s = call i32 @cq_template_add_i32(i32 %l, i32 %x)",
                        "call void @cqrt_qram_load_i32_hl_unc(i32 %l, i32 %a, i32 0)",
                        "call void @cqrt_free(i32 %l)",
                        "call void @cqrt_qram_store_i32_hl_unc(i32 %a, i32 0, i32 %v)",
                        "call void @__cq_q_addto_0001_unc(i32 %v, i32 %a, i32 1, i32 0, i32 %a, i32 1, i32 %i)",
                        "call void @cqrt_free(i32 %v)",
                        "call void @cq_template_and_i32_hl_unc(i32 %i, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %i)",
                        "call void @cqrt_qram_store_i32_hl_unc(i32 %a, i32 0, i32 %s0)",
                        "call void @cqrt_free(i32 %s0)",
                        "call void @cqrt_qram_free(i32 %a)",
                        "%m = call i32 @cqrt_measure_i32(i32 %s)",
                        "ret i32 %m",
                    });
}

void fatal_call_bus_read_unrecorded() {
  Fx f(R"(
declare i32 @__cq_q_addto_0001(i32, i32, i32, i32, i32, i32)
define i32 @f(i32 %a0) {
  %a = call i32 @cqrt_qram_alloc_i32(i32 2)
  %v = call i32 @__cq_q_addto_0001(i32 %a, i32 1, i32 0, i32 %a, i32 1, i32 %a0)
  ret i32 0
})");
  RailId a = f.core(f.call("cqrt_qram_alloc_i32"), abi::Core::QramAlloc, "l", ~0u);
  f.U.noteCallBusRead(cast<CallInst>(f.I("v")), a);
}

// cq-vtfq (CR §1.3, 186's shape): a' = qram_realloc(a, 6) is a bus of its own. The store and load made
// through a' are undone first, then qram_realloc_unc(a', 4) (n_old: a's qram_alloc size), then the
// un-copy of the load made through a before the realloc, a's store's POP, and a's qram_free.
void qram_realloc() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %a = call i32 @cqrt_qram_alloc_i32(i32 4)
  %v1 = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  call void @cqrt_qram_store_i32(i32 %a, i32 %x, i32 %v1)
  %l1 = call i32 @cqrt_qram_load_i32_hl(i32 %a, i32 1)
  %a2 = call i32 @cqrt_qram_realloc_i32(i32 %a, i32 6)
  call void @cqrt_qram_store_i32_hl(i32 %a2, i32 5, i32 %x)
  %l2 = call i32 @cqrt_qram_load_i32(i32 %a2, i32 %x)
  %s = call i32 @cq_template_add_i32(i32 %l1, i32 %l2)
  %m = call i32 @cqrt_measure_i32(i32 %s)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  RailId a = f.core(f.call("cqrt_qram_alloc_i32"), abi::Core::QramAlloc, "l", ~0u);
  f.T("v1", "hl");
  f.core(f.call("cqrt_qram_store_i32"), abi::Core::QramStore, "hhh", a);
  f.core(f.call("cqrt_qram_load_i32_hl"), abi::Core::QramLoad, "hl", ~0u);
  RailId a2 = f.core(f.call("cqrt_qram_realloc_i32"), abi::Core::QramRealloc, "hl", ~0u);
  f.core(f.call("cqrt_qram_store_i32_hl"), abi::Core::QramStore, "hlh", a2);
  f.core(f.call("cqrt_qram_load_i32"), abi::Core::QramLoad, "hh", ~0u);
  f.U.setRole(f.T("s", "hh"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%a = call i32 @cqrt_qram_alloc_i32(i32 4)",
                        "%v1 = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "call void @cqrt_qram_store_i32(i32 %a, i32 %x, i32 %v1)",
                        "%l1 = call i32 @cqrt_qram_load_i32_hl(i32 %a, i32 1)",
                        "%a2 = call i32 @cqrt_qram_realloc_i32(i32 %a, i32 6)",
                        "call void @cqrt_qram_store_i32_hl(i32 %a2, i32 5, i32 %x)",
                        "%l2 = call i32 @cqrt_qram_load_i32(i32 %a2, i32 %x)",
                        "%s = call i32 @cq_template_add_i32(i32 %l1, i32 %l2)",
                        "call void @cqrt_qram_load_i32_unc(i32 %l2, i32 %a2, i32 %x)",
                        "call void @cqrt_free(i32 %l2)",
                        "call void @cqrt_qram_store_i32_hl_unc(i32 %a2, i32 5, i32 %x)",
                        "call void @cqrt_qram_realloc_i32_unc(i32 %a2, i32 4)",
                        "call void @cqrt_qram_load_i32_hl_unc(i32 %l1, i32 %a, i32 1)",
                        "call void @cqrt_free(i32 %l1)",
                        "call void @cqrt_qram_store_i32_unc(i32 %a, i32 %x, i32 %v1)",
                        "call void @cq_template_add_i32_hl_unc(i32 %v1, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %v1)",
                        "call void @cqrt_qram_free(i32 %a)",
                        "%m = call i32 @cqrt_measure_i32(i32 %s)",
                        "ret i32 %m",
                    });
}

// cq-vtfq: a kept realloc result (Output) never restores a: a's resolvable items are refused.
void fatal_qram_realloc_kept() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %a = call i32 @cqrt_qram_alloc_i32(i32 4)
  %a2 = call i32 @cqrt_qram_realloc_i32(i32 %a, i32 6)
  call void @cqrt_qram_store_i32_hl(i32 %a2, i32 5, i32 %x)
  ret i32 %a0
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.core(f.call("cqrt_qram_alloc_i32"), abi::Core::QramAlloc, "l", ~0u);
  RailId a2 = f.core(f.call("cqrt_qram_realloc_i32"), abi::Core::QramRealloc, "hl", ~0u);
  f.core(f.call("cqrt_qram_store_i32_hl"), abi::Core::QramStore, "hlh", a2);
  f.U.setRole(a2, Role::Output);
  f.U.flushAtExit(f.ret());
}

// cq-w6ie (A2): a read-modify-write on one bus (77's shape). Each store is its own POP item, popped
// last-in-first-out; old (read v_1) is un-copied between POP(2) and POP(1), after sum, against the
// restored cell; the load reading v_2 precedes POP(2); the bus is freed last.
void qram_rmw() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %b = call i32 @cqrt_qram_alloc_i32(i32 2)
  %v1 = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  call void @cqrt_qram_store_i32_hl(i32 %b, i32 0, i32 %v1)
  %i = call i32 @cq_template_and_i32_hl(i32 %x, i32 1)
  %old = call i32 @cqrt_qram_load_i32(i32 %b, i32 %i)
  %sum = call i32 @cq_template_add_i32(i32 %old, i32 %x)
  call void @cqrt_qram_store_i32(i32 %b, i32 %i, i32 %sum)
  %l = call i32 @cqrt_qram_load_i32_hl(i32 %b, i32 0)
  %s = call i32 @cq_template_add_i32_hl(i32 %l, i32 7)
  %m = call i32 @cqrt_measure_i32(i32 %s)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  RailId b = f.core(f.call("cqrt_qram_alloc_i32"), abi::Core::QramAlloc, "l", ~0u);
  f.T("v1", "hl");
  f.core(f.call("cqrt_qram_store_i32_hl"), abi::Core::QramStore, "hlh", b);
  f.T("i", "hl");
  f.core(f.call("cqrt_qram_load_i32"), abi::Core::QramLoad, "hh", ~0u);
  f.T("sum", "hh");
  f.core(f.call("cqrt_qram_store_i32"), abi::Core::QramStore, "hhh", b);
  f.core(f.call("cqrt_qram_load_i32_hl"), abi::Core::QramLoad, "hl", ~0u);
  f.U.setRole(f.T("s", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%b = call i32 @cqrt_qram_alloc_i32(i32 2)",
                        "%v1 = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "call void @cqrt_qram_store_i32_hl(i32 %b, i32 0, i32 %v1)",
                        "%i = call i32 @cq_template_and_i32_hl(i32 %x, i32 1)",
                        "%old = call i32 @cqrt_qram_load_i32(i32 %b, i32 %i)",
                        "%sum = call i32 @cq_template_add_i32(i32 %old, i32 %x)",
                        "call void @cqrt_qram_store_i32(i32 %b, i32 %i, i32 %sum)",
                        "%l = call i32 @cqrt_qram_load_i32_hl(i32 %b, i32 0)",
                        "%s = call i32 @cq_template_add_i32_hl(i32 %l, i32 7)",
                        "call void @cqrt_qram_load_i32_hl_unc(i32 %l, i32 %b, i32 0)",
                        "call void @cqrt_free(i32 %l)",
                        "call void @cqrt_qram_store_i32_unc(i32 %b, i32 %i, i32 %sum)",
                        "call void @cq_template_add_i32_unc(i32 %sum, i32 %old, i32 %x)",
                        "call void @cqrt_free(i32 %sum)",
                        "call void @cqrt_qram_load_i32_unc(i32 %old, i32 %b, i32 %i)",
                        "call void @cqrt_free(i32 %old)",
                        "call void @cq_template_and_i32_hl_unc(i32 %i, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %i)",
                        "call void @cqrt_qram_store_i32_hl_unc(i32 %b, i32 0, i32 %v1)",
                        "call void @cq_template_add_i32_hl_unc(i32 %v1, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %v1)",
                        "call void @cqrt_qram_free(i32 %b)",
                        "%m = call i32 @cqrt_measure_i32(i32 %s)",
                        "ret i32 %m",
                    });
}

// cq-w6ie (A2): a kept bus (a global's handle, Output) never pops its stores, so a later store stays
// a barrier: a load whose last reader precedes that store is un-copied before it.
void qram_kept_bus() {
  Fx f(R"(
define i32 @f(i32 %b, i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %l = call i32 @cqrt_qram_load_i32_hl(i32 %b, i32 0)
  %s = call i32 @cq_template_add_i32_hl(i32 %l, i32 1)
  %v = call i32 @cq_template_add_i32_hl(i32 %x, i32 5)
  call void @cqrt_qram_store_i32_hl(i32 %b, i32 0, i32 %v)
  %m = call i32 @cqrt_measure_i32(i32 %s)
  ret i32 %m
})");
  RailId b = f.U.recordExternal(f.F->getArg(0), Role::Output);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.core(f.call("cqrt_qram_load_i32_hl"), abi::Core::QramLoad, "hl", ~0u);
  f.U.setRole(f.T("s", "hl"), Role::Measured);
  f.T("v", "hl");
  f.core(f.call("cqrt_qram_store_i32_hl"), abi::Core::QramStore, "hlh", b);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%l = call i32 @cqrt_qram_load_i32_hl(i32 %b, i32 0)",
                        "%s = call i32 @cq_template_add_i32_hl(i32 %l, i32 1)",
                        "call void @cqrt_qram_load_i32_hl_unc(i32 %l, i32 %b, i32 0)",
                        "call void @cqrt_free(i32 %l)",
                        "%v = call i32 @cq_template_add_i32_hl(i32 %x, i32 5)",
                        "call void @cqrt_qram_store_i32_hl(i32 %b, i32 0, i32 %v)",
                        "call void @cq_template_add_i32_hl_unc(i32 %v, i32 %x, i32 5)",
                        "call void @cqrt_free(i32 %v)",
                        "%m = call i32 @cqrt_measure_i32(i32 %s)",
                        "ret i32 %m",
                    });
}

// cq-w6ie (A2, item 5): the value of store 2 is rotated after the store, so POP(2) is never emitted:
// store 2 and store 1 stay, the bus is KeptEntangled (never freed). The load reading v_2 is still
// un-copied; v1 (read only by the kept POP(1)) is cleaned, since the store left v unchanged.
void qram_pop_kept() {
  Fx f(R"(
define i32 @f(i32 %a0, i32 %a1, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %b = call i32 @cqrt_qram_alloc_i32(i32 2)
  %v1 = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  call void @cqrt_qram_store_i32_hl(i32 %b, i32 0, i32 %v1)
  %y = call i32 @cqrt_alloc_i32(i32 %a1)
  call void @cqrt_qram_store_i32_hl(i32 %b, i32 1, i32 %y)
  call void @cqrt_ry_i32(i32 %y, double %th)
  %l = call i32 @cqrt_qram_load_i32_hl(i32 %b, i32 0)
  %s = call i32 @cq_template_add_i32_hl(i32 %l, i32 7)
  %m = call i32 @cqrt_measure_i32(i32 %s)
  ret i32 %m
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  RailId b = f.core(f.call("cqrt_qram_alloc_i32"), abi::Core::QramAlloc, "l", ~0u);
  f.T("v1", "hl");
  f.core(f.call("cqrt_qram_store_i32_hl", 0), abi::Core::QramStore, "hlh", b);
  RailId y = f.S("y");
  f.core(f.call("cqrt_qram_store_i32_hl", 1), abi::Core::QramStore, "hlh", b);
  f.U.noteNonDiagonal(y, f.call("cqrt_ry_i32", 1));
  f.core(f.call("cqrt_qram_load_i32_hl"), abi::Core::QramLoad, "hl", ~0u);
  f.U.setRole(f.T("s", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%b = call i32 @cqrt_qram_alloc_i32(i32 2)",
                        "%v1 = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "call void @cqrt_qram_store_i32_hl(i32 %b, i32 0, i32 %v1)",
                        "call void @cq_template_add_i32_hl_unc(i32 %v1, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %v1)",
                        "%y = call i32 @cqrt_alloc_i32(i32 %a1)",
                        "call void @cqrt_qram_store_i32_hl(i32 %b, i32 1, i32 %y)",
                        "call void @cqrt_ry_i32(i32 %y, double %th)",
                        "%l = call i32 @cqrt_qram_load_i32_hl(i32 %b, i32 0)",
                        "%s = call i32 @cq_template_add_i32_hl(i32 %l, i32 7)",
                        "call void @cqrt_qram_load_i32_hl_unc(i32 %l, i32 %b, i32 0)",
                        "call void @cqrt_free(i32 %l)",
                        "%m = call i32 @cqrt_measure_i32(i32 %s)",
                        "ret i32 %m",
                    });
}

// cq-w6ie (A2): on a kept bus a load read after a later store cannot be un-copied (the store is
// never popped): the in-place-write barrier stands.
void fatal_qram_kept_bus_barrier() {
  Fx f(R"(
define i32 @f(i32 %b, i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %l = call i32 @cqrt_qram_load_i32_hl(i32 %b, i32 0)
  %v = call i32 @cq_template_add_i32_hl(i32 %x, i32 5)
  call void @cqrt_qram_store_i32_hl(i32 %b, i32 0, i32 %v)
  %s = call i32 @cq_template_add_i32_hl(i32 %l, i32 1)
  %m = call i32 @cqrt_measure_i32(i32 %s)
  ret i32 %m
})");
  RailId b = f.U.recordExternal(f.F->getArg(0), Role::Output);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.core(f.call("cqrt_qram_load_i32_hl"), abi::Core::QramLoad, "hl", ~0u);
  f.T("v", "hl");
  f.core(f.call("cqrt_qram_store_i32_hl"), abi::Core::QramStore, "hlh", b);
  f.U.setRole(f.T("s", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
}

// ---- classical control flow ----------------------------------------------------------------------

void multi_exit() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  br i1 %c, label %A, label %B
A:
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)
  %mq = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %mq
B:
  %s = call i32 @cq_template_shl_i32_hl(i32 %p, i32 2)
  %ms = call i32 @cqrt_measure_i32(i32 %s)
  ret i32 %ms
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("p", "hl");
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.setRole(f.T("s", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret(0));
  f.U.flushAtExit(f.ret(1));
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "br i1 %c, label %A, label %B",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)",
                        "call void @cq_template_add_i32_hl_unc(i32 %p, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %p)",
                        "%mq = call i32 @cqrt_measure_i32(i32 %q)",
                        "ret i32 %mq",
                        "%s = call i32 @cq_template_shl_i32_hl(i32 %p, i32 2)",
                        "call void @cq_template_add_i32_hl_unc(i32 %p, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %p)",
                        "%ms = call i32 @cqrt_measure_i32(i32 %s)",
                        "ret i32 %ms",
                    });
}

const char *kArm = R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  br i1 %c, label %A, label %M
A:
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)
  %mq = call i32 @cqrt_measure_i32(i32 %q)
  br label %M
M:
  %r = phi i32 [ %mq, %A ], [ 0, %entry ]
  ret i32 %r
})";

void arm_flush() {
  Fx f(kArm);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("p", "hl");
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushBefore(f.I("mq")->getParent()->getTerminator());
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "br i1 %c, label %A, label %M",
                        "%p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)",
                        "call void @cq_template_add_i32_hl_unc(i32 %p, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %p)",
                        "%mq = call i32 @cqrt_measure_i32(i32 %q)",
                        "br label %M",
                        "%r = phi i32 [ %mq, %A ], [ 0, %entry ]",
                        "ret i32 %r",
                    });
}

// ---- corpus witnesses: the forward code of the example, the reference body expected -------------

void ex14_fmuladd() {
  // 14_fmuladd, fmuladd_qcc.
  Fx f(R"(
define double @fmuladd_qcc(double noundef %0, double noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_f64(double %0)
  call void @cqrt_ry_f64(i32 %5, double %1)
  %6 = call i32 @cq_template_fmul_f64_hl(i32 %5, double %2)
  %7 = call i32 @cq_template_fadd_f64_hl(i32 %6, double %3)
  %8 = call double @cqrt_measure_f64(i32 %7)
  ret double %8
})");
  RailId x = f.reg("5", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_f64"));
  f.T("6", "hl");
  f.U.setRole(f.T("7", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%5 = call i32 @cqrt_alloc_f64(double %0)",
                        "call void @cqrt_ry_f64(i32 %5, double %1)",
                        "%6 = call i32 @cq_template_fmul_f64_hl(i32 %5, double %2)",
                        "%7 = call i32 @cq_template_fadd_f64_hl(i32 %6, double %3)",
                        "call void @cq_template_fmul_f64_hl_unc(i32 %6, i32 %5, double %2)",
                        "call void @cqrt_free(i32 %6)",
                        "%8 = call double @cqrt_measure_f64(i32 %7)",
                        "ret double %8",
                    });
}

void ex42_measure_one_of_two() {
  // 42_measure_one_of_two.
  Fx f(R"(
define i32 @measure_one_of_two(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %6, double %2)
  %7 = call i32 @cqrt_alloc_i32(i32 %1)
  call void @cqrt_ry_i32(i32 %7, double %3)
  %8 = call i32 @cq_template_add_i32(i32 %6, i32 %7)
  %9 = call i32 @cqrt_measure_i32(i32 %6)
  %10 = call i32 @cq_template_mul_i32_hl(i32 %8, i32 %4)
  %11 = call i32 @cqrt_measure_i32(i32 %10)
  %12 = add nsw i32 %11, %9
  ret i32 %12
})");
  RailId x = f.reg("6", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  RailId y = f.reg("7", 1);
  f.U.noteNonDiagonal(y, f.call("cqrt_ry_i32", 1));
  f.T("8", "hh");
  f.U.setRole(x, Role::Measured);
  f.U.setRole(f.T("10", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%6 = call i32 @cqrt_alloc_i32(i32 %0)",
                        "call void @cqrt_ry_i32(i32 %6, double %2)",
                        "%7 = call i32 @cqrt_alloc_i32(i32 %1)",
                        "call void @cqrt_ry_i32(i32 %7, double %3)",
                        "%8 = call i32 @cq_template_add_i32(i32 %6, i32 %7)",
                        "%9 = call i32 @cqrt_measure_i32(i32 %6)",
                        "%10 = call i32 @cq_template_mul_i32_hl(i32 %8, i32 %4)",
                        "call void @cq_template_add_i32_unc(i32 %8, i32 %6, i32 %7)",
                        "call void @cqrt_free(i32 %8)",
                        "%11 = call i32 @cqrt_measure_i32(i32 %10)",
                        "%12 = add nsw i32 %11, %9",
                        "ret i32 %12",
                    });
}

void ex162_consumer() {
  // 162_quantum_return_entry: both functions. The entry's result escapes, x stays (never freed).
  Fx f(R"(
define i32 @quantum_return_consumer(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %4, double %1)
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)
  %6 = call i32 @cq_template_shl_i32_hl(i32 %5, i32 1)
  %7 = call i32 @cqrt_measure_i32(i32 %6)
  ret i32 %7
}
define i32 @quantum_return_entry(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %4, double %1)
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)
  ret i32 %5
})");
  RailId x = f.reg("4", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("5", "hl");
  f.U.setRole(f.T("6", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%4 = call i32 @cqrt_alloc_i32(i32 %0)",
                        "call void @cqrt_ry_i32(i32 %4, double %1)",
                        "%5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)",
                        "%6 = call i32 @cq_template_shl_i32_hl(i32 %5, i32 1)",
                        "call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 %2)",
                        "call void @cqrt_free(i32 %5)",
                        "%7 = call i32 @cqrt_measure_i32(i32 %6)",
                        "ret i32 %7",
                    });
  // The entry: one Uncompute per lowered function.
  Function *E = f.M->getFunction("quantum_return_entry");
  Uncompute U;
  auto *a = cast<CallInst>(&*E->getEntryBlock().begin());
  RailId xe = U.recordSeed(a);
  U.setRole(xe, Role::UserRegister);
  auto *ry = cast<CallInst>(a->getNextNode());
  U.noteNonDiagonal(xe, ry);
  auto *add = cast<CallInst>(ry->getNextNode());
  RailId res = U.recordTemplate(add, tspec("add", 32, "hl"), {H(a), {add->getArgOperand(1), false}});
  U.setRole(res, Role::Escaped);
  U.flushAtExit(cast<ReturnInst>(add->getNextNode()));
  if (E->getEntryBlock().size() != 4) {
    ++failures;
    errs() << "FAIL ex162_consumer: the entry gained instructions\n" << *E;
  }
}

void ex144_rule6() {
  // 144_value_arm_then_rotate.
  Fx f(R"(
define i32 @value_arm_then_rotate(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)
  call void @cqrt_ry_i32(i32 %7, double %1)
  %8 = call i32 @cqrt_alloc_i32(i32 %2)
  call void @cqrt_ry_i32(i32 %8, double %3)
  %9 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %4)
  %10 = call i32 @cq_template_zext_i1_to_i32(i32 %9)
  %11 = call i32 @cq_template_add_i32(i32 %8, i32 %10)
  call void @cqrt_ry_i32(i32 %11, double %5)
  %12 = call i32 @cqrt_measure_i32(i32 %11)
  %13 = call i32 @cqrt_measure_i32(i32 %7)
  %14 = add nsw i32 %13, %12
  ret i32 %14
})");
  RailId x = f.reg("7", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  RailId y = f.reg("8", 1);
  f.U.noteNonDiagonal(y, f.call("cqrt_ry_i32", 1));
  f.T("9", "hl");
  f.T("10", "h");
  RailId y2 = f.T("11", "hh");
  f.U.cleanupBijective(y, tspec("sub", 32), {H(f.I("11")), H(f.I("10"))});
  f.U.setRole(y2, Role::UserRegister);
  f.U.noteNonDiagonal(y2, f.call("cqrt_ry_i32", 2));
  f.U.setRole(y2, Role::Measured);
  f.U.setRole(x, Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%7 = call i32 @cqrt_alloc_i32(i32 %0)",
                        "call void @cqrt_ry_i32(i32 %7, double %1)",
                        "%8 = call i32 @cqrt_alloc_i32(i32 %2)",
                        "call void @cqrt_ry_i32(i32 %8, double %3)",
                        "%9 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %4)",
                        "%10 = call i32 @cq_template_zext_i1_to_i32(i32 %9)",
                        "%11 = call i32 @cq_template_add_i32(i32 %8, i32 %10)",
                        "%12 = call i32 @cq_template_sub_i32(i32 %11, i32 %10)",
                        "call void @cqrt_copy_i32(i32 %12, i32 %8)",
                        "call void @cq_template_sub_i32_unc(i32 %12, i32 %11, i32 %10)",
                        "call void @cqrt_free(i32 %12)",
                        "call void @cqrt_free(i32 %8)",
                        "call void @cq_template_zext_i1_to_i32_unc(i32 %10, i32 %9)",
                        "call void @cqrt_free(i32 %10)",
                        "call void @cq_template_icmp_sgt_i32_hl_unc(i32 %9, i32 %7, i32 %4)",
                        "call void @cqrt_free(i32 %9)",
                        "call void @cqrt_ry_i32(i32 %11, double %5)",
                        "%13 = call i32 @cqrt_measure_i32(i32 %11)",
                        "%14 = call i32 @cqrt_measure_i32(i32 %7)",
                        "%15 = add nsw i32 %14, %13",
                        "ret i32 %15",
                    });
}

// ---- fatal cases: each must stop with its named error ---------------------------------------------

const char *kChain = R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)
  %m = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %m
})";

void fatal_use_after_free() {
  Fx f(kChain);
  f.reg("x", 0);
  RailId p = f.T("p", "hl");
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.U.noteUse(p, f.I("m"));
}

void fatal_operand_mismatch() {
  Fx f(kChain);
  f.reg("x", 0);
  auto *p = cast<CallInst>(f.I("p"));
  f.U.recordTemplate(p, tspec("add", 32, "hl"), {H(f.I("x")), {f.I("x"), false}});
}

// An arm on a cycle (a classical loop body) left unflushed: one item at the return cannot undo every
// trip's rail, so it stays an internal error (cq-ut4k builds only arms outside cycles).
void fatal_unflushed_arm() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  br i1 %c, label %A, label %M
A:
  %p = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %q = call i32 @cq_template_mul_i32_hl(i32 %p, i32 3)
  %mq = call i32 @cqrt_measure_i32(i32 %q)
  br i1 %c, label %A, label %M
M:
  %r = phi i32 [ %mq, %A ], [ 0, %entry ]
  ret i32 %r
})");
  f.reg("x", 0);
  f.T("p", "hl");
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
}

void fatal_scope_order() {
  Fx f(kChain);
  unsigned a = f.U.openScope();
  f.U.openScope();
  f.U.closeScope(a);
}

void fatal_mirror_outside_reader() {
  Fx f(kChain);
  f.reg("x", 0);
  unsigned s = f.U.openScope();
  f.T("p", "hl");
  f.U.closeScope(s);
  f.T("q", "hl");
  IRBuilder<> B(f.I("m"));
  f.U.emitMirror(s, B);
}

void fatal_write_barrier() {
  // g read the seed d; d is then written in place and g is read after the write: g's _unc would
  // see the written d. Not a non-diagonal gate, so not KeptEntangled: an internal error.
  Fx f(R"(
define i32 @f(i32 %a0, double %th) {
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %d = call i32 @cqrt_alloc_i32(i32 0)
  %g = call i32 @cq_template_add_i32_hl(i32 %d, i32 1)
  call void @cqrt_copy_i32(i32 %x, i32 %d)
  %q = call i32 @cq_template_mul_i32_hl(i32 %g, i32 3)
  %m = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %m
})");
  f.reg("x", 0);
  RailId d = f.S("d");
  f.T("g", "hl");
  f.core(f.call("cqrt_copy_i32"), abi::Core::Copy, "hh", d);
  f.U.setRole(d, Role::Result);
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
}

void fatal_unknown_handle() {
  Fx f(kChain);
  f.T("p", "hl"); // %x was never recorded
}

// ---- U1: merged handles (CR rule 9, a classical select/phi over handles) -------------------------

// r = c ? x + 1 : x * 2 with c classical: both arms hoisted, a classical select over their handles.
const char *kSel = R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)
  %m = select i1 %c, i32 %ha, i32 %hb
  %fr = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %m, i32 %fr)
  %r = call i32 @cqrt_measure_i32(i32 %fr)
  ret i32 %r
})";

// M3 (cq-arch 2026-11-01): a load of a slot cell's handle that may name either stored rail is a merge
// over both: the template reading the load reads both arms, so both are uncomputed after it.
const char *kCell = R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %p = alloca i32
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)
  %v = select i1 %c, i32 %ha, i32 %hb
  store i32 %v, ptr %p
  %m = load i32, ptr %p
  %y = call i32 @cq_template_mul_i32_hl(i32 %m, i32 3)
  %r = call i32 @cqrt_measure_i32(i32 %y)
  ret i32 %r
})";

void cell_load_garbage() {
  Fx f(kCell);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  RailId a = f.T("ha", "hl");
  RailId b = f.T("hb", "hl");
  RailId m = f.U.recordCellLoad(f.I("m"), {a, b});
  if (f.id("m") != m) {
    ++failures;
    errs() << "FAIL cell_load_garbage: idOf(load) is not recordCellLoad's rail\n";
  }
  f.U.setRole(f.T("y", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%p = alloca i32, align 4",
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)",
                        "%v = select i1 %c, i32 %ha, i32 %hb",
                        "store i32 %v, ptr %p, align 4",
                        "%m = load i32, ptr %p, align 4",
                        "%y = call i32 @cq_template_mul_i32_hl(i32 %m, i32 3)",
                        "call void @cq_template_shl_i32_hl_unc(i32 %hb, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %hb)",
                        "call void @cq_template_add_i32_hl_unc(i32 %ha, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %ha)",
                        "%r = call i32 @cqrt_measure_i32(i32 %y)",
                        "ret i32 %r",
                    });
}

// M3: a kept role on the load keeps every rail it may name (a load has no join to resolve at).
void cell_load_kept() {
  Fx f(kCell);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  RailId a = f.T("ha", "hl");
  RailId b = f.T("hb", "hl");
  RailId m = f.U.recordCellLoad(f.I("m"), {a, b});
  f.U.setRole(m, Role::Measured);
  f.U.setRole(f.T("y", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%p = alloca i32, align 4",
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)",
                        "%v = select i1 %c, i32 %ha, i32 %hb",
                        "store i32 %v, ptr %p, align 4",
                        "%m = load i32, ptr %p, align 4",
                        "%y = call i32 @cq_template_mul_i32_hl(i32 %m, i32 3)",
                        "%r = call i32 @cqrt_measure_i32(i32 %y)",
                        "ret i32 %r",
                    });
}

// M3: a cell load that may name nothing is an internal error.
void fatal_cell_load_empty() {
  Fx f(kCell);
  f.U.recordCellLoad(f.I("m"), {});
}

// F1 with M3 (179): a classically bounded loop stores a flag rail into a cell each trip; after the loop
// the cell is read through a cell-load merge and measured. The exit rail has no IR use outside the
// loop, so it keeps its kept role on every trip: no copy at the exit, the reverse loop does not undo
// it, and the trip's other rail reading it (u) is still undone.
const char *kDefMem = R"(
define i32 @f(i32 %a0, double %th, i32 %n) {
entry:
  %p = alloca i32
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  br label %L
L:
  %i = phi i32 [ 0, %entry ], [ %i2, %L ]
  %t = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %u = call i32 @cq_template_mul_i32_hl(i32 %t, i32 3)
  store i32 %t, ptr %p
  %i2 = add i32 %i, 1
  %c = icmp slt i32 %i2, %n
  br i1 %c, label %L, label %X
X:
  %m = load i32, ptr %p
  %r = call i32 @cqrt_measure_i32(i32 %m)
  ret i32 %r
})";

void deferred_kept_through_memory() {
  Fx f(kDefMem);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  unsigned s = f.U.openScope();
  RailId t = f.T("t", "hl");
  f.T("u", "hl");
  f.U.closeScope(s);
  Uncompute *U = &f.U;
  f.U.recordDeferred({s}, {t}, [U, s](IRBuilder<> &B) { U->emitMirror(s, B); }, {x});
  RailId m = f.U.recordCellLoad(f.I("m"), {t});
  f.U.setRole(m, Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%p = alloca i32, align 4",
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "br label %L",
                        "%i = phi i32 [ 0, %entry ], [ %i2, %L ]",
                        "%t = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%u = call i32 @cq_template_mul_i32_hl(i32 %t, i32 3)",
                        "store i32 %t, ptr %p, align 4",
                        "%i2 = add i32 %i, 1",
                        "%c = icmp slt i32 %i2, %n",
                        "br i1 %c, label %L, label %0",
                        "%m = load i32, ptr %p, align 4",
                        "%r = call i32 @cqrt_measure_i32(i32 %m)",
                        "call void @cq_template_mul_i32_hl_unc(i32 %u, i32 %t, i32 3)",
                        "call void @cqrt_free(i32 %u)",
                        "br label %X",
                        "ret i32 %r",
                    });
}

// U2 (cq-arch 2026-11-01): a clone call with two result rails (64). Both are read by one template; the
// twin, taking both result handles first, runs after it, then both rails are freed in field order.
const char *kCall2 = R"(
declare { i32, i32 } @__cq_q_split_10(i32, double)
declare i32 @cq_template_fadd_f64(i32, i32)
define double @f(double %a0, double %th, double %c) {
entry:
  %x = call i32 @cqrt_alloc_f64(double %a0)
  call void @cqrt_ry_f64(i32 %x, double %th)
  %s = call { i32, i32 } @__cq_q_split_10(i32 %x, double %c)
  %h = extractvalue { i32, i32 } %s, 0
  %l = extractvalue { i32, i32 } %s, 1
  %y = call i32 @cq_template_fadd_f64(i32 %h, i32 %l)
  %r = call double @cqrt_measure_f64(i32 %y)
  ret double %r
})";

void call_two_results() {
  Fx f(kCall2);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_f64"));
  auto ids = f.U.recordCall(cast<CallInst>(f.I("s")), {f.I("h"), f.I("l")}, {}, {});
  if (ids.size() != 2 || f.id("h") != ids[0] || f.id("l") != ids[1]) {
    ++failures;
    errs() << "FAIL call_two_results: recordCall ids\n";
  }
  f.U.setRole(f.T("y", "hh"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_f64(double %a0)",
                        "call void @cqrt_ry_f64(i32 %x, double %th)",
                        "%s = call { i32, i32 } @__cq_q_split_10(i32 %x, double %c)",
                        "%h = extractvalue { i32, i32 } %s, 0",
                        "%l = extractvalue { i32, i32 } %s, 1",
                        "%y = call i32 @cq_template_fadd_f64(i32 %h, i32 %l)",
                        "call void @__cq_q_split_10_unc(i32 %h, i32 %l, i32 %x, double %c)",
                        "call void @cqrt_free(i32 %h)",
                        "call void @cqrt_free(i32 %l)",
                        "%r = call double @cqrt_measure_f64(i32 %y)",
                        "ret double %r",
                    });
}

// U2: every result kept (159's second entry measures both): no twin, nothing freed.
const char *kCall2m = R"(
declare { i32, i32 } @__cq_q_split_10(i32, double)
define double @f(double %a0, double %th, double %c) {
entry:
  %x = call i32 @cqrt_alloc_f64(double %a0)
  call void @cqrt_ry_f64(i32 %x, double %th)
  %s = call { i32, i32 } @__cq_q_split_10(i32 %x, double %c)
  %h = extractvalue { i32, i32 } %s, 0
  %l = extractvalue { i32, i32 } %s, 1
  %r = call double @cqrt_measure_f64(i32 %h)
  %q = call double @cqrt_measure_f64(i32 %l)
  ret double %r
})";

void call_all_kept() {
  Fx f(kCall2m);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_f64"));
  auto ids = f.U.recordCall(cast<CallInst>(f.I("s")), {f.I("h"), f.I("l")}, {}, {});
  f.U.setRole(ids[0], Role::Measured);
  f.U.setRole(ids[1], Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_f64(double %a0)",
                        "call void @cqrt_ry_f64(i32 %x, double %th)",
                        "%s = call { i32, i32 } @__cq_q_split_10(i32 %x, double %c)",
                        "%h = extractvalue { i32, i32 } %s, 0",
                        "%l = extractvalue { i32, i32 } %s, 1",
                        "%r = call double @cqrt_measure_f64(i32 %h)",
                        "%q = call double @cqrt_measure_f64(i32 %l)",
                        "ret double %r",
                    });
}

// cq-b73i: a slotOut (the after-call load of a cell the clone wrote) that nothing reads. The item
// follows the load's definition, not just the forward call (it names the load's handle).
const char *kCallSlot = R"(
declare void @__cq_q_fill_11(ptr, i32)
define i32 @f(i32 %a0, double %th) {
entry:
  %a = alloca [2 x i32], align 4
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %old = load i32, ptr %a, align 4
  call void @__cq_q_fill_11(ptr %a, i32 %x)
  %c = load i32, ptr %a, align 4
  ret i32 0
})";

void call_slotout_unused() {
  Fx f(kCallSlot);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.U.recordCall(f.call("__cq_q_fill_11"), {}, {f.I("c")}, {Operand{f.I("old"), false}});
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%a = alloca [2 x i32], align 4",
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%old = load i32, ptr %a, align 4",
                        "call void @__cq_q_fill_11(ptr %a, i32 %x)",
                        "%c = load i32, ptr %a, align 4",
                        "call void @__cq_q_fill_11_unc(ptr %a, i32 %x, i32 %old)",
                        "call void @cqrt_free(i32 %c)",
                        "ret i32 0",
                    });
}

// U4: g sits in a caller cell the clone reads (noteCallReads, made before recordCall as mem-slots
// does). g's own item reads x only, but it must follow the twin, which recompute-reads g: the twin,
// the slotOut's free, then g's _unc.
const char *kCallReads = R"(
declare void @__cq_q_fill_11(ptr, i32)
define i32 @f(i32 %a0, double %th) {
entry:
  %a = alloca [2 x i32], align 4
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %g = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  store i32 %g, ptr %a, align 4
  call void @__cq_q_fill_11(ptr %a, i32 %x)
  %p = getelementptr inbounds i32, ptr %a, i64 1
  %c = load i32, ptr %p, align 4
  %r = call i32 @cqrt_measure_i32(i32 %x)
  ret i32 %r
})";

void call_reads() {
  Fx f(kCallReads);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  RailId g = f.T("g", "hl");
  f.U.noteCallReads(f.call("__cq_q_fill_11"), {g});
  f.U.recordCall(f.call("__cq_q_fill_11"), {}, {f.I("c")}, {Operand{PoisonValue::get(Type::getInt32Ty(f.C)), false}});
  f.U.setRole(x, Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%a = alloca [2 x i32], align 4",
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%g = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "store i32 %g, ptr %a, align 4",
                        "call void @__cq_q_fill_11(ptr %a, i32 %x)",
                        "%p = getelementptr inbounds i32, ptr %a, i64 1",
                        "%c = load i32, ptr %p, align 4",
                        "call void @__cq_q_fill_11_unc(ptr %a, i32 %x, i32 poison)",
                        "call void @cqrt_free(i32 %c)",
                        "call void @cq_template_add_i32_hl_unc(i32 %g, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %g)",
                        "%r = call i32 @cqrt_measure_i32(i32 %x)",
                        "ret i32 %r",
                    });
}

// U5: resolveAt. t (garbage over x) is defined and used in the guarded block G; every path from G to
// the return passes X, so resolveAt(first instruction of X, {t}) emits t's _unc and free there.
const char *kResolveAt = R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  br i1 %c, label %G, label %Y
G:
  %t = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  call void @cqrt_ry_i32(i32 %t, double %th)
  br label %X
X:
  %r = call i32 @cqrt_measure_i32(i32 %x)
  ret i32 %r
Y:
  ret i32 0
})";

void resolve_at() {
  Fx f(kResolveAt);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  RailId t = f.T("t", "hl");
  f.U.setRole(x, Role::Measured);
  (void)t;
  f.U.resolveAt(f.I("r"), {t});
  f.U.flushAtExit(f.ret(0));
  f.U.flushAtExit(f.ret(1));
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "br i1 %c, label %G, label %Y",
                        "%t = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "call void @cqrt_ry_i32(i32 %t, double %th)",
                        "br label %X",
                        "call void @cq_template_add_i32_hl_unc(i32 %t, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %t)",
                        "%r = call i32 @cqrt_measure_i32(i32 %x)",
                        "ret i32 %r",
                        "ret i32 0",
                    });
}

// U5: t is still used at the point: an internal error.
void fatal_resolve_at_used() {
  Fx f(kResolveAt);
  RailId x = f.reg("x", 0);
  RailId t = f.T("t", "hl");
  (void)x;
  f.U.resolveAt(f.call("cqrt_ry_i32", 1), {t});
}

// U5: a path from x's definition reaches a return (Y) without passing the point in X.
const char *kResolveBypass = R"(
define i32 @f(i32 %a0, i1 %c) {
entry:
  %s = call i32 @cqrt_alloc_i32(i32 %a0)
  br i1 %c, label %A, label %B
A:
  ret i32 1
B:
  ret i32 0
})";

void fatal_resolve_at_bypass() {
  Fx f(kResolveBypass);
  RailId s = f.S("s");
  f.U.resolveAt(f.ret(0), {s});
}

// cq-fwto: a clone with a classical pointer formal, recorded as a template (one result). A later store
// into the object is a barrier: its twin goes before it when its last use does (pointee_before_store),
// and is unimplemented when the result is still read after the store (fatal_pointee_write).
const char *kPointee = R"(
declare i32 @__cq_q_g_01(ptr, i32)
define i64 @f(i32 %a0, double %th, i64 %q) {
entry:
  %s = alloca i64, align 8
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  store i64 %q, ptr %s, align 8
  %r = call i32 @__cq_q_g_01(ptr %s, i32 %x)
  %t = call i32 @cq_template_add_i32_hl(i32 %r, i32 1)
  store i64 7, ptr %s, align 8
  %m = call i32 @cqrt_measure_i32(i32 %t)
  %u = call i32 @cq_template_add_i32_hl(i32 %r, i32 2)
  ret i64 0
})";

void pointee_before_store() {
  Fx f(kPointee);
  // Without %u: the twin of %r follows %t and precedes the store.
  f.I("u")->eraseFromParent();
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("r", "lh");
  RailId t = f.T("t", "hl");
  f.U.setRole(t, Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%s = alloca i64, align 8",
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "store i64 %q, ptr %s, align 8",
                        "%r = call i32 @__cq_q_g_01(ptr %s, i32 %x)",
                        "%t = call i32 @cq_template_add_i32_hl(i32 %r, i32 1)",
                        "call void @__cq_q_g_01_unc(i32 %r, ptr %s, i32 %x)",
                        "call void @cqrt_free(i32 %r)",
                        "store i64 7, ptr %s, align 8",
                        "%m = call i32 @cqrt_measure_i32(i32 %t)",
                        "ret i64 0",
                    });
}

void fatal_pointee_write() {
  Fx f(kPointee);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("r", "lh");
  RailId t = f.T("t", "hl");
  f.T("u", "hl");
  f.U.setRole(t, Role::Measured);
  f.U.flushAtExit(f.ret());
}

// U2: one result kept and the other not: the twin would zero the kept one.
void fatal_call_mixed() {
  Fx f(kCall2m);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_f64"));
  auto ids = f.U.recordCall(cast<CallInst>(f.I("s")), {f.I("h"), f.I("l")}, {}, {});
  f.U.setRole(ids[1], Role::Measured);
  f.U.flushAtExit(f.ret());
}

// The merged handle measured: the consumer copies it out into a fresh rail and keeps that rail
// (compute-copy-uncompute, CR §0); the merge stays garbage and both arms are uncomputed after the copy.
// Kept: x and the copy (one rail with the chosen arm's value), as in 135's classical-control spelling.
void merge_measured() {
  Fx f(kSel);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("ha", "hl");
  f.T("hb", "hl");
  RailId m = f.U.recordMerge(f.I("m"));
  if (f.id("m") != m) {
    ++failures;
    errs() << "FAIL merge_measured: idOf(merged) is not recordMerge's rail\n";
  }
  RailId fr = f.S("fr");
  f.core(f.call("cqrt_copy_i32"), abi::Core::Copy, "hh", fr);
  f.U.setRole(fr, Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)",
                        "%m = select i1 %c, i32 %ha, i32 %hb",
                        "%fr = call i32 @cqrt_alloc_i32(i32 0)",
                        "call void @cqrt_copy_i32(i32 %m, i32 %fr)",
                        "call void @cq_template_shl_i32_hl_unc(i32 %hb, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %hb)",
                        "call void @cq_template_add_i32_hl_unc(i32 %ha, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %ha)",
                        "%r = call i32 @cqrt_measure_i32(i32 %fr)",
                        "ret i32 %r",
                    });
}

// 135's spelling: every arm is already kept (copied out into a Result rail inside its arm), so a kept
// role on the merged handle changes nothing and nothing is emitted for the arms or the merge.
void merge_all_arms_kept() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  br i1 %c, label %A, label %B
A:
  %ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  br label %J
B:
  %hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)
  br label %J
J:
  %m = phi i32 [ %ha, %A ], [ %hb, %B ]
  %r = call i32 @cqrt_measure_i32(i32 %m)
  ret i32 %r
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.U.setRole(f.T("ha", "hl"), Role::Result);
  f.U.setRole(f.T("hb", "hl"), Role::Result);
  f.U.setRole(f.U.recordMerge(f.I("m")), Role::Measured);
  f.U.flushBefore(f.I("ha")->getParent()->getTerminator());
  f.U.flushBefore(f.I("hb")->getParent()->getTerminator());
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "br i1 %c, label %A, label %B",
                        "%ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "br label %J",
                        "%hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)",
                        "br label %J",
                        "%m = phi i32 [ %ha, %A ], [ %hb, %B ]",
                        "%r = call i32 @cqrt_measure_i32(i32 %m)",
                        "ret i32 %r",
                    });
}

// The merged handle read by a template, then garbage: the template's rail is uncomputed first (it
// reads the merge, so it reads whichever arm was chosen), then both arms, all after the last use and
// before the block's terminator (a local flush: the select is not a call, but it is a recorded merge).
void merge_template_then_garbage() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)
  %m = select i1 %c, i32 %ha, i32 %hb
  %t = call i32 @cq_template_mul_i32_hl(i32 %m, i32 3)
  %u = call i32 @cq_template_add_i32_hl(i32 %t, i32 5)
  %r = call i32 @cqrt_measure_i32(i32 %u)
  br label %exit
exit:
  ret i32 %r
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("ha", "hl");
  f.T("hb", "hl");
  f.U.recordMerge(f.I("m"));
  f.T("t", "hl");
  f.U.setRole(f.T("u", "hl"), Role::Measured);
  f.U.flushBefore(f.I("r")->getParent()->getTerminator());
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)",
                        "%m = select i1 %c, i32 %ha, i32 %hb",
                        "%t = call i32 @cq_template_mul_i32_hl(i32 %m, i32 3)",
                        "%u = call i32 @cq_template_add_i32_hl(i32 %t, i32 5)",
                        "call void @cq_template_mul_i32_hl_unc(i32 %t, i32 %m, i32 3)",
                        "call void @cqrt_free(i32 %t)",
                        "call void @cq_template_shl_i32_hl_unc(i32 %hb, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %hb)",
                        "call void @cq_template_add_i32_hl_unc(i32 %ha, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %ha)",
                        "%r = call i32 @cqrt_measure_i32(i32 %u)",
                        "br label %exit",
                        "ret i32 %r",
                    });
}

// A noted use of the merged handle (e.g. a slot load of it) extends every arm past that use.
void merge_noted_use() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)
  %m = select i1 %c, i32 %ha, i32 %hb
  %ld = call i32 @cq_template_icmp_eq_i32_hl(i32 %x, i32 7)
  %r = call i32 @cqrt_measure_i32(i32 %ld)
  ret i32 %r
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("ha", "hl");
  f.T("hb", "hl");
  RailId m = f.U.recordMerge(f.I("m"));
  f.U.setRole(f.T("ld", "hl"), Role::Measured);
  f.U.noteUse(m, f.I("ld"));
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)",
                        "%m = select i1 %c, i32 %ha, i32 %hb",
                        "%ld = call i32 @cq_template_icmp_eq_i32_hl(i32 %x, i32 7)",
                        "call void @cq_template_shl_i32_hl_unc(i32 %hb, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %hb)",
                        "call void @cq_template_add_i32_hl_unc(i32 %ha, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %ha)",
                        "%r = call i32 @cqrt_measure_i32(i32 %ld)",
                        "ret i32 %r",
                    });
}

// A phi-shaped merge at a classical join, arms defined in a block that dominates the join: the arms
// are uncomputed in the join after the merged handle's last reader is uncomputed.
const char *kPhi = R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)
  br i1 %c, label %A, label %B
A:
  br label %J
B:
  br label %J
J:
  %m = phi i32 [ %ha, %A ], [ %hb, %B ]
  %t = call i32 @cq_template_mul_i32_hl(i32 %m, i32 3)
  %r = call i32 @cqrt_measure_i32(i32 %t)
  ret i32 %r
})";

void merge_phi() {
  Fx f(kPhi);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("ha", "hl");
  f.T("hb", "hl");
  f.U.flushBefore(f.I("hb")->getParent()->getTerminator()); // nothing: the arms are read in J
  f.U.recordMerge(f.I("m"));
  f.U.setRole(f.T("t", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)",
                        "br i1 %c, label %A, label %B",
                        "br label %J",
                        "br label %J",
                        "%m = phi i32 [ %ha, %A ], [ %hb, %B ]",
                        "%t = call i32 @cq_template_mul_i32_hl(i32 %m, i32 3)",
                        "call void @cq_template_shl_i32_hl_unc(i32 %hb, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %hb)",
                        "call void @cq_template_add_i32_hl_unc(i32 %ha, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %ha)",
                        "%r = call i32 @cqrt_measure_i32(i32 %t)",
                        "ret i32 %r",
                    });
}

// Nested classical selects (a classical switch over handles): a reader of the outer merge outlives
// into every leaf arm; the inner merge has no item either.
void merge_nested() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c1, i1 %c2) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)
  %hc = call i32 @cq_template_mul_i32_hl(i32 %x, i32 5)
  %m1 = select i1 %c1, i32 %ha, i32 %hb
  %m2 = select i1 %c2, i32 %m1, i32 %hc
  %t = call i32 @cq_template_add_i32_hl(i32 %m2, i32 9)
  %r = call i32 @cqrt_measure_i32(i32 %t)
  ret i32 %r
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("ha", "hl");
  f.T("hb", "hl");
  f.T("hc", "hl");
  f.U.recordMerge(f.I("m1"));
  f.U.recordMerge(f.I("m2"));
  f.U.setRole(f.T("t", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)",
                        "%hc = call i32 @cq_template_mul_i32_hl(i32 %x, i32 5)",
                        "%m1 = select i1 %c1, i32 %ha, i32 %hb",
                        "%m2 = select i1 %c2, i32 %m1, i32 %hc",
                        "%t = call i32 @cq_template_add_i32_hl(i32 %m2, i32 9)",
                        "call void @cq_template_mul_i32_hl_unc(i32 %hc, i32 %x, i32 5)",
                        "call void @cqrt_free(i32 %hc)",
                        "call void @cq_template_shl_i32_hl_unc(i32 %hb, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %hb)",
                        "call void @cq_template_add_i32_hl_unc(i32 %ha, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %ha)",
                        "%r = call i32 @cqrt_measure_i32(i32 %t)",
                        "ret i32 %r",
                    });
}

// ---- cq-bv91: a kept role on a classically merged phi keeps the chosen arm on each path ----------

// 128 (measure_then_reuse): each arm exists only on the path that chooses it (a rotated register in
// A, a seed of a classical value in B). Measuring the merge keeps the arm on its own path: nothing is
// uncomputed or freed, one kept rail per path.
void merge_kept_arm_local() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c, i32 %v) {
entry:
  br i1 %c, label %A, label %B
A:
  %ha = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %ha, double %th)
  br label %J
B:
  %hb = call i32 @cqrt_alloc_i32(i32 %v)
  br label %J
J:
  %m = phi i32 [ %ha, %A ], [ %hb, %B ]
  %r = call i32 @cqrt_measure_i32(i32 %m)
  ret i32 %r
})");
  RailId a = f.reg("ha", 0);
  f.U.noteNonDiagonal(a, f.call("cqrt_ry_i32"));
  f.S("hb");
  f.U.flushBefore(f.I("ha")->getParent()->getTerminator());
  f.U.flushBefore(f.I("hb")->getParent()->getTerminator());
  f.U.setRole(f.U.recordMerge(f.I("m")), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "br i1 %c, label %A, label %B",
                        "%ha = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %ha, double %th)",
                        "br label %J",
                        "%hb = call i32 @cqrt_alloc_i32(i32 %v)",
                        "br label %J",
                        "%m = phi i32 [ %ha, %A ], [ %hb, %B ]",
                        "%r = call i32 @cqrt_measure_i32(i32 %m)",
                        "ret i32 %r",
                    });
}

// 25 (the exit phi of a classically bounded loop): the zero-trip seed s is defined before the branch,
// so it also reaches the join along the loop edge, where the merge chooses the loop's output o. s is
// kept on the zero-trip path and freed at the end of the loop edge's block, before the join; the
// garbage t that o was computed from is uncomputed at the return as usual (o is kept).
void merge_kept_unchosen_edge() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %s = call i32 @cqrt_alloc_i32(i32 0)
  br i1 %c, label %L, label %J
L:
  %t = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %o = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %t, i32 %o)
  br label %J
J:
  %m = phi i32 [ %s, %entry ], [ %o, %L ]
  %r = call i32 @cqrt_measure_i32(i32 %m)
  ret i32 %r
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.S("s");
  f.T("t", "hl");
  RailId o = f.S("o");
  f.core(f.call("cqrt_copy_i32"), abi::Core::Copy, "hh", o);
  f.U.setRole(o, Role::Output);
  f.U.flushBefore(f.I("t")->getParent()->getTerminator());
  RailId m = f.U.recordMerge(f.I("m"));
  f.U.setRole(m, Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%s = call i32 @cqrt_alloc_i32(i32 0)",
                        "br i1 %c, label %L, label %J",
                        "%t = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%o = call i32 @cqrt_alloc_i32(i32 0)",
                        "call void @cqrt_copy_i32(i32 %t, i32 %o)",
                        "call void @cq_template_add_i32_hl_unc(i32 %t, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %t)",
                        "call void @cqrt_free(i32 %s)",
                        "br label %J",
                        "%m = phi i32 [ %s, %entry ], [ %o, %L ]",
                        "%r = call i32 @cqrt_measure_i32(i32 %m)",
                        "ret i32 %r",
                    });
}

// cq_theta on the merge (lowerTheta: the role first, then the gate): the gate hits the chosen arm, so
// a garbage rail that read the merge before the rotation cannot be uncomputed after it (A4).
void merge_kept_rotated() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c, i32 %v) {
entry:
  br i1 %c, label %A, label %B
A:
  %ha = call i32 @cqrt_alloc_i32(i32 %a0)
  br label %J
B:
  %hb = call i32 @cqrt_alloc_i32(i32 %v)
  br label %J
J:
  %m = phi i32 [ %ha, %A ], [ %hb, %B ]
  %t = call i32 @cq_template_add_i32_hl(i32 %m, i32 1)
  call void @cqrt_ry_i32(i32 %m, double %th)
  %r = call i32 @cqrt_measure_i32(i32 %m)
  %q = call i32 @cqrt_measure_i32(i32 %t)
  ret i32 %r
})");
  f.S("ha");
  f.S("hb");
  f.U.flushBefore(f.I("ha")->getParent()->getTerminator());
  f.U.flushBefore(f.I("hb")->getParent()->getTerminator());
  RailId m = f.U.recordMerge(f.I("m"));
  RailId t = f.T("t", "hl");
  f.U.setRole(m, Role::UserRegister);
  f.U.noteNonDiagonal(m, f.call("cqrt_ry_i32"));
  f.U.setRole(t, Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "br i1 %c, label %A, label %B",
                        "%ha = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "br label %J",
                        "%hb = call i32 @cqrt_alloc_i32(i32 %v)",
                        "br label %J",
                        "%m = phi i32 [ %ha, %A ], [ %hb, %B ]",
                        "%t = call i32 @cq_template_add_i32_hl(i32 %m, i32 1)",
                        "call void @cqrt_ry_i32(i32 %m, double %th)",
                        "%r = call i32 @cqrt_measure_i32(i32 %m)",
                        "%q = call i32 @cqrt_measure_i32(i32 %t)",
                        "ret i32 %r",
                    });
}

// The unchosen arm s is still read by a pending garbage rail u on the loop edge: freeing s there would
// leave u's uncompute without its operand. Unimplemented.
void fatal_merge_unchosen_reader() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %s = call i32 @cqrt_alloc_i32(i32 %a0)
  %u = call i32 @cq_template_add_i32_hl(i32 %s, i32 1)
  br i1 %c, label %L, label %J
L:
  %o = call i32 @cqrt_alloc_i32(i32 0)
  br label %J
J:
  %m = phi i32 [ %s, %entry ], [ %o, %L ]
  %r = call i32 @cqrt_measure_i32(i32 %m)
  %q = call i32 @cqrt_measure_i32(i32 %u)
  ret i32 %r
})");
  f.S("s");
  f.T("u", "hl");
  f.S("o");
  f.U.setRole(f.U.recordMerge(f.I("m")), Role::Measured);
}

// The unchosen arm s is read directly after the join: it cannot be freed on the loop edge.
void fatal_merge_unchosen_used_after() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %s = call i32 @cqrt_alloc_i32(i32 %a0)
  br i1 %c, label %L, label %J
L:
  %o = call i32 @cqrt_alloc_i32(i32 0)
  br label %J
J:
  %m = phi i32 [ %s, %entry ], [ %o, %L ]
  %r = call i32 @cqrt_measure_i32(i32 %m)
  %q = call i32 @cqrt_measure_i32(i32 %s)
  ret i32 %r
})");
  f.S("s");
  f.S("o");
  f.U.setRole(f.U.recordMerge(f.I("m")), Role::Measured);
}

// cq-sodl (rev/bv91-n1/p1.c): the zero-trip arm s is freed on the loop edge; the spine lowers a
// direct read of s after the join only after the kept consumer (cq_measure(a * 5) after the loop).
// That read is caught when it is recorded: unimplemented, not a use after free.
void fatal_merge_unchosen_read_later() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %s = call i32 @cqrt_alloc_i32(i32 %a0)
  br i1 %c, label %L, label %J
L:
  %o = call i32 @cqrt_alloc_i32(i32 0)
  br label %J
J:
  %m = phi i32 [ %s, %entry ], [ %o, %L ]
  %r = call i32 @cqrt_measure_i32(i32 %m)
  ret i32 %r
})");
  RailId s = f.S("s");
  f.S("o");
  f.U.setRole(f.U.recordMerge(f.I("m")), Role::Measured);
  IRBuilder<> B(f.ret());
  CallInst *u = B.CreateCall(f.M->getFunction("cq_template_mul_i32_hl"), {f.I("s"), B.getInt32(5)});
  (void)s;
  f.U.recordTemplate(u, {}, {H(u->getArgOperand(0)), Operand{u->getArgOperand(1), false}});
}

// cq-sodl (rev/bv91-n1/q8.ll): the edge from A carries a nested merge n = select(k, t, x) that may
// still choose t, so t is chosen on both edges and is never freed on A's edge; n is a kept classical
// select with a resolvable arm t: unimplemented (cq-aqeq), whichever order the phi lists its arms in.
const char *kNestedSel = R"(
define i32 @f(i32 %a0, double %th, i1 %c, i1 %k) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %t = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  br i1 %c, label %A, label %B
A:
  %n = select i1 %k, i32 %t, i32 %x
  br label %J
B:
  br label %J
J:
  %m = phi i32 [ %ARM1 ], [ %ARM2 ]
  %r = call i32 @cqrt_measure_i32(i32 %m)
  ret i32 %r
})";
void nestedSel(bool selFirst) {
  std::string ir = kNestedSel;
  std::string a1 = selFirst ? "%n, %A" : "%t, %B", a2 = selFirst ? "%t, %B" : "%n, %A";
  ir.replace(ir.find("%ARM1"), 5, a1);
  ir.replace(ir.find("%ARM2"), 5, a2);
  Fx f(ir);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32"));
  f.T("t", "hl");
  f.U.recordMerge(f.I("n"));
  f.U.setRole(f.U.recordMerge(f.I("m")), Role::Measured);
}
void fatal_merge_nested_select_edge() { nestedSel(true); }
void fatal_merge_nested_select_edge_rev() { nestedSel(false); }

// cq-sodl: m = phi [n, Y], [s, X] with n = phi [s, Z], [b, W]. The edge from Y chooses n, which may
// still be s (from Z): s is freed only on W's edge (where n chooses b), never on Y's.
void merge_kept_nested_phi_edge() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c, i1 %d) {
entry:
  %s = call i32 @cqrt_alloc_i32(i32 %a0)
  br i1 %c, label %X, label %Y0
Y0:
  br i1 %d, label %Z, label %W
Z:
  br label %N
W:
  %b = call i32 @cqrt_alloc_i32(i32 7)
  br label %N
N:
  %n = phi i32 [ %s, %Z ], [ %b, %W ]
  br label %J
X:
  br label %J
J:
  %m = phi i32 [ %n, %N ], [ %s, %X ]
  %r = call i32 @cqrt_measure_i32(i32 %m)
  ret i32 %r
})");
  f.S("s");
  f.S("b");
  f.U.recordMerge(f.I("n"));
  f.U.setRole(f.U.recordMerge(f.I("m")), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%s = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "br i1 %c, label %X, label %Y0",
                        "br i1 %d, label %Z, label %W",
                        "br label %N",
                        "%b = call i32 @cqrt_alloc_i32(i32 7)",
                        "call void @cqrt_free(i32 %s)",
                        "br label %N",
                        "%n = phi i32 [ %s, %Z ], [ %b, %W ]",
                        "br label %J",
                        "br label %J",
                        "%m = phi i32 [ %n, %N ], [ %s, %X ]",
                        "%r = call i32 @cqrt_measure_i32(i32 %m)",
                        "ret i32 %r",
                    });
}

// cq-1dgy (rev/sodl-n1/r1.ll, r3.c): the join is inside a loop and the arm a is defined before it.
// a is unchosen on P's edge, so it would be freed at the end of P; the back edge then reaches Q, whose
// edge chooses the same a (use after free), and P again (double free). Refused.
const char *kLoopArm = R"(
define i32 @f(i32 %a0, i1 %c, i1 %d) {
entry:
  %a = call i32 @cqrt_alloc_i32(i32 %a0)
  br label %H
H:
  br i1 %c, label %P, label %Q
P:
  %b = call i32 @cqrt_alloc_i32(i32 7)
  br label %J
Q:
  br label %J
J:
  %m = phi i32 [ %b, %P ], [ %a, %Q ]
  %r = call i32 @cqrt_measure_i32(i32 %m)
  br i1 %d, label %H, label %X
X:
  ret i32 %r
})";

void fatal_merge_unchosen_loop() {
  Fx f(kLoopArm);
  f.S("a");
  f.S("b");
  f.U.setRole(f.U.recordMerge(f.I("m")), Role::Measured);
  f.U.flushAtExit(f.ret());
}

// A kept role on a classical select whose arms are resolvable: keeping only the chosen arm would need
// a branch on the condition (not built). Keeping every arm would keep the unchosen arm's garbage (an
// extra kept rail, §6-different from rule 9's "arm rails uncomputed").
void fatal_merge_kept_role() {
  Fx f(kSel);
  f.reg("x", 0);
  f.T("ha", "hl");
  f.T("hb", "hl");
  f.U.setRole(f.U.recordMerge(f.I("m")), Role::Measured);
}

void fatal_merge_nondiagonal() {
  Fx f(kSel);
  f.reg("x", 0);
  f.T("ha", "hl");
  f.T("hb", "hl");
  f.U.noteNonDiagonal(f.U.recordMerge(f.I("m")), f.call("cqrt_ry_i32"));
}

// A phi over arm-local garbage handles: no point after the merged handle's uses can name the arm (cq-ut4k).
// cq-ut4k: a phi over arm-local garbage handles. Each arm's item runs at the return under its arm's
// selector (true on the paths through the arm's block), in a block of its own, the arm carried there
// by a phi (poison on the paths that skip it).
void merge_arm_local() {
  Fx f(R"(
define i32 @f(i32 %a0, double %th, i1 %c) {
entry:
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  br i1 %c, label %A, label %B
A:
  %ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  br label %J
B:
  %hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)
  br label %J
J:
  %m = phi i32 [ %ha, %A ], [ %hb, %B ]
  %t = call i32 @cq_template_mul_i32_hl(i32 %m, i32 3)
  %r = call i32 @cqrt_measure_i32(i32 %t)
  ret i32 %r
})");
  f.reg("x", 0);
  f.T("ha", "hl");
  f.T("hb", "hl");
  f.U.recordMerge(f.I("m"));
  f.U.setRole(f.T("t", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "br i1 %c, label %A, label %B",
                        "%ha = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "br label %J",
                        "%hb = call i32 @cq_template_shl_i32_hl(i32 %x, i32 1)",
                        "br label %J",
                        "%hb6 = phi i32 [ %hb, %B ], [ poison, %A ]",
                        "%ha5 = phi i32 [ poison, %B ], [ %ha, %A ]",
                        "%cq.on = phi i1 [ true, %B ], [ false, %A ]",
                        "%cq.on3 = phi i1 [ false, %B ], [ true, %A ]",
                        "%m = phi i32 [ %ha, %A ], [ %hb, %B ]",
                        "%t = call i32 @cq_template_mul_i32_hl(i32 %m, i32 3)",
                        "br i1 %cq.on, label %J.cq.arm2, label %J.cq.after1",
                        "call void @cq_template_shl_i32_hl_unc(i32 %hb6, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %hb6)",
                        "br label %J.cq.after1",
                        "br i1 %cq.on3, label %J.cq.arm, label %J.cq.after",
                        "call void @cq_template_add_i32_hl_unc(i32 %ha5, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %ha5)",
                        "br label %J.cq.after",
                        "%r = call i32 @cqrt_measure_i32(i32 %t)",
                        "ret i32 %r",
                    });
}

// ---- cq-zh7z: a gate on a handle loaded from a slot cell that may hold an operand rail ----------

// b1's shape: x sits in cell i, a fresh seed is stored to cell m, cell i is reloaded (%l: x when
// m != i, the seed when m == i) and rotated, and g, which read x, is read after the Ry. Rule 5 needs
// g's _unc before the Ry when %l is x, and CR §0 needs it cleaned when it is not: unimplemented.
const char *kAliasIr = R"(
define i32 @f(i32 %a0, i64 %i, i64 %m, double %th) {
  %cells = alloca i32, i64 4
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %pi = getelementptr inbounds i32, ptr %cells, i64 %i
  store i32 %x, ptr %pi
  %g = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %z = call i32 @cqrt_alloc_i32(i32 0)
  %pm = getelementptr inbounds i32, ptr %cells, i64 %m
  store i32 %z, ptr %pm
  %pj = getelementptr inbounds i32, ptr %cells, i64 IDX
  %l = load i32, ptr %pj
  call void @cqrt_ry_i32(i32 %l, double %th)
  %q = call i32 @cq_template_mul_i32_hl(i32 %g, i32 3)
  %r = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %r
})";

void aliasCase(const char *idx) {
  std::string ir = kAliasIr;
  ir.replace(ir.find("IDX"), 3, idx);
  Fx f(ir);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  f.T("g", "hl");
  f.U.setRole(f.S("z"), Role::UserRegister);
  f.U.recordExternal(f.I("l"), Role::UserRegister);
  f.U.noteNonDiagonal(f.id("l"), f.call("cqrt_ry_i32", 1));
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
}

void fatal_alias_slot_reload() { aliasCase("%i"); }

void alias_distinct_cell() {
  // x in cell 0, the seed in cell 1, the Ry on a reload of cell 1: never x, so g is cleaned after
  // its consumer as before.
  std::string ir = kAliasIr;
  ir.replace(ir.find("i64 %i\n  store i32 %x"), 6, "i64 0");
  ir.replace(ir.find("i64 %m\n  store i32 %z"), 6, "i64 1");
  ir.replace(ir.find("IDX"), 3, "1");
  Fx f(ir);
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  f.T("g", "hl");
  f.U.setRole(f.S("z"), Role::UserRegister);
  f.U.recordExternal(f.I("l"), Role::UserRegister);
  f.U.noteNonDiagonal(f.id("l"), f.call("cqrt_ry_i32", 1));
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
  f.check(__func__, {
                        "%cells = alloca i32, i64 4, align 4",
                        "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                        "call void @cqrt_ry_i32(i32 %x, double %th)",
                        "%pi = getelementptr inbounds i32, ptr %cells, i64 0",
                        "store i32 %x, ptr %pi, align 4",
                        "%g = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                        "%z = call i32 @cqrt_alloc_i32(i32 0)",
                        "%pm = getelementptr inbounds i32, ptr %cells, i64 1",
                        "store i32 %z, ptr %pm, align 4",
                        "%pj = getelementptr inbounds i32, ptr %cells, i64 1",
                        "%l = load i32, ptr %pj, align 4",
                        "call void @cqrt_ry_i32(i32 %l, double %th)",
                        "%q = call i32 @cq_template_mul_i32_hl(i32 %g, i32 3)",
                        "call void @cq_template_add_i32_hl_unc(i32 %g, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %g)",
                        "%r = call i32 @cqrt_measure_i32(i32 %q)",
                        "ret i32 %r",
                    });
}

// The reverse direction: g read a reload %l of cell i, and the Ry is on x, which sits in cell i.
void fatal_alias_slot_direct() {
  Fx f(R"(
define i32 @f(i32 %a0, i64 %i, double %th) {
  %cells = alloca i32, i64 4
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %pi = getelementptr inbounds i32, ptr %cells, i64 %i
  store i32 %x, ptr %pi
  %pj = getelementptr inbounds i32, ptr %cells, i64 %i
  %l = load i32, ptr %pj
  %g = call i32 @cq_template_add_i32_hl(i32 %l, i32 1)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %q = call i32 @cq_template_mul_i32_hl(i32 %g, i32 3)
  %r = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %r
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  f.U.recordExternal(f.I("l"), Role::UserRegister);
  f.T("g", "hl");
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 1));
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
}

// ---- cq-vdaa: the rail reaches a second slot array through a copy of a reload -----------------

// c1's shape: x sits in q[i]; a reload %l of q[j] (x when j == i) is stored to s[k]; a reload %l2 of
// s[m] (x when j == i and k == m) is rotated, and g, which read x, is read after the Ry.
const char *kCopyIr = R"(
define i32 @f(i32 %a0, i64 %i, i64 %j, i64 %k, i64 %m, double %th) {
  %qa = alloca i32, i64 4
  %sa = alloca i32, i64 4
  %ta = alloca i32, i64 4
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %pi = getelementptr inbounds i32, ptr %qa, i64 %i
  store i32 %x, ptr %pi
  %g = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  %pj = getelementptr inbounds i32, ptr %qa, i64 %j
  %l = load i32, ptr %pj
  %pk = getelementptr inbounds i32, ptr %sa, i64 %k
  store i32 %l, ptr %pk
  %pm = getelementptr inbounds i32, ptr GATEARR, i64 %m
  %l2 = load i32, ptr %pm
  call void @cqrt_ry_i32(i32 %l2, double %th)
  %q = call i32 @cq_template_mul_i32_hl(i32 %g, i32 3)
  %r = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %r
})";

void copyCase(const char *arr, Fx *&out, std::string &keep) {
  keep = kCopyIr;
  keep.replace(keep.find("GATEARR"), 7, arr);
  out = new Fx(keep);
  Fx &f = *out;
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  f.T("g", "hl");
  f.U.recordExternal(f.I("l"), Role::UserRegister);
  f.U.recordExternal(f.I("l2"), Role::UserRegister);
  f.U.noteNonDiagonal(f.id("l2"), f.call("cqrt_ry_i32", 1));
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
}

void fatal_alias_second_array() {
  Fx *f;
  std::string ir;
  copyCase("%sa", f, ir);
}

// The rotated reload comes from a third array the rail never reaches: g is cleaned after its
// consumer as before.
void alias_copy_distinct_array() {
  Fx *f;
  std::string ir;
  copyCase("%ta", f, ir);
  f->check(__func__, {
                         "%qa = alloca i32, i64 4, align 4",
                         "%sa = alloca i32, i64 4, align 4",
                         "%ta = alloca i32, i64 4, align 4",
                         "%x = call i32 @cqrt_alloc_i32(i32 %a0)",
                         "call void @cqrt_ry_i32(i32 %x, double %th)",
                         "%pi = getelementptr inbounds i32, ptr %qa, i64 %i",
                         "store i32 %x, ptr %pi, align 4",
                         "%g = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)",
                         "%pj = getelementptr inbounds i32, ptr %qa, i64 %j",
                         "%l = load i32, ptr %pj, align 4",
                         "%pk = getelementptr inbounds i32, ptr %sa, i64 %k",
                         "store i32 %l, ptr %pk, align 4",
                         "%pm = getelementptr inbounds i32, ptr %ta, i64 %m",
                         "%l2 = load i32, ptr %pm, align 4",
                         "call void @cqrt_ry_i32(i32 %l2, double %th)",
                         "%q = call i32 @cq_template_mul_i32_hl(i32 %g, i32 3)",
                         "call void @cq_template_add_i32_hl_unc(i32 %g, i32 %x, i32 1)",
                         "call void @cqrt_free(i32 %g)",
                         "%r = call i32 @cqrt_measure_i32(i32 %q)",
                         "ret i32 %r",
                     });
}

// c2's shape, the reverse: g read a reload %l2 of s[m], which may be x copied there through a
// reload of q[j]; the Ry is on x itself.
void fatal_alias_second_array_rev() {
  Fx f(R"(
define i32 @f(i32 %a0, i64 %i, i64 %j, i64 %k, i64 %m, double %th) {
  %qa = alloca i32, i64 4
  %sa = alloca i32, i64 4
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %pi = getelementptr inbounds i32, ptr %qa, i64 %i
  store i32 %x, ptr %pi
  %pj = getelementptr inbounds i32, ptr %qa, i64 %j
  %l = load i32, ptr %pj
  %pk = getelementptr inbounds i32, ptr %sa, i64 %k
  store i32 %l, ptr %pk
  %pm = getelementptr inbounds i32, ptr %sa, i64 %m
  %l2 = load i32, ptr %pm
  %g = call i32 @cq_template_add_i32_hl(i32 %l2, i32 1)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %q = call i32 @cq_template_mul_i32_hl(i32 %g, i32 3)
  %r = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %r
})");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  f.U.recordExternal(f.I("l"), Role::UserRegister);
  f.U.recordExternal(f.I("l2"), Role::UserRegister);
  f.T("g", "hl");
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 1));
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
}

// A memcpy of the whole first array into the second: the rotated reload of s[m] may be x.
void fatal_alias_memcpy() {
  Fx f(R"(
define i32 @f(i32 %a0, i64 %i, i64 %m, double %th) {
  %qa = alloca i32, i64 4
  %sa = alloca i32, i64 4
  %x = call i32 @cqrt_alloc_i32(i32 %a0)
  call void @cqrt_ry_i32(i32 %x, double %th)
  %pi = getelementptr inbounds i32, ptr %qa, i64 %i
  store i32 %x, ptr %pi
  %g = call i32 @cq_template_add_i32_hl(i32 %x, i32 1)
  call void @llvm.memcpy.p0.p0.i64(ptr %sa, ptr %qa, i64 16, i1 false)
  %pm = getelementptr inbounds i32, ptr %sa, i64 %m
  %l2 = load i32, ptr %pm
  call void @cqrt_ry_i32(i32 %l2, double %th)
  %q = call i32 @cq_template_mul_i32_hl(i32 %g, i32 3)
  %r = call i32 @cqrt_measure_i32(i32 %q)
  ret i32 %r
}
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1))");
  RailId x = f.reg("x", 0);
  f.U.noteNonDiagonal(x, f.call("cqrt_ry_i32", 0));
  f.T("g", "hl");
  f.U.recordExternal(f.I("l2"), Role::UserRegister);
  f.U.noteNonDiagonal(f.id("l2"), f.call("cqrt_ry_i32", 1));
  f.U.setRole(f.T("q", "hl"), Role::Measured);
  f.U.flushAtExit(f.ret());
}

const std::map<std::string, std::function<void()>> kPositive = {
    {"reverse_dependency_order", reverse_dependency_order},
    {"independent_most_recent_first", independent_most_recent_first},
    {"last_use_ir", last_use_ir},
    {"last_use_noted", last_use_noted},
    {"nondiagonal_before", nondiagonal_before},
    {"nondiagonal_kept", nondiagonal_kept},
    {"nondiagonal_transitive", nondiagonal_transitive},
    {"rule10_flag_kept", rule10_flag_kept},
    {"measure_is_not_a_barrier", measure_is_not_a_barrier},
    {"rule6_sequence", rule6_sequence},
    {"scope_mirror_order", scope_mirror_order},
    {"scope_nested", scope_nested},
    {"seed_direct", seed_direct},
    {"seed_xorc_direct", seed_xorc_direct},
    {"seed_written_undone", seed_written_undone},
    {"qram_lifo", qram_lifo},
    {"qram_call_bus_read", qram_call_bus_read},
    {"qram_rmw", qram_rmw},
    {"qram_realloc", qram_realloc},
    {"qram_kept_bus", qram_kept_bus},
    {"qram_pop_kept", qram_pop_kept},
    {"multi_exit", multi_exit},
    {"arm_flush", arm_flush},
    {"ex14_fmuladd", ex14_fmuladd},
    {"ex42_measure_one_of_two", ex42_measure_one_of_two},
    {"ex162_consumer", ex162_consumer},
    {"ex144_rule6", ex144_rule6},
    {"merge_measured", merge_measured},
    {"cell_load_garbage", cell_load_garbage},
    {"cell_load_kept", cell_load_kept},
    {"deferred_kept_through_memory", deferred_kept_through_memory},
    {"call_two_results", call_two_results},
    {"call_all_kept", call_all_kept},
    {"call_slotout_unused", call_slotout_unused},
    {"call_reads", call_reads},
    {"resolve_at", resolve_at},
    {"pointee_before_store", pointee_before_store},
    {"merge_all_arms_kept", merge_all_arms_kept},
    {"merge_template_then_garbage", merge_template_then_garbage},
    {"merge_noted_use", merge_noted_use},
    {"merge_phi", merge_phi},
    {"merge_arm_local", merge_arm_local},
    {"merge_nested", merge_nested},
    {"merge_kept_arm_local", merge_kept_arm_local},
    {"merge_kept_unchosen_edge", merge_kept_unchosen_edge},
    {"merge_kept_rotated", merge_kept_rotated},
    {"merge_kept_nested_phi_edge", merge_kept_nested_phi_edge},
    {"alias_distinct_cell", alias_distinct_cell},
    {"alias_copy_distinct_array", alias_copy_distinct_array},
};

const std::map<std::string, std::function<void()>> kFatal = {
    {"fatal_use_after_free", fatal_use_after_free},
    {"fatal_cell_load_empty", fatal_cell_load_empty},
    {"fatal_call_mixed", fatal_call_mixed},
    {"fatal_pointee_write", fatal_pointee_write},
    {"fatal_resolve_at_used", fatal_resolve_at_used},
    {"fatal_resolve_at_bypass", fatal_resolve_at_bypass},
    {"fatal_operand_mismatch", fatal_operand_mismatch},
    {"fatal_unflushed_arm", fatal_unflushed_arm},
    {"fatal_scope_order", fatal_scope_order},
    {"fatal_mirror_outside_reader", fatal_mirror_outside_reader},
    {"fatal_write_barrier", fatal_write_barrier},
    {"fatal_qram_kept_bus_barrier", fatal_qram_kept_bus_barrier},
    {"fatal_qram_realloc_kept", fatal_qram_realloc_kept},
    {"fatal_call_bus_read_unrecorded", fatal_call_bus_read_unrecorded},
    {"fatal_unknown_handle", fatal_unknown_handle},
    {"fatal_merge_kept_role", fatal_merge_kept_role},
    {"fatal_merge_nondiagonal", fatal_merge_nondiagonal},
    {"fatal_merge_unchosen_reader", fatal_merge_unchosen_reader},
    {"fatal_merge_unchosen_used_after", fatal_merge_unchosen_used_after},
    {"fatal_merge_unchosen_read_later", fatal_merge_unchosen_read_later},
    {"fatal_merge_nested_select_edge", fatal_merge_nested_select_edge},
    {"fatal_merge_nested_select_edge_rev", fatal_merge_nested_select_edge_rev},
    {"fatal_merge_unchosen_loop", fatal_merge_unchosen_loop},
    {"fatal_alias_slot_reload", fatal_alias_slot_reload},
    {"fatal_alias_slot_direct", fatal_alias_slot_direct},
    {"fatal_alias_second_array", fatal_alias_second_array},
    {"fatal_alias_second_array_rev", fatal_alias_second_array_rev},
    {"fatal_alias_memcpy", fatal_alias_memcpy},
};

} // namespace

int main(int argc, char **argv) {
  if (argc == 1) {
    for (auto &[name, fn] : kPositive) {
      fn();
      outs() << name << "\n";
    }
    outs() << kPositive.size() << " cases, " << failures << " failed\n";
    return failures ? 1 : 0;
  }
  std::string c = argv[1];
  if (auto it = kPositive.find(c); it != kPositive.end()) {
    it->second();
    return failures ? 1 : 0;
  }
  if (auto it = kFatal.find(c); it != kFatal.end()) {
    it->second();
    errs() << "FAIL " << c << ": returned without a fatal error\n";
    return 1;
  }
  errs() << "unknown case " << c << "\n";
  return 2;
}
