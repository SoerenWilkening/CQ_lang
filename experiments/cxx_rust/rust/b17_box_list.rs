#![allow(unused_imports, dead_code)]
include!("../cq.rs");
enum L { Cons(i32, Box<L>), Nil }
fn sum(l: &L) -> i32 { match l { L::Cons(v, n) => v.wrapping_add(sum(n).wrapping_mul(2)), L::Nil => 0 } }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut l = L::Nil; for i in 0..4 { l = L::Cons(if i == 2 { q(x) } else { y }, Box::new(l)); } sum(&l) }
