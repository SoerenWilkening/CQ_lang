#!/usr/bin/env python3
"""report.py: write the tier-1 passthrough report (cq-w1-kernel-t1) into this directory.

tus.tsv: one line per TU (tus.py) with its check result (check1.sh):
    object, source, opt level, state, verdict, sha256 of the bitcode, target triple, detail
summary.txt: release, commit, config, toolchain, the pass (CQ_lang2 commit, plugin sha256), counts.
A TU with no result, or one older than its object, is reported as "unchecked".
"""
import collections, hashlib, os, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

def env():
    out = subprocess.run(["bash", "-c", f"set -a; . '{HERE}/env.sh'; env"], capture_output=True, text=True,
                         check=True).stdout
    return dict(l.split("=", 1) for l in out.splitlines() if "=" in l)

def main():
    e = env()
    os.environ.update({k: e[k] for k in ("KOUT", "KTREE", "KSRC")})
    import tus
    kout, chk = Path(e["KOUT"]), Path(e["CHK"])
    rows, counts, verdicts, olevels, triples = [], collections.Counter(), collections.Counter(), \
        collections.Counter(), collections.Counter()
    for obj, src, ol, state in tus.tus():
        verdict = sha = triple = detail = ""
        if state == "bitcode":
            r = chk / "res" / obj.replace("/", "%")
            if r.exists() and r.stat().st_mtime >= (kout / obj).stat().st_mtime:
                _, verdict, sha, triple, detail = r.read_text().rstrip("\n").split("\t")
            else:
                verdict = "unchecked"
            verdicts[verdict] += 1; olevels[ol] += 1; triples[triple] += 1
        counts[state] += 1
        rows.append((obj, src, ol, state, verdict, sha, triple, detail))
    with open(HERE / "tus.tsv", "w") as f:
        f.write("object\tsource\topt\tstate\tverdict\tsha256\ttriple\tdetail\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    root = HERE.parents[1]
    commit = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"], capture_output=True,
                            text=True).stdout.strip()
    plugin = Path(e["PLUGIN"])
    psha = hashlib.sha256(plugin.read_bytes()).hexdigest() if plugin.exists() else "missing"
    kver = subprocess.run(["git", "-C", e["KTREE"], "rev-parse", "HEAD"], capture_output=True,
                          text=True).stdout.strip()
    lines = [
        "CQ_lang2 kernel tier 1 (passthrough), bead cq-w1-kernel-t1",
        f"linux release     {e['KREL']} ({e['KREPO']})",
        f"linux commit      {kver}",
        f"config            {e['KCONFIG']} (ARCH=x86_64 LLVM=1, KCFLAGS=-O1, kcc adds -emit-llvm)",
        "toolchain         brew llvm@19 19.1.7 (clang, opt), lld@19 19.1.7",
        f"pass              CQ_lang2 {commit} (the checkout's HEAD when the report was written)",
        f"plugin sha256     {psha}",
        "identity          opt -passes=cq-lower X  ==  opt X   (byte for byte, bitcode output; owner",
        "                  ruling on cq-arch 2026-10-27; control.sh shows the comparison sees a rewrite)",
        "scope             every C file kbuild compiles to an object for `vmlinux modules` of the config,",
        "                  outside scripts/ (host programs). Not reached: arch/x86/boot and",
        "                  boot/compressed (bzImage needs a linked vmlinux) and the files modpost generates",
        "                  (*.mod.c, .vmlinux.export.c; modpost reads ELF). Opt level: KCFLAGS=-O1, except",
        "                  where the kernel's Makefiles set their own later (listed under opt level).",
        "",
        f"TUs               {len(rows)}",
    ]
    lines += [f"  {k:<16}{v}" for k, v in sorted(counts.items())]
    lines += ["bitcode TUs by verdict"] + [f"  {k:<16}{v}" for k, v in sorted(verdicts.items())]
    lines += ["bitcode TUs by opt level"] + [f"  {k or '(none)':<16}{v}" for k, v in sorted(olevels.items())]
    lines += ["bitcode TUs by triple"] + [f"  {k or '(none)':<28}{v}" for k, v in sorted(triples.items())]
    (HERE / "summary.txt").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))
    bad = [r for r in rows if r[3] != "bitcode" or r[4] != "identical"]
    for r in bad:
        print("NOT IDENTICAL/NOT REBUILT:", "\t".join(r[:5]), r[7][:200])
    return 1 if bad else 0

if __name__ == "__main__":
    sys.exit(main())
