
from redis import StrictRedis
import sys

host = "localhost"
host = sys.argv[1] if len(sys.argv) > 1 else host
result = 0

r = StrictRedis(host=host, port=6379, db=0, password=None)
print(r.get('a'))
