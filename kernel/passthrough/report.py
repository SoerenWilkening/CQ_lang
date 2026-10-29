#!/usr/bin/env python3
"""report.py: write the tier-1 passthrough report (cq-w1-kernel-t1) into this directory.

tus.tsv: one line per TU (tus.py) with its check result (check1.sh):
    object, source, opt level, state, verdict, sha256 of the bitcode, target triple, plugin sha256, detail
summary.txt: release, commit, config, toolchain, the pass (plugin path, sha256, its checkout's HEAD), counts.
A TU with no result is "unchecked"; one whose result is older than its object, names another bitcode
hash or another plugin hash than the current $PLUGIN's, or has an old format, is "stale".
Exit 0 iff there is at least one TU and every TU is bitcode with verdict identical under the current
plugin. REPORT_DIR (default: this directory) is where tus.tsv and summary.txt are written.
    report.py --pending   print the bitcode TUs with no current result (check.sh's work list) and exit
"""
import collections, hashlib, os, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

def env():
    out = subprocess.run(["bash", "-c", f"set -a; . '{HERE}/env.sh'; env"], capture_output=True, text=True,
                         check=True).stdout
    return dict(l.split("=", 1) for l in out.splitlines() if "=" in l)

def sha256(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()

def result(chk, kout, obj, psha, full):
    """(verdict, sha, triple, plugin sha, detail) of obj's check1.sh result. verdict is "unchecked" with
    no result, "stale" when the result does not belong to the current object and plugin: older than the
    object, another plugin hash, an old format, or (full) another bitcode hash."""
    r = chk / "res" / obj.replace("/", "%")
    if not r.exists():
        return ("unchecked", "", "", "", "")
    f = r.read_text().rstrip("\n").split("\t")
    if len(f) != 6:
        return ("stale", "", "", "", "result has the old format (no plugin hash)")
    _, verdict, sha, triple, rpsha, detail = f
    why = ("result older than the object" if r.stat().st_mtime < (kout / obj).stat().st_mtime else
           f"result from plugin {rpsha[:12]}, current {psha[:12]}" if rpsha != psha else
           "bitcode hash changed" if full and sha != sha256(kout / obj) else "")
    return ("stale", sha, triple, rpsha, why) if why else (verdict, sha, triple, rpsha, detail)

def setup():
    e = env()
    os.environ.update({k: e[k] for k in ("KOUT", "KTREE", "KSRC")})
    plugin = Path(e["PLUGIN"])
    psha = sha256(plugin) if plugin.exists() else "missing"
    return e, Path(e["KOUT"]), Path(e["CHK"]), plugin, psha

def pending():
    e, kout, chk, plugin, psha = setup()
    import tus
    ts = tus.tus()
    if not ts:
        print(f"report: no TUs found under {kout}", file=sys.stderr)
        return 1
    for obj, src, ol, state in ts:
        if state == "bitcode" and result(chk, kout, obj, psha, False)[0] in ("unchecked", "stale"):
            print(obj)
    return 0

def main():
    e, kout, chk, plugin, psha = setup()
    out = Path(os.environ.get("REPORT_DIR", HERE))
    import tus
    rows, counts, verdicts, olevels, triples = [], collections.Counter(), collections.Counter(), \
        collections.Counter(), collections.Counter()
    for obj, src, ol, state in tus.tus():
        verdict = sha = triple = rpsha = detail = ""
        if state == "bitcode":
            verdict, sha, triple, rpsha, detail = result(chk, kout, obj, psha, True)
            verdicts[verdict] += 1; olevels[ol] += 1; triples[triple] += 1
        counts[state] += 1
        rows.append((obj, src, ol, state, verdict, sha, triple, rpsha, detail))
    with open(out / "tus.tsv", "w") as f:
        f.write("object\tsource\topt\tstate\tverdict\tsha256\ttriple\tplugin_sha256\tdetail\n")
        for r in rows:
            f.write("\t".join(r) + "\n")
    # the pass is the plugin: a snap.sh copy names its origin; otherwise PLUGIN is <checkout>/build/pass/X
    origin = Path(str(plugin) + ".origin")
    if origin.exists():
        o = dict(l.split(None, 1) for l in origin.read_text().splitlines() if l.strip())
        passline = [f"pass              CQ_lang2 {o['commit']}", f"plugin origin     snap.sh copy of {o['source']} (mtime {o['mtime']})"]
    else:
        root = plugin.resolve().parents[2] if plugin.exists() else HERE.parents[1]
        commit = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"], capture_output=True,
                                text=True).stdout.strip() or "unknown"
        passline = [f"pass              CQ_lang2 {commit} (HEAD of the plugin's checkout when the report was written)"]
    kver = subprocess.run(["git", "-C", e["KTREE"], "rev-parse", "HEAD"], capture_output=True,
                          text=True).stdout.strip()
    lines = [
        "CQ_lang2 kernel tier 1 (passthrough), bead cq-w1-kernel-t1",
        f"linux release     {e['KREL']} ({e['KREPO']})",
        f"linux commit      {kver}",
        f"config            {e['KCONFIG']} (ARCH=x86_64 LLVM=1, KCFLAGS=-O1, kcc adds -emit-llvm)",
        "toolchain         brew llvm@19 19.1.7 (clang, opt), lld@19 19.1.7",
        f"plugin            {plugin}",
        f"plugin sha256     {psha} (every verdict below is a result recorded under this hash)",
        *passline,
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
    if not rows:
        print(f"report: FAILED, no TUs found under {kout}", file=sys.stderr)
        return 1
    bad = [r for r in rows if r[3] != "bitcode" or r[4] != "identical"]
    for r in bad:
        print("NOT IDENTICAL/NOT CHECKED:", "\t".join(r[:5]), r[8][:200], file=sys.stderr)
    if bad:
        print(f"report: FAILED, {len(bad)} of {len(rows)} TUs not identical under plugin {psha}",
              file=sys.stderr)
    return 1 if bad else 0

if __name__ == "__main__":
    sys.exit(pending() if sys.argv[1:] == ["--pending"] else main())
