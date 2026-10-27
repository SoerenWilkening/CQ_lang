#!/usr/bin/env python3
"""Rewrite the local value names of hand-written examples/*/*.lowered.ll to LLVM's sequential numbering.

LLVM numbers unnamed locals per function in textual order: arguments, then each basic block (an unnamed
block takes a number) and each non-void instruction. Named values do not consume a number, so a scheme
such as "%1 / %q2 / %3" is not expressible; the corpus therefore uses plain numbering (owner, 2026-10-22).
This script drops every local name (values and block labels), renumbers, and keeps every comment and the
line structure of the file, which `opt -discard-value-names` would not.

    renumber_locals.py [--check] FILE.ll ...

With --check nothing is written: the script renumbers in memory and exits 1 if the result differs from the
stock renaming (`opt -S -discard-value-names -passes=verify`) once comments and blank lines are removed.
Without --check it rewrites each file in place and then runs the same equivalence check on the result.
"""
import re
import subprocess
import sys
from pathlib import Path

OPT = "/usr/local/opt/llvm@19/bin/opt"
LLVM_AS = "/usr/local/opt/llvm@19/bin/llvm-as"
NAME = r'(?:[-a-zA-Z$._][-a-zA-Z$._0-9]*|[0-9]+|"[^"]*")'
LOCAL_RE = re.compile(r"%(" + NAME + ")")
DEF_RE = re.compile(r"^\s*%(" + NAME + r")\s*=")
LABEL_RE = re.compile(r"^(" + NAME + r"):(.*)$")
DEFINE_RE = re.compile(r"^define\b.*\{\s*(;.*)?$")


def split_comment(line):
    """Return (code, comment) splitting at the first ';' outside a string literal."""
    in_str = False
    i = 0
    while i < len(line):
        c = line[i]
        if c == '"':
            in_str = not in_str
        elif c == "\\" and in_str:
            i += 1
        elif c == ";" and not in_str:
            return line[:i], line[i:]
        i += 1
    return line, ""


def arg_names(define_line):
    """Local names declared in a define's parameter list, in order (unnamed params are already numeric)."""
    head = define_line[: define_line.rfind(")")]
    head = head[head.index("(") + 1 :]
    return LOCAL_RE.findall(head)


def renumber_function(lines):
    """lines: the define line through the closing '}' (inclusive). Returns the rewritten lines."""
    codes = [split_comment(l) for l in lines]
    mapping = {}
    counter = 0
    # Pass 1: assign numbers in textual order.
    args = arg_names(codes[0][0])
    for a in args:
        mapping[a] = str(counter)
        counter += 1
    # The entry block: unlabeled in the text unless the first body line is a label.
    first_body = 1
    while first_body < len(codes) and codes[first_body][0].strip() == "":
        first_body += 1
    m = LABEL_RE.match(codes[first_body][0].strip()) if first_body < len(codes) else None
    labels = {}  # line index -> old label name (or None for the implicit entry)
    if m:
        labels[first_body] = m.group(1)
    else:
        labels[first_body] = None
    if m:
        mapping[m.group(1)] = str(counter)
    entry_number = counter
    counter += 1
    for idx in range(first_body + (1 if m else 0), len(codes)):
        code = codes[idx][0]
        s = code.strip()
        if s == "}" or s == "":
            continue
        lm = LABEL_RE.match(s)
        if lm and not s.startswith("%") and " " not in lm.group(1):
            labels[idx] = lm.group(1)
            mapping[lm.group(1)] = str(counter)
            counter += 1
            continue
        dm = DEF_RE.match(code)
        if dm:
            mapping[dm.group(1)] = str(counter)
            counter += 1
    # Pass 2: rewrite tokens.
    out = []
    for idx, (code, comment) in enumerate(codes):
        if idx in labels and labels[idx] is not None:
            lm = LABEL_RE.match(code.strip())
            if idx == first_body:
                # LLVM prints no label for an unnamed entry block; keep only a comment it carried.
                if comment.strip():
                    out.append("  " + comment.strip())
                continue
            out.append(mapping[lm.group(1)] + ":" + lm.group(2) + comment)
            continue

        def sub(mo):
            name = mo.group(1)
            if name in mapping:
                return "%" + mapping[name]
            return mo.group(0)

        new_code = LOCAL_RE.sub(sub, code)
        out.append(new_code + comment)
    return out


def renumber_module(text):
    lines = text.split("\n")
    out = []
    i = 0
    while i < len(lines):
        if DEFINE_RE.match(split_comment(lines[i])[0]):
            j = i
            while split_comment(lines[j])[0].strip() != "}":
                j += 1
            out.extend(renumber_function(lines[i : j + 1]))
            i = j + 1
        else:
            out.append(lines[i])
            i += 1
    return "\n".join(out)


def canonical(path_or_text, is_path):
    """opt -discard-value-names output with comments and blank lines stripped (via llvm-as: opt cannot read
    textual IR into a name-discarding context)."""
    asm = subprocess.run([LLVM_AS, "-o", "-"] + ([path_or_text] if is_path else []),
                         input=None if is_path else path_or_text.encode(), capture_output=True)
    if asm.returncode != 0:
        return None, asm.stderr.decode()
    r = subprocess.run([OPT, "-S", "-discard-value-names", "-passes=verify", "-o", "-"],
                       input=asm.stdout, capture_output=True)
    if r.returncode != 0:
        return None, r.stderr.decode()
    keep = []
    for l in r.stdout.decode().split("\n"):
        c = split_comment(l)[0].rstrip()
        if c.strip() and not c.startswith("; ModuleID") and not c.startswith("source_filename"):
            keep.append(c)
    return keep, ""


def bodies(lines):
    """Function bodies only (define..}), whitespace-normalized, comments and blank lines removed."""
    out, inside = [], False
    for l in lines:
        c = split_comment(l)[0].strip()
        if not c:
            continue
        if c.startswith("define "):
            inside = True
        if inside:
            out.append(re.sub(r"\s+", " ", c))
        if c == "}":
            inside = False
    return out


def check(path, new_text):
    """The renumbered bodies must be textually identical to LLVM's own name-discarding print. LLVM 19 accepts
    gaps in numbered values, so parsing alone would not catch a wrong number: the comparison is textual."""
    ref, err = canonical(str(path), True)
    if ref is None:
        return f"{path}: original does not parse: {err.strip()}"
    got = bodies(new_text.split("\n"))
    ref = bodies(ref)
    if ref != got:
        import difflib

        d = "\n".join(difflib.unified_diff(ref, got, "opt-discard-value-names", "renumbered", lineterm="", n=1))
        return f"{path}: renumbering differs from opt -discard-value-names:\n{d}"
    return ""


def main(argv):
    check_only = "--check" in argv
    files = [Path(a) for a in argv if a != "--check"]
    bad = 0
    for f in files:
        text = f.read_text()
        new = renumber_module(text)
        msg = check(f, new)
        if msg:
            print(msg)
            bad += 1
            continue
        if not check_only and new != text:
            f.write_text(new)
    print(f"{len(files)} files, {bad} failures, {'checked' if check_only else 'rewritten'}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
