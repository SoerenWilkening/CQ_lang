#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[derive(Clone, Copy)] struct M<const N: usize>([[i32; N]; N]);
impl<const N: usize> core::ops::Mul for M<N> { type Output = Self; fn mul(self, o: Self) -> Self { let mut r = M([[0; N]; N]); for i in 0..N { for j in 0..N { for k in 0..N { r.0[i][j] = r.0[i][j].wrapping_add(self.0[i][k].wrapping_mul(o.0[k][j])); } } } r } }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let m = M([[1, q(x)], [1, y]]); let r = m * m * m; r.0[0][0].wrapping_add(r.0[1][1]).wrapping_add(r.0[0][1]) }
