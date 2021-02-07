from redis import StrictRedis
import sys

host = "localhost"
host = sys.argv[1]
port = sys.argv[2] 
if len(sys.argv) > 3:
    password = sys.argv[3]
else:
    password = None


result = 'success'
try:
    r = StrictRedis(host=host, port=port, db=0, password=password)
    if not r.set('a', 'aa'):
        result = 'failed'
    if r.get('a')!= 'aa':
        result = 'failed'
    print "result:" + str(result)
    print r.get('a')
except:
    result = 'failed'
    print "result:" + result 
