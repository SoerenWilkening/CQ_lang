#!/usr/bin/env python3
"""comment_only_check.py REV [files...] — prove a change is COMMENTS ONLY: for
each C/C++/lit file changed between REV and the working tree, strip comments
(C/C++: // and /* */ outside string literals; .ll: lines starting with ';')
from both versions, collapse whitespace, and compare. Prints one line per file
and exits 1 if any file's non-comment text changed. Its own null/positive
controls run first (a comment edit must pass, a code edit must fail)."""
import os, re, subprocess, sys

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2"


def strip_c(src):
    out, i, n = [], 0, len(src)
    while i < n:
        if src.startswith("//", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
            out.append(" ")
        elif src[i] in "\"'":
            q, j = src[i], i + 1
            while j < n and src[j] != q:
                j += 2 if src[j] == "\\" else 1
            out.append(src[i:j + 1])
            i = j + 1
        else:
            out.append(src[i])
            i += 1
    return " ".join("".join(out).split())


def strip_ll(src):
    keep = [l for l in src.splitlines() if not l.lstrip().startswith(";")]
    return " ".join(" ".join(keep).split())


def strip_cmake(src):
    keep = [l.split("#", 1)[0] for l in src.splitlines()]
    return " ".join(" ".join(keep).split())


def stripper(path):
    if path.endswith((".cpp", ".h", ".c", ".cc")):
        return strip_c
    if path.endswith(".ll"):
        return strip_ll
    if path.endswith(("CMakeLists.txt", ".cmake")):
        return strip_cmake
    return None


def controls():
    a = "int f(){ return 1; } // old\n"
    assert strip_c(a) == strip_c("int f(){ return 1; } /* new comment */\n"), "null control failed"
    assert strip_c(a) != strip_c("int f(){ return 2; } // old\n"), "positive control failed"
    assert strip_ll("; a\nret\n") == strip_ll("; b\nret\n") and strip_ll("ret 1") != strip_ll("ret 2")


def main():
    controls()
    rev = sys.argv[1]
    files = sys.argv[2:] or subprocess.run(
        ["git", "-C", W, "diff", "--name-only", rev], capture_output=True, text=True).stdout.split()
    bad = 0
    for f in files:
        st = stripper(f)
        if st is None:
            print(f"  (not code)  {f}")
            continue
        old = subprocess.run(["git", "-C", W, "show", f"{rev}:{f}"], capture_output=True, text=True).stdout
        new = open(os.path.join(W, f)).read()
        same = st(old) == st(new)
        bad += not same
        print(f"  {'comment-only' if same else 'CODE CHANGED'}  {f}")
    print(f"comment_only_check vs {rev}: {len(files)} file(s), {bad} with code changes (controls passed)")
    return 1 if bad else 0


sys.exit(main())
