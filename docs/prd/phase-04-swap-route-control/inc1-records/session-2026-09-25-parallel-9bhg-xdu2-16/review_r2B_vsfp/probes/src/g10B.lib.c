int h(int a, int k) { int buf[2]; __builtin_memcpy((void*)buf, &a, 4); volatile int z = buf[0]; return k + 1; }
