#!/bin/bash
InstanceId="redis-9e80nwrcvu17"
API_Host="jvessel-matrix-stag2.jdcloud.com"
PORT="18811"

echo $(date "+%Y-%m-%d %H:%M:%S:%N")

echo "1. /getProxyTopo"
URL=`curl -s -H "JVESSEL-Params:{\"region\":\"cn-north-1\",\"instanceId\":\"$InstanceId\",\"requestId\":\"117\"}" $API_Host:$PORT/getProxyTopo`
echo $URL

echo "2. /getAllStatus"
URL=`curl -s -H "JVESSEL-Params:{\"region\":\"cn-north-1\",\"instanceId\":\"$InstanceId\",\"requestId\":\"117\"}" $API_Host:$PORT/getAllStatus`
echo $URL

echo "3. /checkTopo"
URL=`curl -s -H "JVESSEL-Params:{\"region\":\"cn-north-1\",\"instanceId\":\"$InstanceId\",\"requestId\":\"117\"}" $API_Host:$PORT/checkTopo`
echo $URL

echo "4. /checkShardRole"
URL=`curl -s -H "JVESSEL-Params:{\"region\":\"cn-north-1\",\"instanceId\":\"$InstanceId\",\"requestId\":\"117\"}" $API_Host:$PORT/checkShardRole`
echo $URL

echo "5. /checkConfigs"
URL=`curl -s -H "JVESSEL-Params:{\"region\":\"cn-north-1\",\"instanceId\":\"$InstanceId\",\"requestId\":\"117\"}" $API_Host:$PORT/checkConfigs`
echo $URL

echo "6. /checkAll"
URL=`curl -s -H "JVESSEL-Params:{\"region\":\"cn-north-1\",\"instanceId\":\"$InstanceId\",\"requestId\":\"117\"}" $API_Host:$PORT/checkAll`
echo $URL

echo "7. /getSlotInfo"
URL=`curl -s -H "JVESSEL-Params:{\"region\":\"cn-north-1\",\"instanceId\":\"$InstanceId\",\"requestId\":\"117\"}" $API_Host:$PORT/getSlotInfo`
echo $URL

echo $(date "+%Y-%m-%d %H:%M:%S:%N")

