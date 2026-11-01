// mem-slots internal seam (not a frozen interface): the source of TaintInfo::cellsWritten (T2) that
// mem-slots reads, replaceable by a unit test (tests/mem-slots/slot_cells.cpp) while T2 is a stub.
#pragma once

#include <functional>

#include "cq/Taint.h"
#include "llvm/ADT/SmallVector.h"

namespace cq::mem::detail {
// Empty (the default): mem-slots calls TaintInfo::cellsWritten.
using CellsWrittenFn = std::function<llvm::SmallVector<unsigned, 4>(const Specialization &, unsigned argNo)>;
CellsWrittenFn &cellsWrittenOverride();
}
