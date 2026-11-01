// Module loops-cutoff, private: the rule-14 loop unit as the spine's loop dispatch (spine/Construct.cpp)
// and loops-cutoff both see it. Not a frozen interface; its consumers are those two files.
//
// A loop dispatched as a unit (CR rule 14) ends where every path out of it meets again: its
// CONTINUATION C. An exit into a dead end that has no effect (every path from it ends in `unreachable`
// with no instruction that writes memory or calls: reaching it is undefined behaviour as LLVM defines
// it, outside the domain; 131's switch default) is no exit of the unit. With one live exit block, C is
// that block and the unit is the loop. With several (121, 190's memcmp: `n && *l == *r`), C is their
// nearest common post-dominator and the unit also holds the EXIT ARM: the blocks outside the loop
// between the live exits and C, entered only from the loop. The loop module lowers the exit arm with
// the loop (each trip's exit through it, rule 9 inside the trip) and binds every phi of C that has an
// incoming from the unit; on return the builder sits where C continues.
#pragma once

#include <cstdint>
#include <optional>

#include "cq/Taint.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"

namespace llvm { class Loop; class ScalarEvolution; }

namespace cq::loops::exits {

struct Unit {
  llvm::BasicBlock *cont = nullptr;                // C
  llvm::SmallVector<llvm::BasicBlock *, 4> arm;    // the exit arm, in a topological order
  llvm::SmallVector<llvm::BasicBlock *, 4> live;   // the live exit blocks
  llvm::SmallVector<llvm::BasicBlock *, 4> dead;   // the effect-free dead ends the loop exits into (never run)
  bool multi() const { return live.size() > 1; }
  bool contains(const llvm::Loop &L, const llvm::BasicBlock *b) const;
};

// The one block with an edge into a live exit block (nullptr when there are several), and the one
// live exit block (nullptr when there are several): LoopInfo's getExitingBlock / getExitBlock with the
// exits into effect-free dead ends set aside.
llvm::BasicBlock *liveExiting(const llvm::Loop &L);
llvm::BasicBlock *liveExit(const llvm::Loop &L);

// cq::unimplemented when the live exits have no common post-dominator that every path out of the
// loop reaches through blocks entered only from the loop, or when a dead-end exit has an effect.
Unit unitOf(const llvm::Loop &L);

// The cutoff bound B of a quantum-exit loop (CR rule 14): the least of loops::tripBound and, in
// a clone with `_b` bounds (CR §1.4: "a clone's loop cutoffs use only these bounds and its own range
// facts"; 190's memcmp `_b3`), the trip count's maximum over the bounded formals' ranges [0, b]. With
// several live exits a trip that ends in the body counts (the header-tested "minus one" applies only
// when every exit leaves from the header's test region).
std::optional<uint64_t> cutoffBound(const llvm::Loop &L, llvm::ScalarEvolution &SE, const TaintInfo &T,
                                    const Specialization &S);

} // namespace cq::loops::exits
