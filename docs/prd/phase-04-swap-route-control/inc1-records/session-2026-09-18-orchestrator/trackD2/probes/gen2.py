import os, sys
WT = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ad7349188dd3b67bd"
sys.path.insert(0, WT + "/tools")
import loop_twin_matrix as M

OUT = os.path.dirname(os.path.abspath(__file__)) + "/tgt"
os.makedirs(OUT, exist_ok=True)

# Target-stream donors: the ACCEPTING opaque-threshold siblings of the row-W cells,
# plus the row-W cells themselves for the subject comparison.
CELLS = ["m_none_oeq_none_none_none", "m_none_one_none_none_none",
         "m_none_oder_ry_none_none", "m_none_oeq_none_none_rzpost",
         "m_none_req_none_none_none", "m_none_rne_none_none_none",
         "m_none_rder_none_none_none", "m_none_req0_none_none_none",
         "m_none_rrange_none_none_none"]
for n in CELLS:
    prefix, region, suffix, record, rgate = n.split("_")[1:]
    rolled, unrolled = M.sources(prefix, region, suffix, record, rgate, surface="void")
    open(os.path.join(OUT, n + ".rolled.c"), "w").write(rolled)
    open(os.path.join(OUT, n + ".unrolled.c"), "w").write(unrolled)
print("wrote", OUT)
for n in ("m_none_oeq_none_none_none",):
    prefix, region, suffix, record, rgate = n.split("_")[1:]
    print("---", n, "ROLLED ---")
    print(M.sources(prefix, region, suffix, record, rgate, surface="void")[0])
