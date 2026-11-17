#!/usr/bin/env python3
"""A tree of symlinks to the CQ_spec references, usable as `cqcheck run --ours`: compares each reference
against its C program in our evaluator (plan §4; CQ_spec's README names this as the semantic check of
its bus examples). The file REFERENCE at the root makes `cqcheck run` verify them in reference mode.

    tools/ref_as_ours.py [DEST]     DEST default build/ref_as_ours; prints DEST
"""
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    spec = Path(os.environ.get("CQ_SPEC_DIR", ROOT / "spec")).resolve()
    dest = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "build" / "ref_as_ours"
    dest.mkdir(parents=True, exist_ok=True)
    (dest / "REFERENCE").write_text(str(spec) + "\n")
    for ex in sorted(p for p in (spec / "examples").iterdir() if p.is_dir()):
        refs = sorted(ex.glob("*.lowered.ll"))
        if len(refs) != 1:
            print(f"cq: {ex.name}: {len(refs)} lowered.ll", file=sys.stderr)
            return 1
        d = dest / ex.name
        d.mkdir(exist_ok=True)
        link = d / refs[0].name
        if link.is_symlink() or link.exists():
            link.unlink()
        link.symlink_to(refs[0])
    print(dest.resolve())
    return 0


if __name__ == "__main__":
    sys.exit(main())
