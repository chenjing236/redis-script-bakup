#!/bin/bash
Instance=$1

function benchmark() {
    ./redis-benchmark -h $Instance-proxy-nlb.jvessel-open-sh.jdcloud.com -n 1500000 -r 10000000 -d $1 -t $2 -c $3 -P $4 --threads 32
}

function test() {
    benchmark $1 $2 $3 $4 > 1.data
    cat 1.data | grep "requests per secon"
    cat 1.data | grep milliseconds | sed -r 's/%//g' | awk '{p=$1;t=$3; a[NR]=p;b[NR]=t} END{p90=0;p99=0;p999=0; printf("len a: %s ", length(a));for (i=length(a)-1;i>=0;i--) { if(a[i]<=99.9 && p999==0){p999=b[i];} if(a[i]<=99 && p99==0){p99=b[i];} if(a[i]<=90 && p90==0){p90=b[i]} } printf("tp90: %s, tp99: %s, tp999: %s\n", p90,p99,p999) }'
}

echo "*******pipe line***********"
echo "test -d 50 -t lrange_100 -c 60 -P 16"
test 50 get lrange_100 16
echo
echo "test -d 50 -t lrange_100 -c 150 -P 16"
test 50 lrange_100 150 16
echo
echo "test -d 50 -t lrange_100 -c 600 -P 16"
test 50 lrange_100 600 16

echo "************no pipe line**************"
echo "test -d 50 -t lrange_100 -c 60 -P 1"
test 50 lrange_100 60 1
echo
echo "test -d 50 -t lrange_100 -c 150 -P 1"
test 50 lrange_100 150 1
echo
echo "test -d 50 -t lrange_100 -c 600 -P 1"
test 50 lrange_100 600 1
echo


