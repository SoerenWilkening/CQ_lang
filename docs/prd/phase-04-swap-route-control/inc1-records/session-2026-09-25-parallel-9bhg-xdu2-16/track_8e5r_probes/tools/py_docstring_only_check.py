#!/usr/bin/env python3
"""py_docstring_only_check.py OLD.py NEW.py — prove a Python edit touched only
comments and docstrings: parse both, drop every module/class/function docstring,
and compare `ast.dump` (comments never reach the AST). Exit 1 on any code change.
Null control (a file against itself) and positive control (a one-token code change)
run first."""
import ast
import sys


def strip(src):
    t = ast.parse(src)
    for n in ast.walk(t):
        if isinstance(n, (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            b = n.body
            if b and isinstance(b[0], ast.Expr) and isinstance(getattr(b[0], "value", None), ast.Constant) \
                    and isinstance(b[0].value.value, str):
                n.body = b[1:] or [ast.Pass()]
    return ast.dump(t, include_attributes=False)


a = "def f():\n    '''doc'''\n    return 1  # c\n"
assert strip(a) == strip("def f():\n    '''other doc'''\n    return 1\n"), "null control failed"
assert strip(a) != strip("def f():\n    '''doc'''\n    return 2\n"), "positive control failed"
old, new = (open(p).read() for p in sys.argv[1:3])
same = strip(old) == strip(new)
print(f"py_docstring_only_check: {sys.argv[2]}: {'docstrings/comments ONLY' if same else 'CODE CHANGED'} "
      f"(controls passed)")
sys.exit(0 if same else 1)
