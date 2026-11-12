#!/usr/bin/env python3
"""LIBC_COVERAGE recipe / CR rule 16: the string formatters (sprintf, snprintf, sscanf, swprintf, swscanf and their v
forms) are built over bundle-internal copies so no stream call by name remains in a lifted body (cq-2s5ho, cq-ojgho).

Every stream function a formatter calls by name gets a bundle-internal copy __cq_<name> (musl's vfprintf, vfscanf,
vfwprintf, vfwscanf become __cq_vfprintf, __cq_vfscanf, __cq_vfwprintf, __cq_vfwscanf), and so does every stream
function those copies call by name (vfwprintf's fprintf, fputwc and fwide; vfwscanf's fscanf, getwc, ungetwc and fwide;
fprintf's vfprintf, getwc's fgetwc, ...). A function without a stream name that a copy reaches and that itself reaches
a stream call by name is copied too, so the program's own calls of it keep their host stream calls. Functions that reach
no stream call are shared. Idempotent. usage: cq_formatters.py in.ll out.ll"""
import re, sys

FORMATTERS = ["sprintf", "snprintf", "sscanf", "vsprintf", "vsnprintf", "vsscanf",
              "swprintf", "vswprintf", "swscanf", "vswscanf",
              # the bundle's result entries (bundle/src/cq_count.c, cq-cdf9z): their private FILE is on their own stack
              "__cq_count_snprintf", "__cq_count_vsnprintf", "__cq_count_wprintf", "__cq_count_vwprintf",
              "__cq_count_wctomb", "__cq_count_wcsrtombs"]
# pass/lib/Common.cpp streamName: C17 7.21 / POSIX.1-2017 <stdio.h> less the string formatters, the <wchar.h> stream
# functions less the wide string formatters, CR rule 16's descriptor calls.
STREAM = set("""fopen freopen fclose fflush setbuf setvbuf fprintf printf vfprintf vprintf fscanf scanf vfscanf vscanf fgetc
getc getchar fgets gets fputc putc putchar fputs puts ungetc fread fwrite fgetpos fseek fsetpos ftell rewind clearerr feof
ferror perror remove rename tmpfile tmpnam getline getdelim fdopen fileno popen pclose fseeko ftello dprintf vdprintf
flockfile funlockfile ftrylockfile getc_unlocked getchar_unlocked putc_unlocked putchar_unlocked ctermid fmemopen
open_memstream renameat tempnam open close read write lseek fwprintf wprintf vfwprintf vwprintf fwscanf wscanf vfwscanf
vwscanf fgetwc fgetws fputwc fputws fwide getwc getwchar putwc putwchar ungetwc open_wmemstream""".split())
NAME = r'[\w.$]+'
REF = re.compile(rf'@({NAME})(?![\w.$])')
CQ = "__cq_"

text = open(sys.argv[1]).read()
if not text.endswith("\n"):
    text += "\n"
# the module's function bodies (by name: [start, end) in text) and its aliases (name -> aliasee)
bodies = {m.group(1): (m.start(), m.end())
          for m in re.finditer(rf'(?ms)^define [^\n]*?@({NAME})\(.*?^}}\n', text)}
aliases = dict(re.findall(rf'(?m)^@({NAME}) = [^\n]*?\balias [^\n]*?, ptr @({NAME})\s*$', text))


def target(n):
    """the body behind the name n (through aliases), or None"""
    for _ in range(16):
        if n in bodies:
            return n
        if n not in aliases:
            return None
        n = aliases[n]
    return None


def refs(n):
    s, e = bodies[n]
    first = text.index("\n", s)          # the references of the body, not its own name on the define line
    return set(REF.findall(text, first, e))


# taints: a body without a stream name that reaches a stream call by name through bodies without one; the formatters
# are rewritten in place below and taint nothing
graph = {n: refs(n) for n in bodies}
taints = set()
changed = True
while changed:
    changed = False
    for n in sorted(bodies):
        if n in taints or n in STREAM or n in FORMATTERS:
            continue
        if any(r in STREAM or (target(r) is not None and target(r) not in STREAM and target(r) in taints) for r in graph[n]):
            taints.add(n)
            changed = True


def redirected(r):
    """the name a reference r in a formatter or a copy is redirected to, or None"""
    if r.startswith(CQ):
        return None
    if r in STREAM:
        if target(r) is None:
            sys.exit(f"{r}: a stream call by name in a formatter's body, and no body to copy")
        return CQ + r
    t = target(r)
    if t is not None and t not in STREAM and t in taints:
        return CQ + t
    return None


def rewrite(body):
    """body (a function's text) with its references redirected; the names whose copies it needs"""
    need = set()
    head, _, rest = body.partition("\n")

    def sub(m):
        r = redirected(m.group(1))
        if r is None:
            return m.group(0)
        need.add(m.group(1) if m.group(1) in STREAM else target(m.group(1)))
        return "@" + r
    return head + "\n" + REF.sub(sub, rest), need


out = text
pending = set()
renamed = []
# the formatters, in place
for f in FORMATTERS:
    if f not in bodies:
        continue
    s, e = bodies[f]
    body = text[s:e]
    new, need = rewrite(body)
    if new != body:
        out = out.replace(body, new, 1)
        renamed.append(f)
    pending |= need
# the copies, each made once: __cq_<n> is the body behind n (a stream name's through its alias) under that name
made = []
while pending:
    n = min(pending)
    pending.discard(n)
    cq = CQ + n
    if cq in bodies or cq in made:
        continue
    s, e = bodies[target(n)]
    body = text[s:e]
    body = re.sub(rf'@{re.escape(target(n))}\(', f"@{cq}(", body, count=1)
    body = re.sub(r"^define (?:(?:internal|dso_local|local_unnamed_addr|unnamed_addr|hidden|protected|weak|weak_odr|"
                  r"linkonce|linkonce_odr|external|dso_preemptable) )*", "define internal ", body)
    body, need = rewrite(body)
    out += "\n" + body
    made.append(cq)
    pending |= {x for x in need if CQ + x not in bodies and CQ + x not in made}
open(sys.argv[2], "w").write(out)
print("renamed in formatters:", renamed, "copies:", made)
