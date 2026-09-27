int h(int a, int k) { int arr[4] = {1,2,3,4}; arr[a & 3] = 9; return arr[k & 3]; }
