import os, sys
WT = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ad7349188dd3b67bd"
sys.path.insert(0, WT + "/tools")
import loop_twin_matrix as M

OUT = os.path.dirname(os.path.abspath(__file__)) + "/rz"
os.makedirs(OUT, exist_ok=True)

CELLS = ["m_rz_eq_rz", "m_rz_eq0_rz", "m_rz_gt_rz",
         "m_rz_eq_none", "m_none_eq_rz", "m_none_eq_none"]
for n in CELLS:
    prefix, region, suffix = n.split("_")[1:]
    rolled, unrolled = M.sources(prefix, region, suffix, surface="void")
    open(os.path.join(OUT, n + ".rolled.c"), "w").write(rolled)
    open(os.path.join(OUT, n + ".unrolled.c"), "w").write(unrolled)
print("wrote", len(CELLS) * 2, "files to", OUT)
for n in ("m_rz_eq_rz",):
    prefix, region, suffix = n.split("_")[1:]
    r, u = M.sources(prefix, region, suffix, surface="void")
    print("=" * 30, n, "ROLLED", "=" * 30)
    print(r)
    print("=" * 30, n, "UNROLLED", "=" * 30)
    print(u)
