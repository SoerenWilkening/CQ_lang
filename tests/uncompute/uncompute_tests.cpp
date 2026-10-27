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
                        "call void @cqrt_qram_store_i32_hl_unc(i32 %a, i32 0, i32 %v1)",
                        "call void @cqrt_qram_free(i32 %a)",
                        "call void @cq_template_add_i32_hl_unc(i32 %v2, i32 %x, i32 2)",
                        "call void @cqrt_free(i32 %v2)",
                        "call void @cq_template_add_i32_hl_unc(i32 %v1, i32 %x, i32 1)",
                        "call void @cqrt_free(i32 %v1)",
                        "%m = call i32 @cqrt_measure_i32(i32 %s)",
                        "ret i32 %m",
                    });
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

void fatal_unflushed_arm() {
  Fx f(kArm);
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
    {"multi_exit", multi_exit},
    {"arm_flush", arm_flush},
    {"ex14_fmuladd", ex14_fmuladd},
    {"ex42_measure_one_of_two", ex42_measure_one_of_two},
    {"ex162_consumer", ex162_consumer},
    {"ex144_rule6", ex144_rule6},
};

const std::map<std::string, std::function<void()>> kFatal = {
    {"fatal_use_after_free", fatal_use_after_free},
    {"fatal_operand_mismatch", fatal_operand_mismatch},
    {"fatal_unflushed_arm", fatal_unflushed_arm},
    {"fatal_scope_order", fatal_scope_order},
    {"fatal_mirror_outside_reader", fatal_mirror_outside_reader},
    {"fatal_write_barrier", fatal_write_barrier},
    {"fatal_unknown_handle", fatal_unknown_handle},
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
