#!/usr/bin/env python3
"""Generate CODE_MAP.md for maintained source files.

The map is generated from source rather than maintained by hand. It records
named function definitions and their first source line, including generated
runtime functions. Run this script after adding, moving, or renaming a
function; ``--check`` is suitable for a presubmit or ctest gate.
"""

from __future__ import annotations

import argparse
import ast
import bisect
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "CODE_MAP.md"
SOURCE_ROOTS = ("include", "ir-pass", "runtime", "tools", "tests", "example", "demo")
EXTENSIONS = {".c", ".cc", ".cpp", ".cxx", ".h", ".hh", ".hpp", ".py"}
EXCLUDED_PARTS = {
    ".git", ".beads", ".agents", ".codex", "build", "cmake-build-debug",
    "scratchpad_g387", "archive", "Testing",
}
CONTROL_NAMES = {"if", "for", "while", "switch", "catch", "return"}


def tracked_sources() -> list[Path]:
    """Return maintained, tracked source files in deterministic order."""
    try:
        result = subprocess.run(
            ["git", "ls-files", *SOURCE_ROOTS], cwd=ROOT, check=True,
            capture_output=True, text=True,
        )
        paths = [ROOT / line for line in result.stdout.splitlines()]
        # Include this newly added generator before its first commit as well.
        paths.append(Path(__file__).resolve())
    except (OSError, subprocess.CalledProcessError):
        paths = [p for root in SOURCE_ROOTS for p in (ROOT / root).rglob("*")]
    return sorted(
        p for p in paths
        if p.is_file() and p.suffix in EXTENSIONS
        and not any(part in EXCLUDED_PARTS or part.startswith("build-") for part in p.parts)
    )


def mask_cpp(text: str) -> str:
    """Blank comments, strings, and preprocessor lines while preserving lines."""
    out: list[str] = []
    i = 0
    state = "code"
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if state == "code":
            if ch == "/" and nxt == "/":
                out.extend("  ")
                i += 2
                state = "line"
            elif ch == "/" and nxt == "*":
                out.extend("  ")
                i += 2
                state = "block"
            elif ch in "\"'":
                out.append(" ")
                state = ch
                i += 1
            elif ch == "#" and (not out or out[-1] == "\n"):
                out.append(" ")
                i += 1
                state = "line"
            else:
                out.append(ch)
                i += 1
        elif state == "line":
            if ch == "\n":
                out.append(ch)
                state = "code"
            else:
                out.append(" ")
            i += 1
        elif state == "block":
            if ch == "*" and nxt == "/":
                out.extend("  ")
                i += 2
                state = "code"
            else:
                out.append("\n" if ch == "\n" else " ")
                i += 1
        else:
            if ch == "\\":
                out.extend("  ")
                i += 2
            elif ch == state:
                out.append(" ")
                i += 1
                state = "code"
            else:
                out.append("\n" if ch == "\n" else " ")
                i += 1
    return "".join(out)


def cpp_functions(text: str) -> list[tuple[str, int]]:
    """Find named C/C++ definitions without depending on a specific ctags."""
    masked = mask_cpp(text)
    pairs: dict[int, int] = {}
    stack: list[int] = []
    for index, char in enumerate(masked):
        if char == "(":
            stack.append(index)
        elif char == ")" and stack:
            pairs[stack.pop()] = index
    newlines = [index for index, char in enumerate(masked) if char == "\n"]
    found: list[tuple[str, int]] = []
    for open_at, close_at in pairs.items():
        suffix = masked[close_at + 1:close_at + 513]
        if not re.match(r"\s*(?:const\b|noexcept\b|->|requires\b|__attribute__\b|\{)*\s*\{", suffix):
            continue
        prefix = masked[max(0, open_at - 512):open_at].rstrip()
        name_match = re.search(r"([~A-Za-z_][A-Za-z0-9_:~]*)\s*$", prefix)
        if not name_match or name_match.group(1).split("::")[-1] in CONTROL_NAMES:
            continue
        # `Member(value)` in a constructor initializer is not a definition.
        before_name = prefix[:name_match.start()].rstrip()
        if before_name.endswith((":", ",")):
            continue
        name = name_match.group(1)
        line = bisect.bisect_left(newlines, open_at) + 1
        found.append((name, line))
    return sorted(set(found), key=lambda item: (item[1], item[0]))


def python_functions(text: str) -> list[tuple[str, int]]:
    """Return module, class, and nested Python function definitions."""
    try:
        tree = ast.parse(text)
    except SyntaxError:
        return []
    result: list[tuple[str, int]] = []

    def visit(node: ast.AST, scope: tuple[str, ...] = ()) -> None:
        for child in ast.iter_child_nodes(node):
            if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
                name = ".".join((*scope, child.name))
                result.append((name, child.lineno))
                visit(child, (*scope, child.name))
            elif isinstance(child, ast.ClassDef):
                visit(child, (*scope, child.name))
            else:
                visit(child, scope)

    visit(tree)
    return sorted(result, key=lambda item: (item[1], item[0]))


def file_functions(path: Path) -> list[tuple[str, int]]:
    text = path.read_text(encoding="utf-8", errors="replace")
    return python_functions(text) if path.suffix == ".py" else cpp_functions(text)


def render(files: list[Path]) -> str:
    entries = []
    for path in files:
        text = path.read_text(encoding="utf-8", errors="replace")
        entries.append((path.relative_to(ROOT), file_functions(path), len(text.splitlines())))
    with_functions = [(p, funcs, lines) for p, funcs, lines in entries if funcs]
    total_functions = sum(len(funcs) for _, funcs, _ in with_functions)
    lines = [
        "# CQ_lang Function Map", "",
        "<!-- GENERATED by tools/update_code_map.py; do not edit manually. -->", "",
        "This is the source-of-truth index for named function definitions in the maintained code surface. "
        "Each entry is `path:line — function`; line numbers are regenerated from source.", "",
        "## How to use and update", "",
        "Agents must consult this file before searching source for a function. After adding, moving, "
        "renaming, or deleting a function, run `python3 tools/update_code_map.py` and include the map "
        "update in the same change. Use `python3 tools/update_code_map.py --check` to detect drift.", "",
        f"Scope: {len(files)} maintained source files, {total_functions} named function definitions. "
        "Build output, scratch probes, archived code, documentation, and corpus artifacts are excluded.", "",
        "## Files over the 400-line budget", "",
        "The entries below are an inventory for decomposition work. Generated files and test/tooling "
        "sources are listed too; they are not silently treated as application logic.", "",
    ]
    over = [(p, count) for p, _, count in entries if count > 400]
    lines.extend(
        (f"- `{path}` — {count} physical lines" for path, count in
         sorted(over, key=lambda item: (-item[1], str(item[0]))))
        or ["- None"]
    )
    lines.extend(["", "## Function locations", ""])
    for path, funcs, physical_lines in with_functions:
        lines.extend([f"### `{path}` ({physical_lines} lines)", ""])
        lines.extend(f"- `{path}:{line}` — `{name}`" for name, line in funcs)
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if CODE_MAP.md is stale")
    args = parser.parse_args()
    rendered = render(tracked_sources())
    if args.check:
        actual = OUTPUT.read_text(encoding="utf-8") if OUTPUT.exists() else ""
        if actual != rendered:
            print(f"{OUTPUT.relative_to(ROOT)} is stale; run tools/update_code_map.py", file=sys.stderr)
            return 1
    else:
        OUTPUT.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
