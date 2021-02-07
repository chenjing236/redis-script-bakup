import requests
import subprocess
import time
import json

from elasticsearch import Elasticsearch


JDCPerf_ip = "116.196.80.31"
JDCPerf_port = "8890"
test_ids = ['241866398400432', '262489904137888', '259029370454176', '297726607321680']
run_id = '125657742797968'
user = "jcloudiaas2"

es_url = "es-nlb-es-yo1pyysm63.jvessel-open-hb.jdcloud.com"
es_port = "9200"
es_indices = ["redis-benchmark-standard-8g-pip", "redis-benchmark-standard-8g", "redis-benchmark-cluster-64g-8-pip",
              "redis-benchmark-cluster-64g-8"]
last_date = ["2020-10-01", "2020-10-01", "2020-10-01", "2020-10-01"]


def find_and_write():
    for i in range(len(test_ids)):
        print('**********index is %s **********' % i)
        get_perf_history(test_ids[i], i)


def get_perf_history(test_id, test_id_index):
    url = 'http://' + JDCPerf_ip + ':' + JDCPerf_port + '/gethistorybyid?sortOrder=DESC&pageNumber=1&pageSize=10' \
          '&sortName=dotime&testid=%s' % test_id
    print('url is %s' % url)
    headers = {"Connection": "keep-alive", "accept": "application/json", "userName": user,
               "backdoorTime": get_unix_time_token()}
    r = requests.get(url, headers=headers, verify=True)
    response = r.json()
    for item in response['data']:
        get_perf_data_curl(item['testid'], item['testrunid'], test_id_index)


def get_unix_time_token():
    backdoorTime = str(int(time.time())) + '000'
    return backdoorTime


def get_perf_data(test_id):
    url = 'http://' + JDCPerf_ip + ':' + JDCPerf_port + '/queryBenchMarkStat'
    headers = {"Connection": "keep-alive", "accept": "application/json", "userName": user,
               "backdoorTime": get_unix_time_token(), "Content-Type": "application/json"}
    data = {"runId": run_id, "testId": test_id}
    r = requests.post(url, data=data, headers=headers, verify=True)
    print r.status_code
    print r.encoding
    print r.text


def get_perf_data_curl(test_id, run_id, test_id_index):
    cmd = 'curl "http://%s:%s/queryBenchMarkStat" -H "Connection: keep-alive" -H "backdoorTime: %s" -H "Accept: */*" ' \
          '-H "userName: %s" -H "Content-Type: application/json" -d \'{"runId":%s,"testId":%s}\'' % (JDCPerf_ip, JDCPerf_port, get_unix_time_token(), user, run_id, test_id)
    print('cmd is %s' % cmd)
    child = subprocess.call(cmd, shell=True)
    res = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
    results = json.loads(res.stdout.read())
    print(results['data']['totalList'][0]['time'])
    if (results['data']['totalList'][0]['time'] > last_date[test_id_index]):
        print("+++++++++++++True! run time is later then the write time+++++++++++++")
        write_es(results['data'], test_id_index)
    else:
        print("+++++++++++False! Do not need to write data+++++++++++++")


def write_es(data, test_id_index):
    es = Elasticsearch(hosts="http://%s:%s" % (es_url, es_port))
    body = data["totalList"]
    try:
        if not es.indices.exists(es_indices[test_id_index]):
            es.indices.create(index=es_indices[test_id_index], ignore=400)
        for i in body:
            es.index(index=es_indices[test_id_index], body=i)
    except Exception, e:
        print e


if __name__ == '__main__':
    find_and_write()

