// Module eff-invert: cq_invert regions, CR rule 17 (CQ_spec f684858; cq-4593).
//
// Rule 17: the markers are the run-time primitives cqrt_invert_begin() / cqrt_invert_end() (CR §1.3,
// BACKEND_ABI 1.13). The code between them is lowered exactly as it would be anywhere else; the backend,
// which builds the circuit as the host program runs (§0), emits the gates recorded between the two calls
// reversed, each inverted (allocations keep their place, frees move after the reversed list, a
// measurement inside flushes the gates before it forward). No _adj clone exists (§1.4).
//
// CONSTRUCTION. Each __cq_invert_begin / __cq_invert_end call becomes the call of cqrt_invert_begin /
// cqrt_invert_end at the point the walker reaches it; CQ.h's asm fence next to it (the empty asm with a
// memory clobber the macros place after begin and before end) is consumed. Since begin and end are
// events of the host execution, a region that a classical branch opens, that spans loops or blocks, that
// returns inside, or that nests needs no analysis.
//
// Uncompute placement (rule 5, placement is free; rule 17: "the compiler places no uncompute of a rail
// allocated before the region inside it"). Every rail pending at begin is held while the region is open
// (Uncompute::openInvert); at end (closeInvert) its item follows the end marker when the region used it,
// else it goes after its last use before the begin. A rail the region makes is placed by the ordinary
// rules: right after its last use, inside the region when every use is (the backend then reverses a
// compute/uncompute pair into itself); a rail the region makes and the program reads after it outlives
// the region, as rule 17 says.
//
// References: Bennett.jl 824458d src/bennett_transform.jl:_bennett_default replays a gate list in reverse
// order, each gate by its inverse; BACKEND_ABI 1.13 cites src/circuit.jl:adjoint for the backend's half.
#include "cq/Effects.h"

#include "cq/Abi.h"
#include "cq/Calls.h"
#include "cq/Lowering.h"
#include "cq/Uncompute.h"

#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace cq::invert {

namespace {

const Function *calleeOf(const Instruction *I) {
  auto *C = dyn_cast_or_null<CallBase>(I);
  return C ? C->getCalledFunction() : nullptr;
}

bool isMarker(const Instruction *I, StringRef name) {
  const Function *F = calleeOf(I);
  return F && F->getName() == name;
}

// CQ.h's barrier: an empty asm with a memory clobber and no operands.
bool isFence(const Instruction &I) {
  auto *C = dyn_cast<CallInst>(&I);
  if (!C || !C->isInlineAsm() || C->arg_size() != 0 || !C->getType()->isVoidTy())
    return false;
  auto *IA = cast<InlineAsm>(C->getCalledOperand());
  return IA->getAsmString().empty() && IA->getConstraintString().find("~{memory}") != std::string::npos;
}

} // namespace

bool isMarkerFence(const Instruction &I) {
  if (!isFence(I))
    return false;
  const Instruction *prev = I.getPrevNonDebugInstruction();
  const Instruction *next = I.getNextNonDebugInstruction();
  return isMarker(prev, "__cq_invert_begin") || isMarker(next, "__cq_invert_end");
}

void lowerMarker(LoweringContext &ctx, CallInst &marker) {
  bool begin = isMarker(&marker, "__cq_invert_begin");
  if (!begin && !isMarker(&marker, "__cq_invert_end"))
    internalError("eff-invert: lowerMarker on a call that is no cq_invert marker", &marker);
  Module &M = *ctx.B().GetInsertBlock()->getModule();
  abi::CoreSpec spec{begin ? abi::Core::InvertBegin : abi::Core::InvertEnd};
  CallInst *c = ctx.B().CreateCall(abi::declare(M, spec));
  if (begin)
    ctx.unc().openInvert(c);
  else
    ctx.unc().closeInvert(c);
}

} // namespace cq::invert
