#include "cq.hpp"
template <class T> T gcd(T a, T b) { for (int i = 0; i < 8 && b; i++) { T t = a % b; a = b; b = t; } return a; }
ENTRY int f(int x, int y) { unsigned char a = q((unsigned char)x); return gcd<unsigned char>(a, (unsigned char)(y | 1)); }
