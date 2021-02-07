import bmemcached
import sys

host = "localhost"
host = sys.argv[1] if len(sys.argv) > 1 else host
result = 'success'
#port = 11211
client = bmemcached.Client('%s:11211' % host)
if not client.set('key1', 'value1'):
    result = 'failed'
if client.get('key1')!= 'value1':
    result = 'failed'
print "result:" + str(result)
print "key1:" + client.get('key1')

