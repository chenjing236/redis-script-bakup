#!/bin/bash
COUNT=50
InstanceId="redis-9e80nwrcvu17"
API_Host="jvessel-matrix-stag2.jdcloud.com"
PORT="18811"
API="checkConfigs"

for ((i=1; i<=${COUNT}; i++))
do 
	echo "5. /checkConfigs"
	URL=`curl -s -H "JVESSEL-Params:{\"region\":\"cn-north-1\",\"instanceId\":\"$InstanceId\",\"requestId\":\"117\"}" $API_Host:$PORT/$API`
	echo $URL
	echo $(date "+%Y-%m-%d %H:%M:%S:%N")
	
	# sleep for 1ms
	sleep 0.001
done