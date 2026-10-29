# tests/bundle (cq-w1-bundle): the version 1 injection bundle against the corpus. With
# -DCQ_BUNDLE_SRC=<dir holding the pinned musl/ and llvm-project/ checkouts> the test also rebuilds the
# bundle and requires the pinned sha256.
set(CQ_BUNDLE_SRC "" CACHE PATH "checkouts of the bundle's pinned sources (musl/, llvm-project/)")
set(_cq_bundle_args --spec ${CQ_SPEC_DIR})
if(CQ_BUNDLE_SRC)
  list(APPEND _cq_bundle_args --sources ${CQ_BUNDLE_SRC})
endif()
add_test(NAME bundle
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/check_bundle.py ${_cq_bundle_args}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
