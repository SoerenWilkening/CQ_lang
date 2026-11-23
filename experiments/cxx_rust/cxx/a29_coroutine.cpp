#include "cq.hpp"
#include <coroutine>
struct Gen { struct promise_type { int v; Gen get_return_object() { return {std::coroutine_handle<promise_type>::from_promise(*this)}; }
  std::suspend_always initial_suspend() { return {}; } std::suspend_always final_suspend() noexcept { return {}; } std::suspend_always yield_value(int x) { v = x; return {}; } void return_void() {} void unhandled_exception() {} };
  std::coroutine_handle<promise_type> h; ~Gen() { h.destroy(); } };
__attribute__((noinline)) Gen fib(int a, int n) { int b = 1; for (int i = 0; i < n; i++) { co_yield a; int t = a + b; a = b; b = t; } }
ENTRY int f(int x, int y) { Gen g = fib(q(x), 5); int s = 0; for (int i = 0; i < 4; i++) { g.h.resume(); s = s * 3 + g.h.promise().v; } return s; }
