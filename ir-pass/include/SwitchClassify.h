// SwitchClassify.h — the §0 prove-or-decline ladder for a tainted-condition
// `switch` (swap-route 4.5 WI-1; PRD Part V §§19-22; IMPLEMENTATION-4.5 §3).
//
// `classifySwitchRegion` runs the ordered G0-G11 ladder over the WHOLE switch —
// all cases, the merge, the default — BEFORE any mutation (Rule 9), mirroring how
// `classifySelectRegion` (4.4) generalized the blanket `select` decline. It
// replaces the blanket `diagnoseUnderControl(SI, "switch")` at the SwitchInst arm
// of `detectControlRegions`'s terminator dispatch.
//
// HISTORY: WI-1 shipped this ladder with the emit STUBBED (a proven accept fired
// `diagnoseUnderControl(SI, "switch")` and pushed nothing); WI-2/3/4 added the
// per-class emitters and flipped each accept. Today an accept pushes its region
// (`plan.Regions.push_back` in SwitchClassify.cpp). A real decline fires its
// precise per-shape string.
//
// Pure SSA/CFG analysis — NO IR is mutated. Fires at most one loud diagnostic;
// a decline is loud, so never silent, but each is a gap to close (R1), not a
// safe margin.

#ifndef CQ_IRPASS_SWITCH_CLASSIFY_H_
#define CQ_IRPASS_SWITCH_CLASSIFY_H_

namespace llvm {
class SwitchInst;
}  // namespace llvm

namespace cq {

struct ControlRegion;

struct TaintSet;
struct ControlPlan;

// bd test_C_libtooling-3qlq Inc 1 part B — P5, the register-free PHASE SWITCH
// pre-peel. It runs BEFORE `classifySwitchRegion` because the register-free shape
// has NO merge φ, so that ladder's G1 (`soleSwitchMergePhi`) refuses it outright
// and declines generically — MEASURED at part A's HEAD. On ACCEPT `Region` is a
// `SwitchRegion` with `SwitchCls == Phase` and `Merge == nullptr` (that null IS
// the marker of the register-free shape) for `emitSwitchPhaseRegion`; on
// NotApplicable the caller runs the ordinary G0-G11 ladder, which still owns the
// VALUE and DATA-MUX classes. See the definition's header for the unitary and
// for why P5 has no plain-C customer.
enum class SwitchPhaseKickbackDisp { Accept, Declined, NotApplicable };
SwitchPhaseKickbackDisp classifyPhaseKickbackSwitch(llvm::SwitchInst *SI,
                                                    TaintSet &Taint,
                                                    ControlRegion &Region);

void classifySwitchRegion(llvm::SwitchInst *SI, TaintSet &taint,
                          ControlPlan &plan);

}  // namespace cq

#endif  // CQ_IRPASS_SWITCH_CLASSIFY_H_
