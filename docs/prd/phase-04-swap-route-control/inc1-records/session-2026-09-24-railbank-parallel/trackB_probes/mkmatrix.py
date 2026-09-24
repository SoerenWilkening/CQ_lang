#!/usr/bin/env python3
"""Assemble tests/e2e/railbank_stale_matrix.c + .cases.json from the probes."""
import json, pathlib

SP = pathlib.Path(__file__).parent
WT = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a784cc15f4136a8dc")
F3D8Q = "cq opcode lowering: rotation/measure operand predates a non-diagonal gate"
MIX = "cq rail bank: array mixes a rail cell access with an unrecognized one"
MUXPHI = "cq taint escape: tainted value muxed by a classical-condition phi"

# (id, macro, probe stem, accept, diagnostic, one-line claim)
ROWS = [
    (1, "FIXED_STALE_INVARIANT_PARK", "s01_fixed_parkloop_ry_measloop.bank", False, F3D8Q,
     "bd xdu2.1's own program (review F-1): invariant rail parked, relabelled by Ry, cells measured after"),
    (2, "RUNTIME_STALE_INVARIANT_PARK", "s02_rt_parkloop_ry_measloop.bank", False, F3D8Q,
     "row 1 on the xdu2.4 runtime-sized int b[n] bank (the isArrayAllocation branch of the hop)"),
    (3, "FIXED_STALE_CONSTIDX_READ", "s03_fixed_parkloop_ry_constidx.bank", False, MIX,
     "row 1 read by a constant-index cq_measure(b[1]) -- declines at the carve, before the fence"),
    (4, "RUNTIME_STALE_CONSTIDX_READ", "s04_rt_parkloop_ry_constidx.bank", False, MIX,
     "row 3 on a runtime-sized bank"),
    (5, "FIXED_STALE_THETA_ARG0", "s09_fixed_theta_arg0_stale.bank", False, MIX,
     "a cq_theta arg-0 read of the stale parked rail (constant index)"),
    (6, "RUNTIME_STALE_THETA_ARG0_LOOP", "s10_rt_theta_arg0_stale_loop.bank", False,
     "cq rail bank: unsupported reader of a rail-bank cell",
     "a cq_theta arg-0 read of the stale parked rail in a loop -- D5 refuses the reader"),
    (7, "FIXED_RY_INSIDE_MEASURE_LOOP", "s14_fixed_ry_inside_measloop.bank", False, MUXPHI,
     "relabel INSIDE the measure loop: trip 2 onward reads a stale name"),
    (8, "RUNTIME_PARK_CARRIED_PHI", "s16_rt_park_carried_phi.bank", False, MUXPHI,
     "the parked value is the loop-carried q, rotated after each park in the same loop"),
    (9, "BOOL_STALE_INVARIANT_PARK", "s17_bool_stale.bank", False,
     "cq taint escape: tainted value consumed by an unknown callee",
     "row 1 at _Bool cells"),
    (10, "RUNTIME_STALE_BEFORE_PARK", "s18_rt_stale_before_park.bank", False, F3D8Q,
     "the rail is relabelled BEFORE it is parked (twin-gate row p05, runtime-sized)"),
    (11, "RUNTIME_DTZB_LOOP_XOR", "s26_rt_dtzb_runtime_loop_xor.bank", False, MUXPHI,
     "parked rail relabelled by a runtime-trip in-place xor loop, then the cells measured"),
    (12, "FIXED_SECOND_BANK_INVARIANT", "s30_fixed_two_banks_one_stale.bank", False, F3D8Q,
     "a per-cell-theta bank beside a stale invariant bank, one measure loop over both"),
    (13, "RUNTIME_CONDPREP_BESIDE_STALE", "h06_condprep_plus_invariant_stale.bank", False, F3D8Q,
     "the xdu2.4 conditional-prep (grover) bank beside a stale invariant bank"),
    (14, "RUNTIME_PASSH_THETA_ESCAPES", "h01_passH_t_escapes_relabelled.bank", False,
     "cq controlled lowering: condition predates a non-diagonal gate under quantum control",
     "PASS-H prep whose theta also escapes the loop and is relabelled after it"),
    (15, "RUNTIME_CONDPREP_THETA_ESCAPES", "h02_condprep_t_escapes_relabelled.bank", False,
     "cq controlled lowering: control flow under quantum control",
     "seed-path conditional prep whose arm theta escapes the loop and is relabelled"),
    (16, "RUNTIME_UNCOND_THETA_ESCAPES", "g03_uncond_escapes_relabelled.bank", False, F3D8Q,
     "per-cell theta that ALSO escapes the loop and is relabelled -- the in-loop-minted rail stale through its LCSSA name"),
    (17, "FIXED_STRAIGHT_LINE_PARK", "s05_fixed_straightpark_ry_measloop.bank", False,
     "cq taint escape: tainted value stored to memory",
     "straight-line park b[0]=b[1]=b[2]=q (no write loop): not a bank"),
    (20, "FIXED_LEGIT_ORDER", "s07_fixed_legit.bank", True, None,
     "GREEN: row 1 with the measure loop moved ABOVE the rotation (review f06)"),
    (21, "FIXED_LEGIT_ORDER_TWIN", "s07_fixed_legit.reg", True, None, "array-free twin of 20"),
    (22, "FIXED_PARKED_PARENT_ADD", "s13_fixed_dtzb_add_measure_first.bank", True, None,
     "GREEN: t = q + 3 after the park, cells read after -- must stay OUT of place"),
    (23, "FIXED_PARKED_PARENT_ADD_TWIN", "s13_fixed_dtzb_add_measure_first.reg", True, None,
     "array-free twin of 22"),
    (24, "FIXED_PHASE_BETWEEN", "s25_fixed_phi_between.bank", True, None,
     "GREEN: a register-free cq_phi (diagonal, deleted as a global phase) between park and read"),
    (25, "FIXED_PHASE_BETWEEN_TWIN", "s25_fixed_phi_between.reg", True, None, "array-free twin of 24"),
    (26, "RUNTIME_PARKED_PARENT_ADD_LOOP", "s27_rt_dtzb_runtime_loop_add_measfirst.bank", True, None,
     "GREEN: runtime bank, a runtime-trip add loop on the parked parent, measured first"),
    (27, "RUNTIME_PARKED_PARENT_ADD_LOOP_TWIN", "s27_rt_dtzb_runtime_loop_add_measfirst.reg", True, None,
     "array-free twin of 26"),
    (28, "RUNTIME_PERCELL_SIBLING_ROTATED", "s19_rt_sibling_register_rotated.bank", True, None,
     "GREEN: the capability plus an unrelated register rotated between the loops"),
    (29, "RUNTIME_PERCELL", "s20_rt_percell_theta.bank", True, None,
     "GREEN: the canonical runtime per-cell theta bank"),
    (30, "RUNTIME_CONDPREP_CONTROL", "h04_condprep_control.bank", True, None,
     "GREEN: the xdu2.4 seed-path conditional prep (store value = merge phi)"),
    (31, "RUNTIME_PASSH_CONTROL", "h05_passH_control.bank", True, None,
     "GREEN: the xdu2.4 PASS-H emptied-arm prep (store value = select)"),
    (32, "FIXED_BOOL_PERCELL", "s32_fixed_bool_percell.bank", True, None,
     "GREEN: the capability at _Bool cells -- the hop must peel the i1->i8 storage cast to find the seed"),
    (33, "RUNTIME_DTZB_FIXED_TRIP_XOR", "e1_bank_dtzb_loop_xor.bank", False, MUXPHI,
     "review round-1 probe e1_bank: fixed-trip (unroll disabled) in-place xor loop on the parked rail; held by tryCaseA's CLOSURE refusing the bank store"),
    (40, "TWIN_OF_28", "t28_rt_percell_sibling.twin", True, None, "hand-unrolled n=3 twin of 28"),
    (41, "TWIN_OF_29", "t29_rt_percell.twin", True, None, "hand-unrolled n=3 twin of 29"),
    (42, "TWIN_OF_31", "t31_passH.twin", True, None,
     "hand-unrolled n=3 twin of 31 (Z made quantum by an identity Ry(0), dropped before comparing)"),
    (43, "TWIN_OF_32", "t32_bool_percell.twin", True, None, "hand-unrolled twin of 32"),
]
TWINS = [(20, 21), (22, 23), (24, 25), (26, 27), (28, 40), (29, 41), (31, 42), (32, 43)]
DROPPED = {42: ["cqrt_ry_i32(h0, 0x0p+0)"]}

hdr = """/* railbank_stale_matrix.c — bd xdu2.1 (Track B, session 2026-09-24-railbank-parallel).
 *
 * C-level clang -O1 matrix for the stale-reader fence's MEMORY HOP
 * (`railBankParkedRails`, OpcodeLowering.cpp): a rail parked in a rail-bank cell
 * must be adjudicated exactly as its register spelling is.  Negative rows are
 * programs whose register spelling has no valid circuit (a parked name read
 * after a non-diagonal relabel) — every one must DECLINE; the diagnostic pinned
 * is the wall that fires TODAY, which for several rows is an earlier fence than
 * the reader fence (the row's comment says so).  Positive rows are the
 * capability and legitimate-order controls that a fix of this class must not
 * break; four are LINKED and byte-compared against their array-free twins.
 *
 * Expectations: railbank_stale_matrix.c.cases.json (schema at the top of
 * run_railbank_dynamic_matrix.py).  Probe provenance and re-measurement:
 * docs/prd/phase-04-swap-route-control/inc1-records/
 *   session-2026-09-24-railbank-parallel/TRACK_B.md.
 */
#include "CQ.h"
#include <stdlib.h>

"""
body = []
cases = {}
for cid, macro, stem, acc, diag, claim in ROWS:
    body.append(f"#define CASE_{macro} {cid}\n")
body.append("\n#ifndef CASE\n#define CASE CASE_FIXED_STALE_INVARIANT_PARK\n#endif\n\n")
first = True
for cid, macro, stem, acc, diag, claim in ROWS:
    src = (SP / "probes" / (stem + ".c")).read_text()
    src = src.replace("#include <stdlib.h>\n", "")
    kw = "#if" if first else "#elif"
    first = False
    body.append(f"{kw} CASE == CASE_{macro}\n/* {'ACCEPT' if acc else 'DECLINE'} — {claim}. */\n{src}\n")
    cases[str(cid)] = {"accept": acc, "diagnostic": diag}
body.append("#else\n#error unknown CASE\n#endif\n")
(WT / "tests/e2e/railbank_stale_matrix.c").write_text(hdr + "".join(body))
doc = {
    "_comment": "Expectations for railbank_stale_matrix.c (bd xdu2.1, Track B). "
                "Decline rows pin the wall that fires today; twin pairs are linked and byte-compared.",
    "cases": cases,
    "twins": [{"rolled": a, "twin": b, "argv": [], "dropped_twin_lines": DROPPED.get(b, [])} for a, b in TWINS],
}
(WT / "tests/e2e/railbank_stale_matrix.c.cases.json").write_text(json.dumps(doc, indent=2) + "\n")
print(len(ROWS), "rows")
