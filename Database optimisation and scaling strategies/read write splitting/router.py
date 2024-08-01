import psycopg2
from psycopg2.pool import SimpleConnectionPool

class DBRouter:
    def __init__(self):
        self.write_pool = SimpleConnectionPool(1, 10, dsn="postgresql://user:pass@master:6432/db")
        self.read_pool = SimpleConnectionPool(1, 20, dsn="postgresql://user:pass@replica:6432/db")

    def get_connection(self, for_write=False):
        return self.write_pool.getconn() if for_write else self.read_pool.getconn()

    def return_connection(self, conn, for_write=False):
        if for_write:
            self.write_pool.putconn(conn)
        else:
            self.read_pool.putconn(conn)

db_router = DBRouter()

# Usage
with db_router.get_connection(for_write=True) as conn:
    with conn.cursor() as cur:
        cur.execute("INSERT INTO orders (customer_id, total_amount) VALUES (%s, %s)", (1, 100.00))