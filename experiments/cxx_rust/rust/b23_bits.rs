#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let v = q(x as u32); (v.count_ones() * 100 + v.leading_zeros() * 7 + v.trailing_zeros() + (v.rotate_left(y as u32 & 31) ^ v.swap_bytes() ^ v.reverse_bits())) as i32 }
