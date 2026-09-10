#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int arr[4]={0,0,0,0}; int a=b?2:5; arr[1]=a; return cq_measure(arr[1])+cq_measure(b); }
