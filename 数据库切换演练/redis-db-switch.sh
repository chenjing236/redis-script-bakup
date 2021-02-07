
#!/bin/bash

COUNT=120
domain='redis-huowreapuc.cn-east-2.redis.jdcloud.com'

for ((i=1; i<=${COUNT}; i++))
do 
	URL=`python check-redis.py $domain`
	echo $URL
	echo $(date "+%Y-%m-%d %H:%M:%S:%N")
	sleep 1
done

