#include "CQ.h"
int main(void){ bool b=0; b=cq_theta(b,0.5); int q=cq_theta(3,0.2); int arr[4]={0,0,0,0}; arr[2]= b?2:5; return cq_measure(arr[2])+cq_measure(q)+cq_measure(b); }
