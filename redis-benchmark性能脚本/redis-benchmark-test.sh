#!/bin/bash
Instance=$1

function benchmark() {
    ./redis-benchmark -h $Instance-proxy-nlb.jvessel-open-sh.jdcloud.com -n 1500000 -r 10000000 -d $1 -t $2 -c $3 -P $4 --threads 32
}

function test() {
    benchmark $1 $2 $3 $4 > 1.data
    cat 1.data | grep "requests per secon"
    cat 1.data | grep milliseconds | sed -r 's/%//g' | awk '{p=$1;t=$3; a[NR]=p;b[NR]=t} END{p90=0;p99=0;p999=0; for (i=0;i<length(a);i++) { if(a[i]>=90 && p90==0){p90=b[i];} if(a[i]>=99&&p99==0){p99=b[i];} if(a[i]>=99.9&&p999==0){p999=b[i]} } printf("tp90: %s, tp99: %s, tp999: %s\n", p90,p99,p999) }'
}

echo "*******pipe line***********"
 echo "test -d 50 -t get -c 60 -P 16"
test 50 get 60 16
echo
echo "test -d 50 -t get -c 150 -P 16"
test 50 get 150 16
echo
echo "test -d 50 -t get -c 600 -P 16"
test 50 get 600 16
echo
echo "test -d 50 -t set -c 60 -P 16"
test 50 set 60 16
echo
echo "test -d 50 -t set -c 150 -P 16"
test 50 set 150 16
echo
echo "test -d 50 -t set -c 600 -P 16"
test 50 set 600 16
echo

echo "test -d 50 -t lpush -c 60 -P 16"
test 50 lpush 60 16
echo
echo "test -d 50 -t lpush -c 150 -P 16"
test 50 lpush 150 16
echo
echo "test -d 50 -t lpush -c 600 -P 16"
test 50 lpush 600 16
echo

echo "test -d 50 -t mset -c 60 -P 16"
test 50 mset 60 16
echo
echo "test -d 50 -t mset -c 150 -P 16"
test 50 mset 150 16
echo
echo "test -d 50 -t mset -c 600 -P 16"
test 50 mset 600 16
echo

echo "test -d 50 -t sadd -c 60 -P 16"
test 50 sadd 60 16
echo
echo "test -d 50 -t sadd -c 150 -P 16"
test 50 sadd 150 16
echo
echo "test -d 50 -t sadd -c 600 -P 16"
test 50 sadd 600 16
echo

echo "************no pipe line**************"
echo "test -d 50 -t get -c 60 -P 1"
test 50 get 60 1
echo
echo "test -d 50 -t get -c 150 -P 1"
test 50 get 150 1
echo
echo "test -d 50 -t get -c 600 -P 1"
test 50 get 600 1
echo

echo "test -d 50 -t set -c 60 -P 1"
test 50 set 60 1
echo
echo "test -d 50 -t set -c 150 -P 1"
test 50 set 150 1
echo
echo "test -d 50 -t set -c 600 -P 1"
test 50 set 600 1
echo

echo "test -d 50 -t lpush -c 60 -P 1"
test 50 lpush 60 1
echo
echo "test -d 50 -t lpush -c 150 -P 1"
test 50 lpush 150 1
echo "test -d 50 -t lpush -c 600 -P 1"
test 50 lpush 600 1
echo

echo "test -d 50 -t mset -c 60 -P 1"
test 50 mset 60 1
echo
echo "test -d 50 -t mset -c 150 -P 1"
test 50 mset 150 1
echo
echo "test -d 50 -t mset -c 600 -P 1"
test 50 mset 600 1
echo

echo "test -d 50 -t sadd -c 60 -P 1"
test 50 sadd 60 1
echo
echo "test -d 50 -t sadd -c 150 -P 1"
test 50 sadd 150 1
echo
echo "test -d 50 -t sadd -c 600 -P 1"
test 50 sadd 600 1
echo
