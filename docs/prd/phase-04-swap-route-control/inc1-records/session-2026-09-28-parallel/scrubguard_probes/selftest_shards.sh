#!/bin/bash
# Run the guard's self-test as the three ctest shards do (--shard K/3 --jobs 2), all three
# concurrently, each timed (wall/user/sys from /usr/bin/time -p) with the load before/after.
# usage: selftest_shards.sh <tag>   -> results_r2/<tag>_selftest_shard{1,2,3}.txt
set -u
W="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
R="$(cd "$(dirname "$0")" && pwd)"
TAG="${1:?tag}"
mkdir -p "$R/results_r2"
for k in 1 2 3; do
  bash "$R/timed_guard.sh" "$R/results_r2/${TAG}_selftest_shard$k.txt" --selftest --shard "$k/3" --jobs 2 &
done
wait
for k in 1 2 3; do
  echo "== shard $k"; grep -E "BAD|selftest shard|^real|^user|^sys|^rc=|load" "$R/results_r2/${TAG}_selftest_shard$k.txt"
done
