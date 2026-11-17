#!/usr/bin/env python3
"""What the lowered float library needs from a backend: every cq_template_* and cqrt_* that the archives
leave undefined (llvm-nm), grouped by operation and width.

    python3 softfloat/tools/backend_needs.py [ARCHIVE...]   (default build/libqsoftfloat.a, build/libqsoftfloat_f80.a)
"""
import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

SF = Path(__file__).resolve().parent.parent
NM = "/usr/local/opt/llvm@19/bin/llvm-nm"
W = r"(?:i\d+|f16|bf16|f32|f64|f80)"


def main():
    libs = sys.argv[1:] or [str(SF / "build" / "libqsoftfloat.a"), str(SF / "build" / "libqsoftfloat_f80.a")]
    defined, undef = set(), set()
    for lib in libs:
        for line in subprocess.run([NM, "-g", lib], capture_output=True, text=True, check=True).stdout.splitlines():
            parts = line.split()
            if len(parts) < 2:
                continue
            sym = parts[-1].lstrip("_") if parts[-1].startswith("_c") else parts[-1][1:]
            if not re.match(r"(cq_template_|cqrt_)", sym):
                continue
            (undef if parts[-2] == "U" else defined).add(sym)
    need = sorted(undef - defined)
    groups = defaultdict(set)
    for s in need:
        base = s[:-4] if s.endswith("_unc") else s
        m = re.match(rf"(cq_template_|cqrt_)([a-z_0-9]+?)_({W})(?:_to_({W}))?((?:_[hlq]+)?(?:_rmq?)?(?:_exc)?)$", base)
        if not m:
            groups[(base, "")].add("")
            continue
        pfx, op, w, w2, rest = m.groups()
        groups[(pfx + op + (rest or ""), "")].add(w + (f"->{w2}" if w2 else ""))
    print(f"{len(need)} symbols ({sum(1 for s in need if s.startswith('cqrt_'))} cqrt_*, "
          f"{sum(1 for s in need if s.startswith('cq_template_'))} cq_template_*, _unc forms included) "
          f"undefined in {', '.join(Path(l).name for l in libs)}:")
    fw = re.compile(r"(^|->)(f16|bf16|f32|f64|f80)")
    for (k, _), ws in sorted(groups.items()):
        ws = sorted(ws, key=lambda x: (len(x), x))
        flag = "  [float width]" if any(fw.search(x) for x in ws) else ""
        print(f"  {k}: {' '.join(ws)}{flag}")


if __name__ == "__main__":
    main()
