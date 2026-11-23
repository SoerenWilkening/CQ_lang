#![allow(unused_imports, dead_code)]
include!("../cq.rs");
fn mix(w: &[u32]) -> u32 { let (mut a, mut b) = (0x6a09e667u32, 0xbb67ae85u32); for x in w { let t = a.rotate_right(6) ^ (b & x); a = b.wrapping_add(t); b = t ^ (x << 3); } a ^ b }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut w = [0u32; 8]; for i in 0..8 { w[i] = (i as u32).wrapping_mul(y as u32); } w[1] = q(x as u32); mix(&w) as i32 }
