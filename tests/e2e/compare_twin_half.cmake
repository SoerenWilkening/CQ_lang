# compare_twin_half.cmake — assert that a LINE RANGE of golden A equals a line
# range of golden B after per-file handle renaming. The Track M twin gate: two
# spellings of one program whose select halves must be byte-identical, but whose
# handle NUMBERING differs because one of them emits an extra gate earlier on.
#
# Renaming is whole-token (`h1` never matches inside `h10`), and every rename
# target must be distinct from every source, so the substitution cannot alias.
foreach(v A B AFROM ATO BFROM BTO AREN BREN)
  if(NOT DEFINED ${v})
    message(FATAL_ERROR "compare_twin_half.cmake: -D${v}= is required")
  endif()
endforeach()

function(_slice_ren out file from to renames)
  file(STRINGS "${file}" _lines)
  list(LENGTH _lines _n)
  if(_n LESS to)
    message(FATAL_ERROR "compare_twin_half.cmake: ${file} has ${_n} lines, need ${to}")
  endif()
  set(_acc "")
  math(EXPR _f "${from} - 1")
  math(EXPR _t "${to} - 1")
  foreach(i RANGE ${_f} ${_t})
    list(GET _lines ${i} _l)
    foreach(r IN LISTS renames)
      string(REPLACE "=" ";" _kv "${r}")
      list(GET _kv 0 _k)
      list(GET _kv 1 _v)
      string(REGEX REPLACE "(^|[^A-Za-z0-9_])${_k}([^A-Za-z0-9_]|$)" "\\1${_v}\\2" _l "${_l}")
    endforeach()
    list(APPEND _acc "${_l}")
  endforeach()
  set(${out} "${_acc}" PARENT_SCOPE)
endfunction()

_slice_ren(_a "${A}" ${AFROM} ${ATO} "${AREN}")
_slice_ren(_b "${B}" ${BFROM} ${BTO} "${BREN}")
list(LENGTH _a _na)
list(LENGTH _b _nb)
if(NOT _na EQUAL _nb)
  message(FATAL_ERROR "compare_twin_half.cmake: ${_na} vs ${_nb} lines")
endif()
math(EXPR _last "${_na} - 1")
foreach(i RANGE ${_last})
  list(GET _a ${i} _x)
  list(GET _b ${i} _y)
  if(NOT _x STREQUAL _y)
    message(FATAL_ERROR
      "twin halves diverge at offset ${i}:\n  A: ${_x}\n  B: ${_y}\n"
      "A=${A} [${AFROM}..${ATO}]\nB=${B} [${BFROM}..${BTO}]\n"
      "The widening was supposed to add an ACCEPT, not a STREAM. Re-derive both.")
  endif()
endforeach()
message(STATUS "twin halves identical over ${_na} lines")
