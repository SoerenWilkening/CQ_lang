# Unit tests of module chk-report (bead cq-w0-chk-report).
cq_add_python_unit_classes(chk-report ${CMAKE_CURRENT_SOURCE_DIR}/test_report.py
  ${CMAKE_SOURCE_DIR} "CQ_PLUGIN=$<TARGET_FILE:CQLower>")
