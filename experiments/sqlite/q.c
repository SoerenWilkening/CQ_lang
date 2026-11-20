/* SQLite on quantum data: the bound parameter of a query is in superposition, so the count is
 * computed for every x in 0..255 at once. In-memory database, no file. */
#include "sqlite3.h"
int main(void) {
    sqlite3 *db;
    sqlite3_stmt *st;
    sqlite3_open(":memory:", &db);
    sqlite3_exec(db, "CREATE TABLE t(a INTEGER);"
                     "INSERT INTO t VALUES(1),(2),(3),(4),(5),(6),(7),(8);", 0, 0, 0);
    sqlite3_prepare_v2(db, "SELECT count(*) FROM t WHERE a < ?", -1, &st, 0);

    unsigned char x = 0;
    cq_theta(&x, M_PI_2);
    sqlite3_bind_int(st, 1, x);
    sqlite3_step(st);
    int n = sqlite3_column_int(st, 0);
    return cq_measure(n);
}
