#!/usr/bin/env python3
"""Strip C/C++ comments (string/char-literal aware, incl. simple raw strings),
collapse whitespace, drop blank lines. stdin -> stdout."""
import sys, re
s = sys.stdin.read()
out = []; i = 0; n = len(s)
while i < n:
    c = s[i]
    if s.startswith('R"', i) and (i == 0 or not (s[i-1].isalnum() or s[i-1]=='_')):
        m = re.match(r'R"([^(\s]*)\(', s[i:])
        if m:
            end = s.find(')' + m.group(1) + '"', i)
            end = n if end < 0 else end + len(m.group(1)) + 2
            out.append(s[i:end]); i = end; continue
    if c == '"' or c == "'":
        j = i + 1
        while j < n and s[j] != c:
            j += 2 if s[j] == '\\' else 1
        out.append(s[i:j+1]); i = j + 1; continue
    if s.startswith('//', i):
        j = s.find('\n', i); j = n if j < 0 else j
        # line continuation
        while j < n and s[j-1] == '\\':
            k = s.find('\n', j+1); j = n if k < 0 else k
        i = j; continue
    if s.startswith('/*', i):
        j = s.find('*/', i + 2); j = n if j < 0 else j + 2
        out.append(' '); i = j; continue
    out.append(c); i += 1
t = ''.join(out)
for line in t.split('\n'):
    line = re.sub(r'\s+', ' ', line).strip()
    if line: print(line)
