// MergeArmWrite.h — THE ARM WRITE of a controlled-XOR merge (bd
// test_C_libtooling-dm7f.81; owner ruling
// ruling-dm7f81-constant-arm-xorc-imm-fp-and-runtime-2026-10-15).
//
// Every Phase-4 value merge (the 4.4 select, the 6.5 classical-call arm, the
// 4.5 switch data-mux deltas, the 7.6 IOSink value mux, the 7.4 break
// index/escape captures) writes its fresh |0> out rail as
//     out ^= flag ? arm : 0
// once per arm. Before dm7f.81 a CLASSICAL arm (a constant or a runtime
// classical value) was first loaded into its own rail, `cqrt_alloc_<W>(v)`,
// only to be the source of `cqrt_copy_<W>_controlled(flag, src, out)`, and that
// rail was never freed (32 qubits per `i32` constant arm; dicke.c's `2*q4`
// spent 64). A classical value is a classical operand (R13), so the write is
//   * a QUANTUM arm (a tainted handle): `cqrt_copy_<W>_controlled(f, arm, out)`;
//   * a classical arm whose bit pattern is all zero (`Constant::isNullValue`:
//     integer 0, fp +0.0 — never -0.0): NOTHING, XOR with 0 is the identity.
//     An `undef`/`poison` arm is refined to that pattern (LangRef-legal) and
//     emits nothing too: as a literal, the merge-discharge replay's clone would
//     make it a second slot read as a second value (LiteralIntegrity.h guard 1);
//   * any other classical arm: `cqrt_xorc_<W>_controlled(f, out, arm)`, the arm
//     a literal (or classical SSA) operand — never a rail, never tainted.
// Bennett.jl @824458d builds the same circuit: a constant operand is NOT gates
// on its set bits (src/lowering/operand.jl:31-41), and under a control each NOT
// becomes a CNOT from the control (src/controlled.jl:162-164). BennettVM.jl
// @23d28e6 keeps a select arm a literal (src/ir/select_instruction.jl:72-77).
//
// bd r2j3.14 (L1) carries over by SUBJECT: a classical answer is a round-1
// answer, so every write whose immediate is not a Constant is RECORDED and its
// slot 2 re-asked at final taint by `declineQuantumCopySources`
// (SelectMergeEmit.h) with the unchanged diagnostic.

#ifndef CQ_IRPASS_MERGE_ARM_WRITE_H_
#define CQ_IRPASS_MERGE_ARM_WRITE_H_

#include "llvm/IR/IRBuilder.h"

namespace llvm {
class CallInst;
class DebugLoc;
class Value;
}  // namespace llvm

namespace cq {

class ControlledSymbols;
struct TaintSet;

// Does the arm write of `Arm` emit no gate (a classical all-zero arm)?
bool armWriteIsNoop(llvm::Value *Arm, const TaintSet &taint);

// Emit `Out ^= Flag ? Arm : 0` before `B`'s insert point, as above. `CopyC` is
// the merge's controlled-copy minter, `XorcC` its controlled xor-immediate
// minter at the same width (the caller checks both non-null). Returns the
// emitted gate, or null when the write is a no-op.
llvm::CallInst *emitArmWrite(llvm::IRBuilder<> &B, llvm::Value *Flag,
                             llvm::Value *Arm, llvm::Value *Out,
                             llvm::FunctionCallee CopyC,
                             llvm::FunctionCallee XorcC, const TaintSet &taint,
                             const llvm::DebugLoc &DL);

// The two-arm mux `Out = Flag ? True : False` into a |0> `Out`: the TRUE write
// on the flag, then — only when the FALSE write emits a gate — the X-bracketed
// FALSE write on ¬flag. The bracket encloses ONLY that write (the §16.3
// bracket-order hazard: a bracket around both writes is the same multiset and
// the wrong %out).
void emitArmMux(llvm::IRBuilder<> &B, ControlledSymbols &csyms,
                llvm::Value *Flag, llvm::Value *True, llvm::Value *False,
                llvm::Value *Out, llvm::FunctionCallee CopyC,
                llvm::FunctionCallee XorcC, const TaintSet &taint,
                const llvm::DebugLoc &DL);

// Drop whichever of the two write declarations an emitter minted (to ask the
// fence) but never called — e.g. no copy declaration when every arm is classical
// (R11 round 1 C-F1: a stray `declare @cqrt_copy_<W>_controlled` let a bare
// `CHECK: cqrt_copy_…_controlled(` match nothing real). Only an unused
// DECLARATION is erased; the callees must not be used by the caller afterwards.
void eraseUnusedArmDecls(llvm::FunctionCallee CopyC, llvm::FunctionCallee XorcC);

}  // namespace cq

#endif  // CQ_IRPASS_MERGE_ARM_WRITE_H_
