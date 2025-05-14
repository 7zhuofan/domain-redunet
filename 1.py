import MySQLdb

# 尝试建立连接
try:
    db = MySQLdb.connect(
        host="localhost",  # 根据需要修改
        user="root",       # 根据需要修改
        passwd="123456",   # 根据需要修改
        db="ER_Database"   # 根据需要修改
    )
    print("Database connected successfully!")
except MySQLdb.Error as e:
    print(f"Error: {e}")
# 确认 MySQL 连接
if mysql.connection is None:
    print("MySQL connection failed")
else:
    print("MySQL connection established")
