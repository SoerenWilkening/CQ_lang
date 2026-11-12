#!/usr/bin/env python3
"""The result entries a module needs before its link (owner ruling 2026-11-12, cq-cdf9z, cq-m7ftq).

    python3 driver/cq_entries.py MODULE.ll            the entry names, one per line
    python3 driver/cq_entries.py --decls MODULE.ll    the declarations to append to MODULE.ll before its link

The pass (pass/lib/eff/tape/Tape.cpp rewriteDeferredResults) computes the result of a deferred C library output
call by a call to a bundle result entry (bundle/recipe.json "entries", bundle/src/cq_count.c) that it inserts AFTER
the link, so the entry's body must already be in the module it reads. The contract, for every consumer that links
a program for the pass (driver/cqcc, the checker's oracle link, the musl sweep's row link):

  1. Before the link, scan the program's IR with needed() (this file); decls() gives the declarations of the
     names the module neither declares nor defines.
  2. Make the link pull their bodies. llvm-link drops a declaration nothing uses, so: put them in a unit of their
     own with `@llvm.compiler.used = appending global [n x ptr] [ptr @e, ...], section "llvm.metadata"` and link
     it in full before the bundle (`llvm-link -S prog.ll entries.ll --only-needed bundle...`; driver/cqcc does
     this). When the program is linked with a full library module instead (the musl sweep's rows), naming the
     entries in the internalize list is enough, step 3.
  3. Keep the names through any internalize/globaldce (`-internalize-public-api-list=<...,entry,...>`).

A program with no such call gets nothing: the module is unchanged byte for byte, so the pass's identity and the
corpus outputs do not move. The scan over-approximates the pass's site filter (it cannot see taint): a call to one
of the output functions below, declared and not defined in the module, whose result is used, or a format call
whose format is not a constant string free of %n. An entry linked for a call the pass then leaves classical is
an unused body, never a different value.

Only the format families (and the wide-character ones) need an entry; puts, fputs, fputc, putc, putchar, fwrite,
fflush and putw are templates over the arguments.
"""
import re
import sys

# C name -> (kind, index of the format argument). Kept in step with Tape.cpp outputFunction (an _unlocked form is
# its locked form).
OUTPUT = {
    "printf": ("fmt", 0), "fprintf": ("fmt", 1), "dprintf": ("fmt", 1),
    "vprintf": ("vfmt", 0), "vfprintf": ("vfmt", 1), "vdprintf": ("vfmt", 1),
    "wprintf": ("wfmt", 0), "fwprintf": ("wfmt", 1),
    "vwprintf": ("vwfmt", 0), "vfwprintf": ("vwfmt", 1),
    "fputwc": ("wc", 0), "putwc": ("wc", 0), "putwchar": ("wc", 0),
    "fputws": ("ws", 0),
}
ENTRY = {
    "fmt": "__cq_count_snprintf", "vfmt": "__cq_count_vsnprintf", "wfmt": "__cq_count_wprintf",
    "vwfmt": "__cq_count_vwprintf", "wc": "__cq_count_wctomb", "ws": "__cq_count_wcsrtombs",
}
# x86-64 (NORTHSTAR principle 3): size_t is i64. In bundle/recipe.json "entries" order.
DECL = {
    "__cq_count_snprintf": "declare i32 @__cq_count_snprintf(ptr, i64, ptr, ...)",
    "__cq_count_vsnprintf": "declare i32 @__cq_count_vsnprintf(ptr, i64, ptr, ptr)",
    "__cq_count_wprintf": "declare i32 @__cq_count_wprintf(ptr, ...)",
    "__cq_count_vwprintf": "declare i32 @__cq_count_vwprintf(ptr, ptr)",
    "__cq_count_wctomb": "declare i32 @__cq_count_wctomb(ptr, i32)",
    "__cq_count_wcsrtombs": "declare i64 @__cq_count_wcsrtombs(ptr, ptr, i64, ptr)",
}

_ID = r'(?:[-A-Za-z$._0-9]+|"[^"]*")'
_CALL = re.compile(r'^\s*(?:(%' + _ID + r')\s*=\s*)?(?:tail |musttail |notail )?(?:call|invoke)\b[^@\n]*?@(' + _ID +
                   r')\(', re.M)
_GLOBAL = re.compile(r'^@(' + _ID + r')\s*=\s*(?:[a-z_]+\s+)*?(?:constant|global)\s+\[\d+ x i(8|32)\]\s+'
                     r'(c"(?:[^"\\]|\\[0-9A-Fa-f]{2}|\\\\)*"|\[[^\]]*\]|zeroinitializer)', re.M)


def _cname(sym: str) -> str:
    sym = sym.strip('"')
    if sym.startswith("\\01_"):
        sym = sym[4:]
    if sym.endswith("_unlocked"):
        sym = sym[: -len("_unlocked")]
    return sym


def _args(text: str, start: int) -> list:
    """The top-level arguments of the call whose '(' is at text[start - 1]."""
    out, depth, cur, i, q = [], 0, [], start, False
    while i < len(text):
        ch = text[i]
        if q:
            cur.append(ch)
            q = ch != '"'
        elif ch == '"':
            cur.append(ch)
            q = True
        elif ch in "([{<":
            depth += 1
            cur.append(ch)
        elif ch in ")]}>":
            if depth == 0:
                out.append("".join(cur).strip())
                return out
            depth -= 1
            cur.append(ch)
        elif ch == "," and depth == 0:
            out.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
        i += 1
    return out


def _decode(init: str, width: str) -> str:
    if init == "zeroinitializer":
        return ""
    if width == "8":
        body = init[2:-1]
        b = re.sub(r"\\([0-9A-Fa-f]{2})", lambda m: chr(int(m.group(1), 16)), body.replace("\\\\", "\\5C"))
        return b.split("\0", 1)[0]
    units = [int(x) for x in re.findall(r"i32 (-?\d+)", init)]
    s = []
    for u in units:
        if u == 0:
            break
        s.append(chr(u) if 0 < u < 0x80 else "?")
    return "".join(s)


def _may_hold_n(fmt: str) -> bool:
    """Tape.cpp printfPlanOf's grammar: is there a conversion 'n'?"""
    i = 0
    while i < len(fmt):
        if fmt[i] != "%":
            i += 1
            continue
        i += 1
        if i < len(fmt) and fmt[i] == "%":
            i += 1
            continue
        m = re.match(r"(\d+\$)?[-+ #0']*(\*(\d+\$)?|\d*)(\.(\*(\d+\$)?|\d*))?[hlLqjzt]*", fmt[i:])
        i += m.end()
        if i < len(fmt):
            if fmt[i] == "n":
                return True
            i += 1
    return False


def needed(text: str) -> list:
    """The entry names the module's output calls may need, in DECL order."""
    globals_ = {m.group(1): (m.group(2), m.group(3)) for m in _GLOBAL.finditer(text)}
    defined = set(re.findall(r'^define\b[^@]*@(' + _ID + r')\(', text, re.M))
    want = set()
    # function bodies: from each 'define' to the next line that is exactly '}'
    for body in re.finditer(r"^define\b.*?^\}$", text, re.M | re.S):
        b = body.group(0)
        for m in _CALL.finditer(b):
            sym = m.group(2)
            name = _cname(sym)
            if name not in OUTPUT or sym in defined:
                continue
            kind, fi = OUTPUT[name]
            res = m.group(1)
            used = bool(res) and re.search(re.escape(res) + r'(?![-A-Za-z$._0-9])', b[m.end():] + b[:m.start()])
            if not used and kind in ("fmt", "vfmt", "wfmt", "vwfmt"):
                args = _args(b, m.end())
                tok = args[fi].split()[-1] if fi < len(args) and args[fi].split() else ""
                g = globals_.get(tok[1:]) if tok.startswith("@") else None
                used = g is None or _may_hold_n(_decode(g[1], g[0]))
            if used:
                want.add(ENTRY[kind])
    return [n for n in DECL if n in want]


def decls(text: str) -> list:
    """The declarations to append: the needed entries the module neither declares nor defines."""
    have = set(re.findall(r'^(?:declare|define)\b[^@]*@(' + _ID + r')\(', text, re.M))
    return [DECL[n] for n in needed(text) if n not in have]


def names(decl_lines) -> list:
    """The symbol names of decls()'s lines."""
    return [re.search(r"@(\w+)\(", d).group(1) for d in decl_lines]


def main(argv) -> int:
    want_decls = "--decls" in argv
    files = [a for a in argv if a != "--decls"]
    if len(files) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    text = open(files[0]).read()
    for line in (decls(text) if want_decls else needed(text)):
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
