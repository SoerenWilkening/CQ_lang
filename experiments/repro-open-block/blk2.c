int g(int);
int h(int);
void err(const char *, int);
int f(long n, const int *data)
{
  for (long i = 0; i < n; i++)
    {
      for (int k = 0; k < 2; k++)
        {
          if (k > 0)
            if (g(1) == -1) { err("a", 1); return 5; }
          if (h(data[2 * i + k]) < 0) { err("b", 2); return 5; }
        }
      if (g(3) == -1) { err("a", 3); return 5; }
    }
  return 0;
}
