#!/bin/sh
# run one .ll on the frozen ORACLE; print rc + decline string (short tag)
R=/Users/sorenwilkening/Desktop/CQ_lang
out=$(CQ_CTRL_DBG=1 "$R/build/ir-pass/cq-opt" -load-pass-plugin "$R/build/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$1" -o /dev/null 2>&1); rc=$?
s=$(printf '%s' "$out" | grep -o 'cq[a-z ]*lowering: [^;]*' | head -1)
case "$s" in
  *"state prep seed is proven equal"*) tag="F2" ;;
  "") tag="ACCEPT" ;;
  *) tag=$(printf '%s' "$s" | sed 's/^cq[a-z ]*lowering: //' | cut -c1-48) ;;
esac
printf '%-58s rc=%s  %s\n' "$(basename "$1")" "$rc" "$tag"
