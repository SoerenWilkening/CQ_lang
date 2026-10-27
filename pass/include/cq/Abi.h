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
  bool exc = false, strided = false;     // _exc; qrom_load_<W>_s
};
std::string name(const TemplateSpec &, bool unc);
llvm::FunctionCallee declare(llvm::Module &, const TemplateSpec &, bool unc);
std::optional<TemplateSpec> parseTemplate(llvm::StringRef symbol, bool *unc);
enum class Core : uint8_t { Alloc, Free, Measure, Ry, RyQAngle, RzI1, RzQAngle, NotI1, AndI1, OrI1, XorI1,
  Copy, Xorc, QramAlloc, QramRealloc, QramStore, QramLoad, QramFree, TapeAlloc, TapeFmt, TapeEffect,
  TapeWrite, TapeWriteLit, TapeWriteStrLit, AbortI1, Push, Pop };
struct CoreSpec { Core op; RailType w{}; bool ctl = false, hl = false, unc = false; };
std::string name(const CoreSpec &);
llvm::FunctionCallee declare(llvm::Module &, const CoreSpec &);
std::optional<CoreSpec> parseCore(llvm::StringRef symbol);
struct CloneSpec { std::string fn; Mask mask; std::vector<uint64_t> bounds;
                   bool ctl = false, pure = false, adj = false; unsigned depth = 0; bool unc = false; };
std::string name(const CloneSpec &);
std::optional<CloneSpec> parseClone(llvm::StringRef symbol);
std::string asmCloneFn(const llvm::InlineAsm &);    // "asm_" + first 16 hex of sha256(asm string + constraints)
}
