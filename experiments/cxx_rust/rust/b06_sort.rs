#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut a = [q(x), y, 2, 9]; a.sort_unstable(); a[0].wrapping_add(a[1].wrapping_mul(3)).wrapping_add(a[2].wrapping_mul(5)).wrapping_add(a[3].wrapping_mul(7)) }
