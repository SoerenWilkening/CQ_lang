#!/bin/bash
# usage: strip_diff.sh <repo> <revA> <revB> <paths...>
# comment+whitespace-stripped diff of every .cpp/.h changed between revA and revB
set -u
REPO=$1; A=$2; B=$3; shift 3
CL=/usr/local/opt/llvm@19/bin/clang
W=$(mktemp -d)
strip() { # stdin -> stdout
  cat > "$W/in.cpp"
  python3 "$(dirname "$0")/strip.py" < "$W/in.cpp"
}
n=0
for f in $(git -C "$REPO" diff --name-only "$A" "$B" -- "$@" | grep -E '\.(cpp|h)$'); do
  n=$((n+1))
  git -C "$REPO" show "$A:$f" 2>/dev/null | strip > "$W/a"
  git -C "$REPO" show "$B:$f" 2>/dev/null | strip > "$W/b"
  if ! cmp -s "$W/a" "$W/b"; then
    echo "##### $f"
    diff "$W/a" "$W/b"
  fi
done
echo "## files considered: $n"
rm -rf "$W"
