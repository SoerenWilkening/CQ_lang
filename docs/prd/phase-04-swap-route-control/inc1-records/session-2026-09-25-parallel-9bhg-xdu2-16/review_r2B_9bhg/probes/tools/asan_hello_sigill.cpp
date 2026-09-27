#include <cstdio>
#include <vector>
int main(){std::vector<int>*v=new std::vector<int>(3); int x=(*v)[1]; delete v; printf("%d\n", x); return 0;}
