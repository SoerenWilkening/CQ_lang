#!/usr/bin/env python3
"""bd ffm0 (2dfk round 2) — meta-mutation of e2e-stage-cache-selftest.

Deletes EACH cache-key component, one at a time, from BOTH spellings where both
exist (tests/e2e/stage_cache.sh and tools/cq_stage_cache.py) — so the key-PARITY
row cannot catch it by construction — and requires the selftest to go RED. Every
mutant is checked as PLANTED (each `old` must occur exactly once; a substitution
that matches nothing is a null mutant and is reported as NOT PLANTED, never as
caught). The files are restored from saved bytes after every mutant, and their
sha-256 is checked at the end. Row 0 is the NULL CONTROL (no edit): it must stay
green.

usage: meta_mut_r2.py <worktree> <selftest command...>
"""
import hashlib
import os
import subprocess
import sys

W = sys.argv[1]
CMD = sys.argv[2:]
SC = os.path.join(W, "tests/e2e/stage_cache.sh")
PY = os.path.join(W, "tools/cq_stage_cache.py")

B = SC
P = PY
MUTANTS = [
    ("null", []),
    # ── bash stage-1 key ──
    ("s1_hd_b", [(B, '"$CQ_HD" "$CQ_S1_BASE" "$CQ_CLANG_ID" "$CQ_ENVD" "$#"',
                     '"X" "$CQ_S1_BASE" "$CQ_CLANG_ID" "$CQ_ENVD" "$#"')]),
    ("s1_base_b", [(B, '"$CQ_HD" "$CQ_S1_BASE" "$CQ_CLANG_ID" "$CQ_ENVD" "$#"',
                       '"$CQ_HD" "X" "$CQ_CLANG_ID" "$CQ_ENVD" "$#"')]),
    ("s1_clang_b", [(B, '"$CQ_HD" "$CQ_S1_BASE" "$CQ_CLANG_ID" "$CQ_ENVD" "$#"',
                        '"$CQ_HD" "$CQ_S1_BASE" "X" "$CQ_ENVD" "$#"')]),
    ("s1_env_b", [(B, '"$CQ_HD" "$CQ_S1_BASE" "$CQ_CLANG_ID" "$CQ_ENVD" "$#"',
                      '"$CQ_HD" "$CQ_S1_BASE" "$CQ_CLANG_ID" "X" "$#"')]),
    ("s1_flags_b", [(B, '"$CQ_HD" "$CQ_S1_BASE" "$CQ_CLANG_ID" "$CQ_ENVD" "$#"',
                        '"$CQ_HD" "$CQ_S1_BASE" "$CQ_CLANG_ID" "$CQ_ENVD" 0'),
                    (B, "                 printf '%s\\0' \"$@\"\n", "")]),
    ("s1_path_b", [(B, "printf 'src\\0%s\\0%s\\0' \"$src\" \"$sd\"",
                       "printf 'src\\0%s\\0%s\\0' \"X\" \"$sd\"")]),
    ("s1_bytes_b", [(B, "printf 'src\\0%s\\0%s\\0' \"$src\" \"$sd\"",
                        "printf 'src\\0%s\\0%s\\0' \"$src\" \"X\"")]),
    ("s1_hdr_b", [(B, "printf 'hdr\\0%s\\0' \"$hdrd\"", "printf 'hdr\\0%s\\0' \"X\"")]),
    # ── python stage-1 key ──
    ("s1_hd_p", [(P, 'fields = [S1_VERSION + "-" + kind, harness_digest(), _env("CQ_S1_BASE"), cid,',
                     'fields = [S1_VERSION + "-" + kind, "X", _env("CQ_S1_BASE"), cid,')]),
    ("s1_base_p", [(P, 'fields = [S1_VERSION + "-" + kind, harness_digest(), _env("CQ_S1_BASE"), cid,',
                       'fields = [S1_VERSION + "-" + kind, harness_digest(), "X", cid,')]),
    ("s1_clang_p", [(P, 'fields = [S1_VERSION + "-" + kind, harness_digest(), _env("CQ_S1_BASE"), cid,',
                        'fields = [S1_VERSION + "-" + kind, harness_digest(), _env("CQ_S1_BASE"), "X",')]),
    ("s1_env_p", [(P, '              env_digest()]\n    fields += counted("flags", list(flags))',
                      '              "X"]\n    fields += counted("flags", list(flags))')]),
    ("s1_flags_p", [(P, 'fields += counted("flags", list(flags))', 'fields += counted("flags", [])')]),
    ("s1_path_p", [(P, 'fields += ["src", src_path, src_digest]', 'fields += ["src", "X", src_digest]')]),
    ("s1_hdr_p", [(P, 'fields += ["hdr", header_digest(flags)]', 'fields += ["hdr", "X"]')]),
    ("s1_bytes_p", [(P, 'fields += ["src", src_path, src_digest]', 'fields += ["src", src_path, "X"]')]),
    # ── run key, BOTH spellings ──
    ("run_hd", [(B, '"$CQ_HD" "$CQ_RUN_BASE" "$CQ_CLANG_ID" "${#CQ_S3_CC_FLAGS[@]}"',
                    '"X" "$CQ_RUN_BASE" "$CQ_CLANG_ID" "${#CQ_S3_CC_FLAGS[@]}"'),
                (P, 'fields = [RUN_VERSION, hd, run_base, cid]', 'fields = [RUN_VERSION, "X", run_base, cid]')]),
    ("run_base", [(B, '"$CQ_HD" "$CQ_RUN_BASE" "$CQ_CLANG_ID" "${#CQ_S3_CC_FLAGS[@]}"',
                      '"$CQ_HD" "X" "$CQ_CLANG_ID" "${#CQ_S3_CC_FLAGS[@]}"'),
                  (P, 'fields = [RUN_VERSION, hd, run_base, cid]', 'fields = [RUN_VERSION, hd, "X", cid]')]),
    ("run_clang", [(B, '"$CQ_HD" "$CQ_RUN_BASE" "$CQ_CLANG_ID" "${#CQ_S3_CC_FLAGS[@]}"',
                       '"$CQ_HD" "$CQ_RUN_BASE" "X" "${#CQ_S3_CC_FLAGS[@]}"'),
                   (P, 'fields = [RUN_VERSION, hd, run_base, cid]', 'fields = [RUN_VERSION, hd, run_base, "X"]')]),
    ("run_s3", [(B, '"$CQ_HD" "$CQ_RUN_BASE" "$CQ_CLANG_ID" "${#CQ_S3_CC_FLAGS[@]}"',
                    '"$CQ_HD" "$CQ_RUN_BASE" "$CQ_CLANG_ID" 0'),
                (B, "                    printf '%s\\0' \"${CQ_S3_CC_FLAGS[@]}\"\n", ""),
                (P, 'fields += counted("s3cc", list(s3_flags))', 'fields += counted("s3cc", [])')]),
    ("run_s2d", [(B, '"$s2d" "$tpld" "$rtd" "$ldd" "$CQ_ENVD" 0', '"X" "$tpld" "$rtd" "$ldd" "$CQ_ENVD" 0'),
                 (P, 'fields += [s2_digest, tpl_digest, rt_digest, ld_digest, envd]',
                     'fields += ["X", tpl_digest, rt_digest, ld_digest, envd]')]),
    ("run_tpl", [(B, '"$s2d" "$tpld" "$rtd" "$ldd" "$CQ_ENVD" 0', '"$s2d" "X" "$rtd" "$ldd" "$CQ_ENVD" 0'),
                 (P, 'fields += [s2_digest, tpl_digest, rt_digest, ld_digest, envd]',
                     'fields += [s2_digest, "X", rt_digest, ld_digest, envd]')]),
    ("run_rt", [(B, '"$s2d" "$tpld" "$rtd" "$ldd" "$CQ_ENVD" 0', '"$s2d" "$tpld" "X" "$ldd" "$CQ_ENVD" 0'),
                (P, 'fields += [s2_digest, tpl_digest, rt_digest, ld_digest, envd]',
                    'fields += [s2_digest, tpl_digest, "X", ld_digest, envd]')]),
    ("run_ld", [(B, '"$s2d" "$tpld" "$rtd" "$ldd" "$CQ_ENVD" 0', '"$s2d" "$tpld" "$rtd" "X" "$CQ_ENVD" 0'),
                (P, 'fields += [s2_digest, tpl_digest, rt_digest, ld_digest, envd]',
                    'fields += [s2_digest, tpl_digest, rt_digest, "X", envd]')]),
    ("run_env", [(B, '"$s2d" "$tpld" "$rtd" "$ldd" "$CQ_ENVD" 0', '"$s2d" "$tpld" "$rtd" "$ldd" "X" 0'),
                 (P, 'fields += [s2_digest, tpl_digest, rt_digest, ld_digest, envd]',
                     'fields += [s2_digest, tpl_digest, rt_digest, ld_digest, "X"]')]),
    ("run_argv_p", [(P, 'fields += counted("argc", list(argv))', 'fields += counted("argc", [])')]),
    # ── bash 2b key ──
    ("pb2_hd", [(B, '"$CQ_HD" "$CQ_ENVD" "$s2d" "$fpd" "$2" "$PY"', '"X" "$CQ_ENVD" "$s2d" "$fpd" "$2" "$PY"')]),
    ("pb2_env", [(B, '"$CQ_HD" "$CQ_ENVD" "$s2d" "$fpd" "$2" "$PY"', '"$CQ_HD" "X" "$s2d" "$fpd" "$2" "$PY"')]),
    ("pb2_s2d", [(B, '"$CQ_HD" "$CQ_ENVD" "$s2d" "$fpd" "$2" "$PY"', '"$CQ_HD" "$CQ_ENVD" "X" "$fpd" "$2" "$PY"')]),
    ("pb2_fpd", [(B, '"$CQ_HD" "$CQ_ENVD" "$s2d" "$fpd" "$2" "$PY"', '"$CQ_HD" "$CQ_ENVD" "$s2d" "X" "$2" "$PY"')]),
    ("pb2_flags", [(B, '"$CQ_HD" "$CQ_ENVD" "$s2d" "$fpd" "$2" "$PY"', '"$CQ_HD" "$CQ_ENVD" "$s2d" "$fpd" "X" "$PY"')]),
    ("pb2_py", [(B, '"$CQ_HD" "$CQ_ENVD" "$s2d" "$fpd" "$2" "$PY"', '"$CQ_HD" "$CQ_ENVD" "$s2d" "$fpd" "$2" "X"')]),
    # ── harness digest composition, BOTH spellings ──
    ("hd_run_slice", [(B, '"$d1" "$d2" "$d3" "$d4" | _cq_sha)', '"X" "$d2" "$d3" "$d4" | _cq_sha)'),
                      (P, '    ("run_slice.sh", os.path.join(E2E, "run_slice.sh")),\n', '')]),
    ("hd_multi", [(B, '"$d1" "$d2" "$d3" "$d4" | _cq_sha)', '"$d1" "X" "$d3" "$d4" | _cq_sha)'),
                  (P, '    ("run_slice_multi.sh", os.path.join(E2E, "run_slice_multi.sh")),\n', '')]),
    ("hd_stage_cache", [(B, '"$d1" "$d2" "$d3" "$d4" | _cq_sha)', '"$d1" "$d2" "X" "$d4" | _cq_sha)'),
                        (P, '    ("stage_cache.sh", os.path.join(E2E, "stage_cache.sh")),\n', '')]),
    ("hd_py", [(B, '"$d1" "$d2" "$d3" "$d4" | _cq_sha)', '"$d1" "$d2" "$d3" "X" | _cq_sha)'),
               (P, '    ("cq_stage_cache.py", os.path.join(HERE, "cq_stage_cache.py")),\n', '')]),
    # ── the CR guard of the ModuleID normalisation ──
    ("cr_b", [(B, "        *$'\\r'*)          s2d=$(_cq_sha < \"$TMP/s2.ll\") ;;\n", "")]),
    ("cr_p", [(P, '        if b"\\r" not in first:', '        if True:')]),
]

# META_ONLY=a,b,c runs only those mutants (the null control always runs).
_only = {x for x in os.environ.get("META_ONLY", "").split(",") if x}
if _only:
    MUTANTS = [m for m in MUTANTS if m[0] == "null" or m[0] in _only]

orig = {f: open(f, "rb").read() for f in (SC, PY)}
sha0 = {f: hashlib.sha256(b).hexdigest() for f, b in orig.items()}
caught = missed = notplanted = 0
try:
    for name, edits in MUTANTS:
        texts = {f: orig[f].decode() for f in orig}
        ok = True
        for f, old, new in edits:
            if texts[f].count(old) != 1:
                print("%-16s NOT PLANTED (%d occurrence(s) of %r in %s)"
                      % (name, texts[f].count(old), old[:50], os.path.basename(f)))
                ok = False
                break
            texts[f] = texts[f].replace(old, new, 1)
        if not ok:
            notplanted += 1
            continue
        for f in orig:
            with open(f, "w") as fh:
                fh.write(texts[f])
        if name != "null" and all(texts[f].encode() == orig[f] for f in orig):
            print("%-16s NOT PLANTED (no byte changed)" % name)
            notplanted += 1
            continue
        r = subprocess.run(CMD, capture_output=True, text=True)
        fails = [l.strip()[6:62] for l in r.stdout.splitlines() if l.startswith("  FAIL")]
        if name == "null":
            verdict = "green (NULL CONTROL, expected)" if r.returncode == 0 else "RED — THE CONTROL FAILED"
        elif r.returncode != 0:
            verdict = "CAUGHT"
            caught += 1
        else:
            verdict = "MISSED"
            missed += 1
        print("%-16s rc=%d %-8s %s" % (name, r.returncode, verdict, "; ".join(fails[:3])))
        for f in orig:
            with open(f, "wb") as fh:
                fh.write(orig[f])
finally:
    for f in orig:
        with open(f, "wb") as fh:
            fh.write(orig[f])
restored = all(hashlib.sha256(open(f, "rb").read()).hexdigest() == sha0[f] for f in orig)
print("meta_mut_r2: %d mutant(s): %d CAUGHT, %d MISSED, %d NOT PLANTED; files restored: %s"
      % (len(MUTANTS) - 1, caught, missed, notplanted, restored))
sys.exit(0 if missed == 0 and notplanted == 0 and restored else 1)
