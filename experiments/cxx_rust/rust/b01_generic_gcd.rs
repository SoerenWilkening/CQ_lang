#![allow(unused_imports, dead_code)]
include!("../cq.rs");
fn gcd<T: Copy + core::ops::Rem<Output = T> + PartialEq + Default>(mut a: T, mut b: T) -> T { for _ in 0..8 { if b == T::default() { break; } let t = a % b; a = b; b = t; } a }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { gcd::<u8>(q(x as u8), y as u8 | 1) as i32 }
