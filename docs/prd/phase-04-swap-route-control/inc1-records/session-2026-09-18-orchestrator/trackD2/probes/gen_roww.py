import os, sys
WT = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ad7349188dd3b67bd"
sys.path.insert(0, WT + "/tools")
import loop_twin_matrix as M

OUT = os.path.dirname(os.path.abspath(__file__)) + "/rowW"
os.makedirs(OUT, exist_ok=True)

CELLS = """m_none_rder_none_none_addpost
m_none_rder_none_none_none
m_none_rder_none_none_rypost
m_none_rder_none_none_rypre
m_none_rder_none_none_rzpost
m_none_req0_none_none_none
m_none_req0_none_none_rypost
m_none_req_none_none_addpost
m_none_req_none_none_none
m_none_req_none_none_rypost
m_none_req_none_none_rypre
m_none_req_none_none_rzpost
m_none_rne_none_none_none
m_none_rne_none_none_rypost
m_none_rrange_none_none_none
m_none_rrange_none_none_rypost
m_none_ablphi_none_none_binv""".split()

for n in CELLS:
    toks = n.split("_")[1:]
    prefix, region, suffix, record, rgate = toks
    rolled, unrolled = M.sources(prefix, region, suffix, record, rgate, surface="void")
    open(os.path.join(OUT, n + ".rolled.c"), "w").write(rolled)
    open(os.path.join(OUT, n + ".unrolled.c"), "w").write(unrolled)
print("wrote", len(CELLS) * 2, "files to", OUT)
print("--- m_none_req_none_none_none ROLLED ---")
print(M.sources("none", "req", "none", "none", "none")[0])
print("--- m_none_req_none_none_none UNROLLED ---")
print(M.sources("none", "req", "none", "none", "none")[1])
print("--- m_none_ablphi_none_none_binv ROLLED ---")
print(M.sources("none", "ablphi", "none", "none", "binv", surface="void")[0])
