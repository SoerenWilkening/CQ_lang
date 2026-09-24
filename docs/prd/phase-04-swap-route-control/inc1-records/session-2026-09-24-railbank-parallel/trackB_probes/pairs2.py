#!/usr/bin/env python3
import pathlib
SP = pathlib.Path(__file__).parent
T = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a784cc15f4136a8dc/tools/railbank_twin_pairs")
P = SP / "probes2"
PAIRS = {
  "p13_inloop_xor_park": ("P1_bank", "Rule-13 round-2 F-1 (bd xdu2.1): q parked, then a ROLLED in-place `q ^= 3`\n   loop (kickback on q > k), then the cells measured. Must DECLINE like its twin."),
  "p14_inloop_xor_park_other_cond": ("P1_bank_ry", "F-1 with the relabel loop conditioned on a DIFFERENT register r."),
  "p15_inloop_xor_const_trip": ("r_qxk3_bank", "F-1 with a constant (3) trip count and a trip-dependent immediate (q ^= k)."),
}
for name, (stem, claim) in PAIRS.items():
    b = (P / f"{stem}.bank.c").read_text()
    r = (P / f"{stem}.reg.c").read_text()
    (T / f"{name}.bank.c").write_text(f"/* {claim} */\n#include \"CQ.h\"\n" + b)
    (T / f"{name}.reg.c").write_text(f"/* the ARRAY-FREE twin of {name[:3]}. */\n#include \"CQ.h\"\n" + r)
print("ok")
