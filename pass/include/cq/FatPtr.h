// Frozen interface (cq-arch). Changes only under cq-arch's freeze rule.
#pragma once

#include "cq/Lowering.h"
#include "cq/Taint.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Instructions.h"

// FatPtr.h  (rule 21)
namespace cq::fatptr {
struct FatPtr { llvm::Value *tag; bool tagQuantum; llvm::Value *idx; bool idxQuantum;
                llvm::SmallVector<ObjectId, 4> objects; };
struct Triple { llvm::Value *object, *tag, *idx, *cellCount; };
FatPtr lower(LoweringContext &, const llvm::Value *ptr);
void lowerLoad(LoweringContext &, llvm::LoadInst &);
void lowerStore(LoweringContext &, llvm::StoreInst &);
llvm::Value *lowerCompare(LoweringContext &, llvm::ICmpInst &);
void lowerPtrToInt(LoweringContext &, llvm::Instruction &);
void lowerIntToPtr(LoweringContext &, llvm::Instruction &);
Triple passAcrossCall(LoweringContext &, const llvm::Value *ptr);
// P1 (cq-arch 2026-11-01, CR rule 21, §1.4; 190, 191): at a clone's entry, pointer formal `formal` (T4 abi
// Triple or TripleCount) is bound to the clone's parameters object (ptr, or the i32 bus of a Qram pointee),
// tag, idx (handles iff their mask digits are 1) and cellCount (nullptr unless TripleCount). lower() of the
// formal and of every pointer derived from it then yields the bound fat pointer; a Slot-pointee load is
// checked against cellCount and reads the clone's shared |0> seed beyond it (190). Consumer: spine
// Construct clone entry.
void bindFormal(LoweringContext &, const llvm::Argument &formal, llvm::Value *object, Operand tag, Operand idx,
                llvm::Value *cellCount);
// R1 (cq-r7-91, CR rules 14, 20, 21; 91): TRIP OBJECTS. A K-loop's exit phi P whose loop incoming is an
// allocation site of the loop (one object per (site, trip), rule 14) and whose other incomings are the null
// pointer on edges that skip the loop is the fat pointer (tag, idx 0) over null and the trip objects. The loop
// module reserves one tag per trip (reserveTripTags: n fresh tags past every root number and earlier
// reservation), mints the tag rail and binds P with bindTripPointer, giving per trip object the handles of the
// cells read after the loop as they are at the end of its trip. Through P: an eq/ne compare is a tag compare
// (distinct allocations; each trip object is dereferenced in its trip, so non-null in the domain); a load at a
// classical constant cell is the captured handles merged by select on tag == k (null dropped: a load through
// null is undefined). Anything else through P is unimplemented.
struct TripCell { int64_t byte; llvm::Type *ty; Operand h; };
struct TripObject { unsigned tag; llvm::SmallVector<TripCell, 2> cells; };
// R2 (cq-z6q1, CR rules 14, 21; 189): a K-loop's quantum pointer header phi P is CARRIED as its tag alone:
// the loop binds P (one operand, its i32 tag rail, rebound each trip) after registerCarried(P), which
// checks that every incoming of P is at the start of its objects (idx the classical 0). derive of P is
// then (the bound tag, idx 0) over the roots of its incomings. carriedTag: the tag of a value the loop
// carries into P (its start, its next value), checked to be at idx 0.
void registerCarried(LoweringContext &, const llvm::PHINode &P);
Operand carriedTag(LoweringContext &, const llvm::Value *ptr);
unsigned reserveTripTags(LoweringContext &, unsigned n);
unsigned rootTag(LoweringContext &, const llvm::Value *root);   // a root's number (internal error otherwise)
void bindTripPointer(LoweringContext &, const llvm::PHINode &P, Operand tag, llvm::ArrayRef<TripObject>);
}
