// Operand roles of every ABI call, for the structural verifier (private to module verify).
#pragma once

#include <optional>
#include <string>

#include "cq/Abi.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/InstrTypes.h"

namespace cq::verify {

// What an operand slot of an ABI call does with its value.
enum class Role : uint8_t {
  Classical,  // a literal / classical value; a handle here is handle-in-classical-op
  Read,       // a handle read (operand, control, bus, tape, angle rail)
  Write,      // the target of an in-place XOR-type gate (not/and/or/xor_i1 t, copy d, xorc h)
  Rotate,     // the target of ry / ry_qangle
  UncOut,     // the result rail an _unc returns to |0>
  Free,       // cqrt_free
  BusFree,    // cqrt_qram_free
  Measure,    // cqrt_measure_<W>
  Word,       // cqrt_push: a classical word or a handle
};

// What the call returns.
enum class Res : uint8_t {
  None,       // void
  Classical,  // a classical value (measure)
  Known,      // a fresh handle in a known basis state (alloc, qram_alloc/realloc, tape_alloc)
  Dirty,      // a fresh handle holding a computed value (templates, qram_load, tape_write)
  Word,       // cqrt_pop, and any call that is not an ABI core gate or template
};

enum class Kind : uint8_t { Other, Core, Template, Clone };

struct Sig {
  Kind kind = Kind::Other;
  bool unc = false;
  std::string callee;  // the called symbol ("" for an indirect call)
  std::string fwd;     // for an _unc: the forward symbol
  llvm::SmallVector<Role, 6> roles;  // core and template only
  Res res = Res::Word;
  std::optional<abi::CoreSpec> core;
  std::optional<abi::TemplateSpec> tmpl;
  std::optional<abi::CloneSpec> clone;
};

// One Sig per callee. An ABI symbol abi::parse* rejects, or one whose operand count disagrees with its
// spelling, is a fatal error naming the call.
class SigCache {
public:
  const Sig &get(const llvm::CallBase &CB);

private:
  llvm::DenseMap<const llvm::Value *, Sig> Cache;
  Sig Indirect;
};

} // namespace cq::verify
