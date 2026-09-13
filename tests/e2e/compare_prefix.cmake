# compare_prefix.cmake — assert that file A's first N lines equal file B's first
# N lines. Used by the Track M cascade gate, where B is a PREFIX PROGRAM of A
# (the same source minus its last `if`), so B's own tail is its measurements and
# a whole-file `compare_files` cannot express the relation.
foreach(v A B N)
  if(NOT DEFINED ${v})
    message(FATAL_ERROR "compare_prefix.cmake: -D${v}= is required")
  endif()
endforeach()
foreach(f "${A}" "${B}")
  if(NOT EXISTS "${f}")
    message(FATAL_ERROR "compare_prefix.cmake: missing ${f}")
  endif()
endforeach()
file(STRINGS "${A}" _a)
file(STRINGS "${B}" _b)
list(LENGTH _a _na)
list(LENGTH _b _nb)
if(_na LESS N OR _nb LESS N)
  message(FATAL_ERROR "compare_prefix.cmake: need ${N} lines, have ${_na} and ${_nb}")
endif()
math(EXPR _last "${N} - 1")
foreach(i RANGE ${_last})
  list(GET _a ${i} _x)
  list(GET _b ${i} _y)
  if(NOT _x STREQUAL _y)
    math(EXPR _ln "${i} + 1")
    message(FATAL_ERROR
      "prefix diverges at line ${_ln}:\n  A: ${_x}\n  B: ${_y}\n"
      "A=${A}\nB=${B}\n"
      "Re-derive BOTH goldens from the pass output; never edit one to match the other.")
  endif()
endforeach()
message(STATUS "prefix identical over ${N} lines")
