// eff-fenv's loop hook (cq-9kcq S12b, cq-v1fu; CR rules 14, 23): the quantum floating-point environment as a value a
// rolled loop carries. Defined in pass/lib/eff/fenv/Fenv.cpp.
//
// eff-fenv tracks the quantum part of the environment (FLAGS, MODE: Fenv.cpp's header) as an SSA variable of the output
// function, its value at the end of each output block where it changed and phis over handles at joins. A rolled loop
// (loops-classical's classically bounded loops, loops-cutoff's rolled K-loop) lowers its trip once, before its back edge
// exists, so without this hook every trip would read the pre-loop state, the flags would not accumulate, and the reverse
// loop would undo the exit state. The loop module carries each piece as it carries a header phi over handles:
//
//   1. At the end of the loop's entry block E (the builder there, before the branch to the header H):
//        pieces = fenv::loopCarried(ctx, L)
//      names every piece of the state some trip of L may change, each with its value at E as a rail (an empty FLAGS
//      becomes alloc_i32(0), a classical MODE alloc_i32 of the host mode, both made at the builder).
//   2. In H: one phi over handles per piece, E's incoming the piece's init (carried: noteCarried, as every other carried
//      handle phi), then fenv::bindPiece(ctx, id, phi) so the trip reads the phi.
//   3. At the latch (the builder at the end of the trip): fenv::pieceNow(ctx, id) is the phi's back-edge incoming.
//   4. After the loop, at its exit block X: the piece's exit value (X's phi over the exit edges, or the latch value) is
//      bound with bindPiece and passed to the exit wiring (Region::wireExits) as a value read after the loop, so it is
//      read in place or copied out before the reverse loop undoes the trips; the wired value is bound again with
//      bindPiece. fenv::pieceKey(ctx, id) is the key that names the piece in the wiring's list: a detached value no
//      program has, with no users (so rolled::readersKeep finds no reader that keeps it).
//
// With no piece (the loop changes no state, or the function has no quantum environment) the hook adds nothing.
#pragma once

#include <vector>

#include "cq/Lowering.h"

#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Value.h"

namespace cq::fenv {

// A piece of the carried state: 0 FLAGS, 1 MODE (the quantum part's two fields; the saved parts of fenv_t / fexcept_t
// objects are not carried yet).
struct CarriedPiece {
  unsigned id;
  llvm::Value *init;   // the piece's rail at the builder's point (step 1)
};

std::vector<CarriedPiece> loopCarried(LoweringContext &ctx, const llvm::Loop &L);
llvm::Value *pieceNow(LoweringContext &ctx, unsigned id);
void bindPiece(LoweringContext &ctx, unsigned id, llvm::Value *h);
const llvm::Value *pieceKey(LoweringContext &ctx, unsigned id);
// cq-9kcq S12d (CR rules 6, 23): is h a rail the environment holds or held as its state (MODE, FLAGS, a saved part:
// every such rail is anchored)? Rule 6 never cleans such a rail (fegetround's result is the MODE rail itself).
bool stateRail(LoweringContext &ctx, const llvm::Value *h);
// cq-9ea1d (CR rules 9, 23): the spine's arm flush (Uncompute::flushBefore with liveLater) asks which rails a later
// instruction may still read. The state is read lazily, so a read after a classical join merges the values the state
// held at the ends of that join's arms: while an instruction not lowered yet (lowered(I) false) may read the state,
// every rail the state held at an output block's end or start is appended to `out`. Nothing when there is no state.
void liveState(LoweringContext &ctx, llvm::function_ref<bool(const llvm::Instruction &)> lowered,
               std::vector<llvm::Value *> &out);

} // namespace cq::fenv
