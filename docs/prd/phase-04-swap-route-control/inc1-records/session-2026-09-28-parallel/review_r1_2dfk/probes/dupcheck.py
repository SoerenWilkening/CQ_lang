#!/usr/bin/env python3
"""r1 2dfk: independently re-check the 6 removed lit fixtures were EXACT duplicates.
View 1 = every line not starting with ';' (the module). View 2 = every line that
carries a lit directive (RUN/XFAIL/REQUIRES/UNSUPPORTED or any `<PREFIX>[-X]:`),
with the file's own basename normalised. Also: kept file base vs subject differ
only in ';' comment lines."""
import re, subprocess, sys
W = sys.argv[1]
BASE, SUBJ = "d21a59b0", "12c91627"
pairs = [
 ("control_angle_select_reject_cond_alias.ll", "control_angle_select_reject_cond_register.ll"),
 ("control_inplace_ry_reject_stale_diag_alias_backward.ll", "control_inplace_ry_reject_stale_diag_alias_forward.ll"),
 ("control_predmux_reject_selectform_rotation_hop_chained.ll", "control_predmux_reject_selectform_rotation_poison_arg.ll"),
 ("control_swap_diamond_derived.ll", "control_swap_diamond.ll"),
 ("control_swap_reject_nested_inner_clobber.ll", "control_swap_reject_nested_value_mixed.ll"),
 ("spec_overaccept_probe_callbr_visible.ll", "spec_reject_callbr.ll"),
]
def show(rev, f):
    return subprocess.run(["git", "-C", W, "show", f"{rev}:ir-pass/test/{f}"],
                          capture_output=True, text=True, check=True).stdout
DIR = re.compile(r"^\s*;.*\b(RUN|XFAIL|REQUIRES|UNSUPPORTED|[A-Z0-9_-]+(-NOT|-NEXT|-SAME|-DAG|-LABEL|-COUNT-\d+|-EMPTY)?):")
def views(txt, name):
    mod = [l for l in txt.splitlines() if not l.lstrip().startswith(";")]
    dirs = [l.replace(name[:-3], "@SELF@") for l in txt.splitlines()
            if l.lstrip().startswith(";") and DIR.match(l)]
    return mod, dirs
bad = 0
for rem, kept in pairs:
    r, kb, ks = show(BASE, rem), show(BASE, kept), show(SUBJ, kept)
    mr, dr = views(r, rem); mk, dk = views(kb, kept); mks, dks = views(ks, kept)
    same_mod, same_dir = mr == mk, dr == dk
    kept_ok = (mk == mks) and (dk == dks)
    # prefixes named on RUN lines
    pref = sorted(set(re.findall(r"--check-prefix(?:es)?[= ]([\w,-]+)", r)))
    print(f"{rem}\n   module-identical={same_mod} ({len(mr)} lines)  directives-identical={same_dir} ({len(dr)} lines)  kept-unchanged-outside-comments={kept_ok}  prefixes={pref}")
    if not (same_mod and same_dir and kept_ok): bad += 1
    if not same_dir:
        import difflib
        for x in difflib.unified_diff(dr, dk, lineterm=""): print("     ", x)
    # does the subject still carry the removed file's non-directive comment lines?
    rc = [l for l in r.splitlines() if l.lstrip().startswith(";") and not DIR.match(l) and l.strip(" ;")]
    missing = [l for l in rc if l.strip(" ;") not in ks]
    print(f"   removed-file prose lines={len(rc)}  not found verbatim in kept(subject)={len(missing)}")
    for l in missing[:5]: print("      MISSING:", l)
print("BAD", bad)
