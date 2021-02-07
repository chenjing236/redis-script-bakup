from redis import StrictRedis
import sys

host = "localhost"
host = sys.argv[1] if len(sys.argv) > 1 else host
result = 'success'
try:
    r = StrictRedis(host=host, port=6379, db=0, password=None)
    if not r.set('a', 'aa'):
        result = 'failed'
    if r.get('a')!= 'aa':
        result = 'failed'
    print "result:" + str(result)
    print r.get('a')
except:
    result = 'failed'
    print "result:" + result 
