// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "cq/Common.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Module.h"

// Abi.h  (CR §1.1-§1.4)
namespace cq::abi {
struct TemplateSpec {
  std::string op, pred;                  // CR §1.2 op; icmp/fcmp/fcmps predicate or ""
  RailType w; std::optional<RailType> to;
  std::string shape;                     // "" = all handles; else one of h/q/l per data operand
  enum Rm : uint8_t { NoRm, RmLit, RmRail } rm = NoRm;
  bool exc = false;     // _exc
};
std::string name(const TemplateSpec &, bool unc);
llvm::FunctionCallee declare(llvm::Module &, const TemplateSpec &, bool unc);
std::optional<TemplateSpec> parseTemplate(llvm::StringRef symbol, bool *unc);
enum class Core : uint8_t { Alloc, Free, Measure, Ry, RyQAngle, RzI1, RzQAngle, NotI1, AndI1, OrI1, XorI1,
  Copy, Xorc, QramAlloc, QramStore, QramLoad, QramSwap, TapeAlloc, TapeFmt, TapeEffect,
  TapeEffectW,   // CR §1.3: tape_effect_<W>_controlled(c, t, name, n) -> r
  TapeWrite, TapeWriteLit, AbortI1, Push, Pop,
  InvertBegin, InvertEnd };   // cq-4593 (cq-arch 2026-11-02): CR §1.3, rule 17
// CR §1.3: the host symbols of the injection bundle's runtime object (rules 16, 19): i32 __cq_mem(),
// ptr __cq_alloc(i64 size, i64 align), void __cq_clone_register(ptr fn, ptr sig, ptr clone, ptr ctl, ptr unc,
// ptr ctl_unc), ptr __cq_clone_resolve(ptr fn, i32 kind), i32 __cq_clone_count(ptr sig), ptr __cq_clone_at(ptr sig,
// i32 i), void __cq_object(i64 addr, i64 size), void __cq_unbound(i32 h) (BACKEND_ABI §1.10, Objects; CR rule 20);
// [65 x i64] @__cq_sig is sigTable.
enum class Host : uint8_t { Mem, Alloc, CloneRegister, CloneResolve, CloneCount, CloneAt, Object, Unbound };
llvm::FunctionCallee declareHost(llvm::Module &, Host);
llvm::GlobalVariable *sigTable(llvm::Module &);
struct CoreSpec { Core op; RailType w{}; bool ctl = false, hl = false, unc = false; };
std::string name(const CoreSpec &);
llvm::FunctionCallee declare(llvm::Module &, const CoreSpec &);
std::optional<CoreSpec> parseCore(llvm::StringRef symbol);
struct CloneSpec { std::string fn; Mask mask; std::vector<uint64_t> bounds;
                   bool ctl = false, pure = false; bool unc = false;
                   bool table = false;      // CR §1.4: the table clone _t (kinds _t, _t_ctl, _t_unc, _t_ctl_unc)
                   uint8_t rm = 0; };       // CR §1.4 (owner 2026-11-12, cq-a9ij3): 1 _rm (classical mode), 2 _rmq (mode rail)
std::string name(const CloneSpec &);
std::optional<CloneSpec> parseClone(llvm::StringRef symbol);
std::string asmCloneFn(const llvm::InlineAsm &);    // "asm_" + first 16 lowercase hex of sha256(asm string as LLVM spells it, one NUL byte, constraint string)
}
