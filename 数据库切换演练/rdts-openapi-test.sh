#!/bin/bash

openapi_host=rdts-openapi-stag.jdcloud.com
openapi_version=v2
region_id=cn-north-1
pin=jcloudiaas2
src_port=6379
tgt_port=6379

if [[ $# -ne 5 ]]; then
    echo "usage: shell src_host tgt_host rdb_path aof_path"
    return 1
fi

src_pwd=
src_url=$1
tgt_pwd=
tgt_url=$2
rdb_path=$3
aof_path=$4
max_retry=60


function echo_ok (){
    echo "ok"
}

function echo_error (){
    echo "error: "$*
}


function check_openapi_response(){
    local result=$*
    if [[ -z "$result" ]]; then
        echo "response is empty"
        return 1
    fi
    code=`echo "$result" | jq -r '.error.code'`
    if [[ $? -ne 0 ]]; then
        echo "response is not a valid json, response: $result"
        return 1
    fi
    if [[ $code -eq 0 ]]; then
        return 0
    else
        echo "response return with error: $result"
        return 1
    fi
}

function createMigration(){
    pin_base64=`echo -n $pin | base64`
    local response=`curl -s -H "Content-Type: application/json" -H"x-jdcloud-pin: $pin_base64"\
    -X POST --connect-timeout 5 --retry 2 \
    "$openapi_host/v2/regions/$region_id/instance" \
    -d "{
        \"migrateConfig\":{
            \"name\":\"migrate-test\",
            \"srcType\":\"jcloud\",
            \"srcPwd\":\"$src_pwd\",
            \"srcUrl\":\"$src_url\",
            \"tgtType\":\"jcloud\",
            \"tgtPwd\":\"$tgt_pwd\",
            \"tgtUrl\":\"$tgt_url\"
        },
        \"azAndNetConfig\":{
            \"azId\":\"cn-north-1b\"
        },
    }"`
    check_openapi_response $response
    if [[ $? -ne 0 ]]; then
        echo "createMigration error: $response"
        return 1
    fi
    local instance_id=`echo $response |jq -r '.result.instanceId'`
    echo $instance_id
    return 0
}

function listMigration() {
    pin_base64=`echo -n $pin | base64`
    local response=`curl -s -H"x-jdcloud-pin: $pin_base64"\
        -X GET --connect-timeout 5 --retry 2 \
        "$openapi_host/v2/regions/$region_id/instance"`
    
    check_openapi_response $response
    if [[ $? -ne 0 ]]; then
        echo "listMigration error: $response"
        return 1
    fi
    echo $response | jq -r '.result'
    return 0
}

function checkMigrationStatus(){
    instance_id=$1
    expect_status=$2
    pin_base64=`echo -n $pin | base64`
    local response=`curl -s -H"x-jdcloud-pin: $pin_base64"\
        -X GET --connect-timeout 5 --retry 2 \
        "$openapi_host/v2/regions/$region_id/instance/$instance_id"`
    
    check_openapi_response $response
    if [[ $? -ne 0 ]]; then
        echo "checkMigrationStatus error: $response"
        return 1
    fi
    local instance_status=`echo $response |jq -r '.result.instance.migrationStatus'`
    echo $instance_status
    if [[ "$instance_status" == "$expect_status" ]]; then
        return 0
    fi
    return 2
}

function checkProxyDomain(){
    instance_id=$1
    pin_base64=`echo -n $pin | base64`
    local response=`curl -s -H"x-jdcloud-pin: $pin_base64"\
        -X GET --connect-timeout 5 --retry 2 \
        "$openapi_host/v2/regions/$region_id/instance/$instance_id"`
    check_openapi_response $response
    if [[ $? -ne 0 ]]; then
        echo "checkProxyDomain error: $response"
        return 1
    fi
    local proxyDomain=`echo $response |jq -r '.result.instance.proxyDomain'`
    if [[ "$proxyDomain" == "" ]]; then
        echo "invalid: proxy domain is empty"
        return 2
    fi
    return 0
}

function checkCurrentStepStatus(){
    instance_id=$1
    pin_base64=`echo -n $pin | base64`
    local response=`curl -s -H"x-jdcloud-pin: $pin_base64"\
        -X GET --connect-timeout 5 --retry 2 \
        "$openapi_host/v2/regions/$region_id/instance/$instance_id"`
    
    check_openapi_response $response
    if [[ $? -ne 0 ]]; then
        echo "checkCurrentStepStatus error: $response"
        return 1
    fi

    local currentStepStatus=`echo $response |jq -r '.result.instance.currentStepStatus'`
    echo "$currentStepStatus"
    if [[ "$currentStepStatus" == "success" ]]; then
        return 0
    elif [[ "$currentStepStatus" == "fail" ]]; then
        return 0
    fi
    return 2
}

function doAction(){
    instance_id=$1
    action=$2
    pin_base64=`echo -n $pin | base64`
    local response=`curl -s -H"x-jdcloud-pin: $pin_base64"\
        -X POST --connect-timeout 5 --retry 2 \
        "$openapi_host/v2/regions/$region_id/instance/$instance_id:$action" \
        `
    check_openapi_response $response
    if [[ $? -ne 0 ]]; then
        echo "do $action error: $response"
        return 1
    fi
}

function start(){
    doAction $1 start
    return $?
}

function migrate() {
    doAction $1 migrate
    return $?
}

function redirect() {
    doAction $1 redirect
    return $?
}

function goNextStep() {
	instance_id=$1
    current_step=$2
    pin_base64=`echo -n $pin | base64`
    local response=`curl -s -H"x-jdcloud-pin: $pin_base64"\
        -X POST --connect-timeout 5 --retry 2 \
        "$openapi_host/v2/regions/$region_id/instance/$instance_id:goNextStep" \
        -d "{
            \"currentStep\": \"$current_step\"
        }"`
    
    check_openapi_response $response
    if [[ $? -ne 0 ]]; then
        echo "goNextStep error: $response, current step: $current_step"
        return 1
    fi
    return 0
}

function gotoMigrate() {
    goNextStep $1 clientFlowInProxy
    return $?
}

function gotoRedirect() {
    goNextStep $1 migrateAndCheck
    return $?
}

function gotoTarget() {
    goNextStep $1 clientFlowRedirect
    return $?
}

function gotoComplete() {
    goNextStep $1 clientFlowInTarget
    return $?
}

function deleteMigration(){
    instance_id=$1
    pin_base64=`echo -n $pin | base64`
    local response=`curl -s -H"x-jdcloud-pin: $pin_base64"\
        -X DELETE --connect-timeout 5 --retry 2 \
        "$openapi_host/v2/regions/$region_id/instance/$instance_id"`
    
    check_openapi_response $response
    if [[ $? -ne 0 ]]; then
        echo "deleteMigration error: $response"
        return 1
    fi
}

function waitOK() {
    instance_id=$1
    status=$2
    for((i=1; i<=$max_retry;i++)); do
        checkMigrationStatus $instance_id $status
        ret=$?
        if [[ $ret -eq 0 ]];then
            return 0
        elif [[ $ret -eq 1 ]];then
            echo "waitOK error"
            return 1
        fi
        if [[ $i -eq $max_retry ]]; then
            echo "waitOK timeout"
            return 1
        fi
        echo "running..."
        sleep 10
    done
}

function waitValidated() {
    waitOK $1 "validated"
    return $?
}

function waitMigrate() {
    waitOK $1 "waitMigrate"
    return $?
}

function waitCurrentStepFinished() {
    instance_id=$1
    for((i=1; i<=$max_retry;i++)); do
        checkCurrentStepStatus $instance_id
        ret=$?
        if [[ $ret -eq 0 ]];then
            return 0
        elif [[ $ret -eq 1 ]];then
            echo "waitCurrentStepFinished error"
            return 1
        fi
        if [[ $i -eq $max_retry ]]; then
            echo "checkCurrentStepStatus timeout"
            return 1
        fi
        echo "running..."
        sleep 10
    done
}

function flushDB() {
    host=$1
    port=$1
    redis-cli -h $host -p $port flushall
    if [ $? == 0 ]; then
        echo "empty redis " $host " " $port "faile"
        return 1
    fi
    return 0
}

function fillDB() {
    host=$1
    port=$2
    data=$3
    aof=$4
    ./redis-migrator --protected-mode no --tcp-keepalive 300 --supervised no --loglevel notice --senderNum 24 --port 6888 --syncfrom 127.0.0.1 6400 "to" $host $port --rdbFile $data
    if [ $? == 0 ]; then
        echo "fill redis data " $host " " $port "faile"
        return 1
    fi
    return 0
}

function benchmark() {
    host=$1
    port=$2
    count=$3
    len=$[$RANDOM%200]
    concurrency=$[$RANDOM%20]
    if [[ $concurrency -lt 100 ]];then
        concurrency=100
    fi
    
    ./redis-benchmark -r $count -n $count -c $len -d $len -P 16 &
    if [ $? == 0 ]; then
        echo "start redis-benchmark " $host " " $port "faile"
        return 1
    fi
    return 0
}

# 1: prepare flushall source redis
#    flushall destination redis
#    fill data into source redis
flushDB  $src_url $src_port
if [[ $? -ne 0 ]];then
    echo_error "empty source redis error"
    exit 1
fi
echo "=====empty source redis called====="

flushDB  $tgt_url $tgt_port
if [[ $? -ne 0 ]];then
    echo_error "empty target redis error"
    exit 1
fi
echo "=====empty target redis called====="

fillDB  $src_url $src_port $rdb_path ""
if [[ $? -ne 0 ]];then
    echo_error "fill source redis rdb data error"
    exit 1
fi
echo "=====fill source redis rdb data called====="


instance_id=`createMigration`
if [[ $? -ne 0 ]];then
    echo_error "createMigration error"
    exit 1
fi
echo "=====createMigration called====="

waitValidated $instance_id
if [[ $? -ne 0 ]];then
    echo_error "waitValidated error"
    exit 1
fi
echo "=====createMigration ok====="


# 1: start
start $instance_id
if [[ $? -ne 0 ]];then
    echo_error "startMigration error"
    exit 1
fi
echo "=====startMigration called====="

waitMigrate $instance_id
if [[ $? -ne 0 ]];then
    echo_error "waitMigrate error"
    exit 1
fi
echo "=====waitMigrate ok====="

gotoMigrate $instance_id
if [[ $? -ne 0 ]];then
    echo_error "gotoMigrate error"
    exit 1
fi
echo "=====gotoMigrate ok====="


# 2: migrate
migrate $instance_id
if [[ $? -ne 0 ]];then
    echo_error "migrate error"
    exit 1
fi
echo "=====migrate called====="

fillDB  $src_url $src_port $rdb_path "--sendAof &"
if [[ $? -ne 0 ]];then
    echo_error "fill source redis aof data error"
    exit 1
fi
echo "=====fill source redis aof data called====="

benchmark  $src_url $src_port 1000000
if [[ $? -ne 0 ]];then
    echo_error "fill source redis benchmark data error"
    exit 1
fi

echo "=====fill source redis data called====="
waitCurrentStepFinished $instance_id
if [[ $? -ne 0 ]];then
    echo_error "waitCurrentStepFinished error"
    exit 1
fi
echo "=====migrate ok====="

gotoRedirect $instance_id
if [[ $? -ne 0 ]];then
    echo_error "gotoRedirect error"
    exit 1
fi
echo "=====gotoRedirect ok====="


# 3: redirect
redirect $instance_id
if [[ $? -ne 0 ]];then
    echo_error "redirect error"
    exit 1
fi
echo "=====redirect called====="

waitCurrentStepFinished $instance_id
if [[ $? -ne 0 ]];then
    echo_error "waitCurrentStepFinished error"
    exit 1
fi
echo "=====redirect ok====="

gotoTarget $instance_id
if [[ $? -ne 0 ]];then
    echo_error "gotoTarget error"
    exit 1
fi
echo "=====gotoTarget ok====="


# 4: complete
gotoComplete $instance_id
if [[ $? -ne 0 ]];then
    echo_error "gotoComplete error"
    exit 1
fi
echo "=====gotoComplete ok====="


# 5: delete
echo "=====deleteMigration start====="
deleteMigration $instance_id
if [[ $? -ne 0 ]];then
    echo_error "deleteMigration error"
    exit 1
fi
echo "=====deleteMigration ok====="

echo_ok
