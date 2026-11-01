// Module rot-qangle (cq-w1-rot-qangle): quantum rotation angles, CR rules 11 and 15.
//
//   Rule 11: "An angle that depends on quantum data in any way (a select or phi on a quantum flag, a
//   switch over a quantum scrutinee, a table read at a quantum index, arithmetic on a register) is
//   computed into an f64 rail by ordinary templates (select_f64[_ll|_hl|_lh], qrom_load_f64,
//   arithmetic) and consumed by rule 15's single primitive. The compiler never expands it into
//   per-arm controlled rotations; the ladder is the backend's."  Witnesses: 132, 141, 142.
//   Rule 15: "An angle derived from a register is computed into an f64 rail by ordinary templates and
//   consumed by one primitive: ry_<W>_qangle[_controlled]([c,] h, A) for cq_theta,
//   rz_qangle[_controlled]([c,] A) for cq_phi. The angle rail is uncomputed afterwards. The backend
//   supplies the N-bit ladder."  Witnesses: 79, 143.
//
// The angle rail A is the operand the spine already bound to the cq_theta/cq_phi angle: the select,
// phi, switch, QROM load or arithmetic that computed it was lowered by its own construction (rules 4,
// 9, 13, 20). This module emits only the one primitive that reads A. A is a control of that
// primitive (an IR user of its handle), so the spine's LIFO uncompute resolves it after its last
// consumer (132 shared_angle_select: one rail read by two primitives, uncomputed once after both).
//
// cq_theta(v, A)
//  - v a rail: in place (rule 2). v classical: a register alloc_<W>(v), a seed (79 theta, 132).
//  - No quantum predicate in scope: ry_<W>_qangle(h, A). The rail is rotated: a user register (38),
//    and the rotation is a non-diagonal gate on it (A4: garbage that read it before stays allocated).
//  - Under a quantum predicate (flag c): ry_<W>_qangle_controlled(c, h, A) in place on a rail, which is
//    frozen: rule 10's in-place case with a quantum angle, lowered by rot-cry's lowerControlledTheta
//    (cq-t3rd) so the register bookkeeping is the classical angle's: a register the rail holds is
//    locked and dirty where the rotation runs, and a later prep of it stops loudly instead of writing
//    xorc/Ry onto the rotated state. An in-place target is never one of its own controls (CR §1.3,
//    rot-cry's controlledRy: a flag that IS the target is read into a fresh i1 rail, kept by A4; two
//    slot-cell loads that may be one cell are tested, cq-x80e). A prep of a CLASSICAL value under a
//    quantum predicate is rule
//    10's register (the merge phi names one rail with the straight-through value; a second prep undoes
//    the first): with a quantum angle that is not built yet and is an internal error here.
//  - The target being the angle rail itself (cq_theta_f64(x, x)) is not built yet.
//
// cq_phi(A)
//  - e^{i val(A)} depends on the registers A was computed from: a RELATIVE phase, never deletable as a
//    global one (rule 12 applies to classical angles only). No quantum predicate in scope:
//    rz_qangle(A), a phase on A's branches that A's uncompute kicks back onto its sources (79, 132).
//    Under a quantum predicate: rz_qangle_controlled(c, A) (79's `if (x > k)`, 185). No NOT-rail
//    identity (rz(-θ) plus a global phase) is used: with a quantum θ the leftover is relative (79).
//  - In a _pure clone (CR §1.4: the clone without its phase effects) nothing is emitted, as for a
//    classical angle.
#include "cq/Rotation.h"

#include "cq/Abi.h"
#include "cq/Uncompute.h"
#include "llvm/IR/Constants.h"

using namespace llvm;

namespace cq::rot {

namespace {

// The angle operand: the f64 rail the spine bound to it. A classical angle never reaches this module.
Value *angleRail(LoweringContext &ctx, CallInst &call, const Value *angle) {
  if (!angle->getType()->isDoubleTy())
    internalError("rot-qangle: a rotation angle that is not a double", &call);
  Operand a = ctx.operand(angle);
  if (!a.handle)
    internalError("rot-qangle: a quantum angle whose operand is not a rail (rules 11, 15)", &call);
  return a.v;
}

} // namespace

void lowerQuantumAngleTheta(LoweringContext &ctx, CallInst &call, Value *flag) {
  if (call.arg_size() != 2)
    internalError("rot-qangle: cq_theta with other than two arguments", &call);
  const Value *v = call.getArgOperand(0);
  Value *A = angleRail(ctx, call, call.getArgOperand(1));
  RailType w = railTypeOf(v->getType());
  Operand x = ctx.operand(v);
  if (flag && x.handle)
    return lowerControlledTheta(ctx, call, flag);   // rule 10 in place, quantum angle (cq-t3rd)
  Value *h;
  if (x.handle) {
    h = x.v;   // rule 2: a rotation of an existing rail is in place
    if (h == A)
      unimplemented("rot-qangle: cq_theta of a rail by its own value as the angle (target among the controls)", &call);
  } else {
    if (flag)
      unimplemented("rot-qangle: a prep of a classical value under a quantum predicate with a quantum angle "
                    "(rule 10's register with rule 15's primitive)", &call);
    if (x.v->getType() != irTypeOf(ctx.M.getContext(), w))
      internalError("rot-qangle: cq_theta operand type differs from its rail type", &call);
    CallInst *alloc = ctx.emitCore(abi::CoreSpec{abi::Core::Alloc, w}, {x.v});
    ctx.unc().recordSeed(alloc);
    h = alloc;
  }
  CallInst *ry = ctx.emitCore(abi::CoreSpec{abi::Core::RyQAngle, w}, {h, A});
  RailId id = ctx.unc().idOf(h);
  ctx.unc().noteNonDiagonal(id, ry);
  ctx.unc().setRole(id, Role::UserRegister);
  ctx.bind(&call, h);
}

void lowerQuantumAnglePhase(LoweringContext &ctx, CallInst &call, Value *flag) {
  if (call.arg_size() != 1)
    internalError("rot-qangle: cq_phi with other than one argument", &call);
  Value *A = angleRail(ctx, call, call.getArgOperand(0));
  if (ctx.S.pure)
    return;   // a _pure clone is the clone without its phase effects (CR §1.4)
  RailType none{};   // rz_qangle carries no width
  if (flag)
    ctx.emitCore(abi::CoreSpec{abi::Core::RzQAngle, none, /*ctl=*/true}, {flag, A});
  else
    ctx.emitCore(abi::CoreSpec{abi::Core::RzQAngle, none}, {A});
}

} // namespace cq::rot
