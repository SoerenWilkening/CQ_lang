/* n01 lib — a clone whose select is keyed on a _Bool PARAMETER (a ¬flag bracket would WRITE it) */
int h(int a, _Bool b, int k) { return b ? 0 : k; }
