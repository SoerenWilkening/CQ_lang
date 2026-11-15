// Module loops-cutoff, private: the rule-14 loop unit as the spine's loop dispatch (spine/Construct.cpp)
// and loops-cutoff both see it. Not a frozen interface; its consumers are those two files.
//
// A loop dispatched as a unit (CR rule 14) ends where every path out of it meets again: its
// CONTINUATION C. An exit into a dead end that has no effect (every path from it ends in `unreachable`
// with no instruction that writes memory or calls: reaching it is undefined behaviour as LLVM defines
// it, outside the domain; 131's switch default) is no exit of the unit. With one live exit block, C is
// that block and the unit is the loop. With several (121, 190's memcmp: `n && *l == *r`), C is their
// nearest common post-dominator and the unit also holds the EXIT ARM: the blocks outside the loop
// between the live exits and C. The loop module lowers the exit arm with the loop (each trip's exit
// through it, rule 9 inside the trip) and binds every phi of C that has an incoming from the unit; on
// return the builder sits where C continues. Only an arm that keeps nothing runs per trip (121): a loop with a quantum exit
// whose arm holds a call or a write to memory has its exits met at one hub before the constructions (Plugin.cpp
// armOnceAfterTrips, cq-os2bx, rules 3 and 14), so that arm runs once after the loop. An arm block also entered from outside the loop starts the
// arm's TAIL (Unit::tail), which the walker lowers once more for those outside paths (cq-h8y6).
#pragma once

#include <cstdint>
#include <functional>
#include <optional>

#include "cq/Predicate.h"
#include "cq/Taint.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/BasicBlock.h"

namespace llvm { class Loop; class LoopInfo; class PHINode; class ScalarEvolution; class Value; class DominatorTree; class GlobalVariable; class Module; }
namespace cq { class LoweringContext; }
namespace cq::loops::rolled { class Region; }

namespace cq::loops::exits {

struct Unit {
  llvm::BasicBlock *cont = nullptr;                // C
  llvm::SmallVector<llvm::BasicBlock *, 4> arm;    // the exit arm, in a topological order
  llvm::SmallVector<llvm::BasicBlock *, 4> live;   // the live exit blocks
  llvm::SmallVector<llvm::BasicBlock *, 4> dead;   // the effect-free dead ends the loop exits into (never run)
  // The NORETURN ARMS (CR rule 14 "No live exit", rule 16): the blocks of the dead ends with an effect the
  // loop exits into (a noreturn call: abort, exit), in a topological order. The loop module lowers them
  // per trip under that trip's exit flag (rule 16's abort arm); the walker never runs them.
  llvm::SmallVector<llvm::BasicBlock *, 4> abort;
  // cq-h8y6 (CR rule 14 with rules 8, 9): the TAIL, the arm blocks also entered from outside the unit (an arm
  // block with a predecessor outside the loop and the arm, and every arm block it reaches), in the arm's order.
  // The loop module lowers them per trip like the rest of the arm, for the unit's paths only (an edge from
  // outside is no edge of a trip); the walker lowers them once more for the paths that enter them from outside,
  // under those paths' predicate (tailPred), and joins C's phis with them (rule 9: the unit's value where it
  // ran, the outside path's where it ran).
  llvm::SmallVector<llvm::BasicBlock *, 4> tail;
  bool multi() const { return live.size() > 1; }
  bool contains(const llvm::Loop &L, const llvm::BasicBlock *b) const;
};

// The one block with an edge into a live exit block (nullptr when there are several), and the one
// live exit block (nullptr when there are several): LoopInfo's getExitingBlock / getExitBlock with the
// exits into effect-free dead ends set aside.
llvm::BasicBlock *liveExiting(const llvm::Loop &L);
llvm::BasicBlock *liveExit(const llvm::Loop &L);

// The condition under which p goes to its successor b, over p's own branch condition (rule 8 atoms for a br, rule 13
// case atoms for a switch, the address cases for a computed goto), and its classical part as a classical i1 at the
// builder (a quantum condition counts as true).
Pred tripEdge(const llvm::BasicBlock *p, const llvm::BasicBlock *b);
llvm::Value *classicalEdge(cq::LoweringContext &ctx, const llvm::BasicBlock *p, const llvm::BasicBlock *b);

// Is the header phi h, bound, the continuation phi of a loop that exits into its header (a loop right after a loop)?
bool boundByLoopBefore(cq::LoweringContext &ctx, const llvm::PHINode &h, const llvm::LoopInfo &LI);

// With no live exit, cont is nullptr: the program's continuation after the loop is unreachable (CR rule
// 14 "No live exit"). cq::unimplemented when the live exits have no common post-dominator.
Unit unitOf(const llvm::Loop &L);

// cq-h8y6: the predicate under which a tail block b of U (U.tail) is entered from outside the unit: over b's
// edges from outside the loop and the arm, the edge's predicate; over its forward edges from another tail
// block, that block's tail predicate & the edge's. The unit's own paths into b are not in it (they are the
// loop module's, under its trips' exit flags). DT is the original function's.
Pred tailPred(cq::LoweringContext &ctx, const llvm::Loop &L, const Unit &U, const llvm::BasicBlock *b,
              const llvm::DominatorTree &DT);

// CR rules 9, 14: does tail block u of U lie in the unit of a loop of the tail (the loop, or that loop's exit arm)? Its edge into C is
// that unit's, which selects its own exits over C's phi per trip: read as an edge at the walker's join it would give the values
// after the loop's last trip. Only an edge of the tail outside such a unit is a join arm.
bool inTailLoopUnit(const llvm::Loop &L, const Unit &U, const llvm::BasicBlock *u, const llvm::LoopInfo &LI);

// The cutoff bound B of a quantum-exit loop (CR rule 14): the least of loops::tripBound and, in
// a clone with `_b` bounds (CR §1.4: "a clone's loop cutoffs use only these bounds and its own range
// facts"; 190's memcmp `_b3`), the trip count's maximum over the bounded formals' ranges [0, b]. With
// several live exits a trip that ends in the body counts (the header-tested "minus one" applies only
// when every exit leaves from the header's test region).
std::optional<uint64_t> cutoffBound(const llvm::Loop &L, llvm::ScalarEvolution &SE, const TaintInfo &T,
                                    const Specialization &S);

// CR rule 14 (`nested K-loops ... inner chain seeded by the outer trip predicate`): a quantum-exit loop L
// nested in a classically bounded loop's trip (loops-classical), lowered as loops-cutoff lowers a nested
// K-loop: its K trips unrolled at the builder under `seed` (an i1 rail: the enclosing trip's predicate & L's
// header predicate within the trip), its a_K kept per enclosing trip when B > K or no bound is known, every
// other rail a record of the current Uncompute scope. A classical branch of a trip is a real branch (rule 8,
// cq-kk46l): `segHook` is called with each block it makes (Run, Skip, Join) before code goes into it, with the
// builder still at the end of the code before it, so that the caller opens a segment there. Binds every phi of
// its continuation that has an incoming from the unit (cq::LoweringContext::addJoinArm for an incoming not
// lowered yet) and rebinds its values read after it; the builder is left where the last branch joined.
// Returns the XOR of the flags of the noreturn arms it took (a rail, nullptr when none or no K-loop encloses L).
// test0 (owner ruling Q10, CR rule 14 and rule 8): a classical i1, the classical factor of the predicate of entering L
// that the caller's walk does not establish (a classical conjunct of the pre-header guard, the trip-0 test), or nullptr:
// a real branch on it before trip 0, closed with the unit's own exit tests; where it is false no trip is emitted.
// Owner ruling Q2 of 2026-11-14 (cq-9kcq; CR 1.4 "Received K", rule 27 "Cutoff"): `@__cq_k = internal global i32 -1`, the
// received K of the table clone running (all ones: no cut). Compiler state like @__cq_act_<fn>: plain loads and stores, no
// bus access. Made on first need, in a module that defines a table clone; calls::finalize has every table clone, its _ctl
// form and their twins store their K actual on entry and the value found back at every return.
llvm::GlobalVariable *receivedKGlobal(llvm::Module &M);
// Owner ruling Q2: in a clone or own symbol (not a table clone) that a table clone of its module reaches by name, the K a
// cut of it uses in place of K: select(@__cq_k == -1, K, @__cq_k) (owner 2026-11-15: the received K replaces the own
// one, smaller or larger), @__cq_k loaded once in the entry block of the function lowered;
// nullptr in any other function (it cuts at K). For its K-loops, its quantum-depth recursion, and the K it passes on
// (an indirect call's, a declared clone's).
llvm::Value *receivedKBelow(cq::LoweringContext &ctx, unsigned K);

// cq-9kcq S11 (CQ_K_ROLLED): `region` is the classically bounded loop's rolled region (loops-classical's Unit) whose trip
// holds L; under the switch L rolls inside it (its header and trip blocks segments of that region, its a_K copy kept per
// enclosing trip), else it keeps its K static copies.
llvm::Value *lowerNestedCutoff(cq::LoweringContext &ctx, llvm::Loop &L, llvm::Value *seed,
                               const std::function<void(llvm::BasicBlock *)> &segHook, llvm::Value *test0 = nullptr,
                               cq::loops::rolled::Region *region = nullptr);

// CR rule 14 (case 1 or 3 inside a quantum-exit loop's trip, cq-h5uj): a classically bounded loop L of one
// unrolled trip of a K-loop (a sub-loop of its body or a loop of its exit arm), lowered by loops-classical
// as a rolled classical loop at the builder's position, its effects under `trip` (an i1 rail: the K-loop's
// trip predicate & L's header predicate within the trip; a case-3 chain seeded by it). The caller branches
// around it on the trip's classical path to L's header. Its reverse is an Uncompute deferred item guarded
// by "L's exit was passed", placed after the readers of its exit values, which are read in place (a value
// that is no rail of its own is copied by a record the reverse undoes first). Rebinds the values of L read
// after it (and, for a multi-exit case-3 loop, binds its continuation's phis); the builder is left where
// L's exit continues.
// Returns the XOR of the flags of the noreturn arms of L's nest (hasNoreturnArm; nullptr when none), an exit rail: an edge
// into such an arm is an exit edge of the K-loop too (CR rules 14, 16).
llvm::Value *lowerClassicalInTrip(cq::LoweringContext &ctx, llvm::Loop &L, llvm::Value *trip);

// Has L, a loop inside L, or a loop of L's exit arm a noreturn arm?
bool hasNoreturnArm(const llvm::Loop &L);

// CR rule 6's rolled-loop clause: is the initial value of the carried phi p a rail this function made for itself that
// nothing reads once the loop is entered (the rail trip 0 cleans)?
bool initDead(cq::LoweringContext &ctx, llvm::Loop &L, const llvm::Value *init, const llvm::PHINode *p);

} // namespace cq::loops::exits
