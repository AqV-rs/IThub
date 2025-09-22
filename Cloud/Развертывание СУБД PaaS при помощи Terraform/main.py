import os
import random
import string
import mysql.connector
from dotenv import load_dotenv

load_dotenv()

DB_HOST = os.getenv("MYSQL_HOST", "localhost")
DB_USER = os.getenv("MYSQL_USER", "root")
DB_PASSWORD = os.getenv("MYSQL_PASSWORD", "123qwe!E")
DB_NAME = os.getenv("MYSQL_DB", "testdb")
DB_PORT = os.getenv("MYSQL_PORT", "3306")

NUM_TABLES = int(os.getenv("NUM_TABLES", 200))
NUM_COLUMNS = int(os.getenv("NUM_COLUMNS", 50))
NUM_ROWS = int(os.getenv("NUM_ROWS", 100))

def random_string(length):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))


def generate_column_name(index):
    return f"col_{index + 1}"

conn = mysql.connector.connect(
    host=DB_HOST,
    user=DB_USER,
    password=DB_PASSWORD,
    port=DB_PORT
)
conn.autocommit = True
cursor = conn.cursor()

cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}")
cursor.execute(f"USE {DB_NAME}")

for t in range(NUM_TABLES):
    table_name = f"table_{t + 1}"
    columns_def = ", ".join([f"{generate_column_name(c)} VARCHAR(8)" for c in range(NUM_COLUMNS)])
    cursor.execute(f"CREATE TABLE IF NOT EXISTS {table_name} ({columns_def})")

    for r in range(NUM_ROWS):
        values = [f"{random_string(random.randint(4, 8))}" for _ in range(NUM_COLUMNS)]
        placeholders = ", ".join(["%s"] * NUM_COLUMNS)
        cursor.execute(f"INSERT INTO {table_name} VALUES ({placeholders})", values)

    print(f"Таблица {table_name} создана и заполнена {NUM_ROWS} строками")

cursor.close()
conn.close()
print("Генерация тестовых данных завершена.")
