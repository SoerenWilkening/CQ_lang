#!/usr/bin/env python3
"""cq-d4n0n: the effect table of checker/rt/fx_standin.h (cq_fx_table) against the pass's stream names.

The pass makes every call of a stream function (pass/lib/Common.cpp streamName) an effect entry of its name; the checker
decides from cq_fx_table alone whether the entry is an INPUT call (ruling Q5: it consumes from the one input stream) or
the stand-in. A name missing from the table is the stand-in on both sides: an input call that consumes nothing and reads
a hash (getc_unlocked and getchar_unlocked were, cq-d4n0n). This test fails when
  1. a name streamName lists is neither classified INPUT nor NOT_INPUT below (a new stream name must be classified),
  2. an INPUT name has no 'I' row in the table,
  3. an _unlocked alias musl defines (bodiless under ruling Q6, so an effect entry of its name) of a function the table
     has has no row, or a row whose class or roles differ from its locked form's (owner ruling 2026-11-12: an _unlocked
     variant follows its locked form).
Also builds and runs fx_stream_test.c (cq-dsnrs: the stream model against musl's ungetc, ungetwc, getdelim).
Usage: test_fx_table.py [--clang CLANG] (reads the repository)."""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# The streamName functions that read the input stream (C17 7.21.7, 7.21.8.1, 7.21.6.2/4, 7.29.3, POSIX read, getline,
# getdelim, getc_unlocked, getchar_unlocked) or its state (feof, ferror, clearerr, ungetc, ungetwc: fx_standin.h's model).
INPUT = set("""fgetc getc getchar fgets gets ungetc fread clearerr feof ferror getline getdelim read fscanf scanf vfscanf
vscanf getc_unlocked getchar_unlocked fwscanf wscanf vfwscanf vwscanf fgetwc fgetws getwc getwchar ungetwc""".split())
# The others: output, opening and closing, buffering, positioning, locking, names. No byte of the input stream is consumed.
NOT_INPUT = set("""fopen freopen fclose fflush setbuf setvbuf fprintf printf vfprintf vprintf fputc putc putchar fputs puts
fwrite fgetpos fseek fsetpos ftell rewind perror remove rename tmpfile tmpnam fdopen fileno popen pclose fseeko ftello
dprintf vdprintf flockfile funlockfile ftrylockfile putc_unlocked putchar_unlocked ctermid fmemopen open_memstream renameat
tempnam open close write lseek fwprintf wprintf vfwprintf vwprintf fputwc fputws fwide putwc putwchar open_wmemstream""".split())
# musl's public _unlocked aliases (musl b1efda5 src/stdio: weak_alias(..., X_unlocked)).
MUSL_UNLOCKED = """clearerr_unlocked feof_unlocked ferror_unlocked fflush_unlocked fgetc_unlocked fgets_unlocked fgetwc_unlocked
fgetws_unlocked fileno_unlocked fputc_unlocked fputs_unlocked fputwc_unlocked fputws_unlocked fread_unlocked fwrite_unlocked
getc_unlocked getchar_unlocked getwc_unlocked getwchar_unlocked putc_unlocked putchar_unlocked putwc_unlocked
putwchar_unlocked""".split()


def stream_names():
    text = (ROOT / "pass/lib/Common.cpp").read_text()
    body = re.search(r"bool streamName\(StringRef n\) \{(.*?)\n\}", text, re.S).group(1)
    names = re.search(r"names\[\] = \{(.*?)\};", body, re.S).group(1)
    return set(re.findall(r'"([^"]+)"', names))


def fx_table():
    text = (ROOT / "checker/rt/fx_standin.h").read_text()
    body = re.search(r"cq_fx_table\[\] = \{(.*?)\n\};", text, re.S).group(1)
    body = re.sub(r"/\*.*?\*/", "", body, flags=re.S)
    return {n: (c, r) for n, c, r in re.findall(r"\{\"([^\"]+)\", '(.)', \"([^\"]*)\"\}", body)}


def main():
    errs = []
    sn, tab = stream_names(), fx_table()
    if not sn or not tab:
        errs.append("could not read streamName or cq_fx_table")
    for n in sorted(sn - INPUT - NOT_INPUT):
        errs.append(f"streamName lists {n}, which this test does not classify (INPUT or NOT_INPUT)")
    for n in sorted((INPUT | NOT_INPUT) - sn):
        errs.append(f"{n} is classified here but streamName does not list it")
    for n in sorted(INPUT):
        if tab.get(n, ("",))[0] != "I":
            errs.append(f"{n}: an input stream call with no INPUT row in cq_fx_table")
    for n in sorted(NOT_INPUT):
        if tab.get(n, ("",))[0] == "I":
            errs.append(f"{n}: an INPUT row for a call classified NOT_INPUT")
    for u in MUSL_UNLOCKED:
        base = u[:-len("_unlocked")]
        if base in tab and tab.get(u) != tab[base]:
            errs.append(f"{u}: row {tab.get(u)} differs from its locked form {base}'s {tab[base]}")
        if base in INPUT and u not in tab:
            errs.append(f"{u}: the _unlocked form of an input call has no row")
    clang = sys.argv[sys.argv.index("--clang") + 1] if "--clang" in sys.argv else "/usr/local/opt/llvm@19/bin/clang"
    with tempfile.TemporaryDirectory(prefix="cq-fxs.") as d:
        exe = Path(d) / "fxs"
        here = Path(__file__).resolve().parent
        b = subprocess.run([clang, "-std=c17", "-O1", "-I", str(ROOT / "checker/rt"), str(here / "fx_stream_test.c"),
                            "-o", str(exe)], capture_output=True, text=True)
        if b.returncode:
            errs.append("fx_stream_test.c does not build: " + b.stderr.strip())
        else:
            r = subprocess.run([str(exe)], capture_output=True, text=True)
            print(r.stdout.strip())
            if r.returncode:
                errs.append("fx_stream_test failed")
    for e in errs:
        print("FAIL", e)
    print(f"{len(errs)} failures" if errs else f"fx table: {len(sn)} stream names, {len(tab)} rows, all classified")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
