// OpcodeSupport.h — Hand-written supported-set + opcode classification
// for the cq-lowering pass (PRD §2.1). This is the policy layer that
// decides *what is in scope* and *how an operand/predicate canonicalizes*;
// `TemplateName` then spells the symbol and `WidthDispatch` mints the
// decl. Keeping the supported-set hand-authored (not generated) is a
// deliberate PRD §2.1 decision: a ~20-line classifier is the authority
// the pass mirrors, and the per-symbol LIT fixtures + the link against the
// generated runtime header guard against drift.
//
// Phase 3 surface (forward only):
//   * binary  : add sub mul sdiv udiv srem urem  (int_arith)
//               and or xor shl lshr ashr          (int_bitwise)
//               fadd fsub fmul fdiv frem          (fp_arith)
//   * unary   : fneg
//   * compare : icmp (10 preds) / fcmp (6 ordered preds), flag handle
//   * cast    : sext zext trunc fpext fptrunc sitofp uitofp fptosi fptoui
//
// Widths: int {i1,i8,i16,i32,i64}, fp {f32,f64}.

#ifndef CQ_IRPASS_OPCODE_SUPPORT_H_
#define CQ_IRPASS_OPCODE_SUPPORT_H_

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/InstrTypes.h"

namespace llvm {
class Instruction;
class Type;
}  // namespace llvm

namespace cq {

// LLVM binary opcode → its template stem ("add"/"sub"/"fadd"/"shl"/…),
// restricted to the in-scope set. Returns "" for any opcode outside the
// surface (the caller then emits the loud "no template" diagnostic). The
// stem is exactly `Instruction::getOpcodeName()` for the in-scope opcodes;
// the intersection with the supported set is what this function adds.
llvm::StringRef binaryStem(unsigned opcode);

// Commutative binary opcodes: {add mul and or xor fadd fmul} (PRD §2.4).
// Drives operand canonicalization — a commutative op moves a literal to
// the RHS (`_hl`); a non-commutative op preserves operand order and uses
// `_hl` (literal right) or `_lh` (literal left). Also gates the Q+Q
// BirthOrder swap (on for commutative, off otherwise).
bool isCommutative(unsigned opcode);

// Predicate flip for a literal-on-left compare (PRD §2.4): slt↔sgt,
// sle↔sge, ult↔ugt, ule↔uge, olt↔ogt, ole↔oge; eq/ne/oeq/une self-map.
// Lets a `5 < x` compare reuse the `_hl` template with the operands
// swapped — there are no `_lh` compare templates. Any predicate without a
// defined flip (the (un)ordered fp predicates out of Phase-3 scope) maps
// to itself.
llvm::CmpInst::Predicate flipPredicate(llvm::CmpInst::Predicate pred);

// Whether a cast `op` over the `(fromW, toW)` ABI-width pair is in the
// Phase-3 cast surface (the 68 yaml pairs). Encodes the structural rule
// the yaml enumerates: int widen (sext/zext, strictly wider), int narrow
// (trunc, strictly narrower), fp widen/narrow (fpext/fptrunc), and the
// four int↔fp domain crossings (sitofp/fptosi exclude i1 — no signed
// bool; uitofp/fptoui include i1). `op` is the cast opcode name.
bool castInScope(llvm::StringRef op, llvm::StringRef fromW,
                 llvm::StringRef toW);

// Whether a compare `op` ("icmp"/"fcmp") with predicate-name `pred` is in the
// Phase-3 compare surface. `pred` is `CmpInst::getPredicateName(...)` (e.g.
// "eq"/"slt"/"oeq"/"une"). Mirrors the YAML `predicates:` map
// (tools/opcode_table.yaml): `icmp` ships ALL 10 LLVM integer predicates;
// `fcmp` ships only {oeq, une, olt, ogt, ole, oge} (the 5 ordered relationals
// Clang emits for C float `< > <= >=` plus `une` for `!=`). An out-of-scope
// fcmp predicate (`one`/`ord`/`uno`/`ueq`/unordered `u*`/`true`/`false`) has NO
// generated template — keyed on `op` because icmp and fcmp share predicate-name
// strings (`ugt`/`uge`/`ult`/`ule`). Width is gated separately by
// `abiWidthFromType`; this is the PREDICATE axis only. Without this gate
// `WidthDispatch::compareTemplateFn` would `getOrInsertFunction` a non-existent
// `cq_template_fcmp_<pred>_<W>_hl` symbol (verify-clean, link-fails at Stage 3;
// test_C_libtooling-jvun).
bool compareInScope(llvm::StringRef op, llvm::StringRef pred);

// A value's LLVM type → its ABI-width string ("i1"/…/"i64"/"f32"/"f64").
// Returns "" for an unsupported width (`half`, `i128`, `fp128`, vectors);
// the caller then diagnoses. Integer widths are restricted to the 5
// supported {1,8,16,32,64}. Moved here from `OpcodeLowering` so every
// instruction-class lowerer shares one width-resolution policy.
llvm::StringRef abiWidthFromType(llvm::Type *ty);

// "No template for opcode" diagnostic, generalized from the original
// `BinaryOperator`-only helper to any `Instruction*`. Same
// `DiagnosticInfoUnsupported(DS_Error)` surface the rest of the pass uses;
// the message is `"no template for opcode '<detail>' in tainted context"`
// where `detail` is a caller-supplied "<opcode> <type>" string a LIT
// fixture can FileCheck. If `detail` is empty the helper derives a
// reasonable "<opcodeName> <type>" description from the instruction.
void diagnoseNoTemplate(llvm::Instruction *inst, llvm::StringRef detail = {});

}  // namespace cq

#endif  // CQ_IRPASS_OPCODE_SUPPORT_H_
