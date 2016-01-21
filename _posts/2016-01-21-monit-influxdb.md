---
layout: post
title: "打造Linux监控系统——influxdb"
keywords: Linux, Centos, influxdb, 监控, 运维
description: "在基于RPM的Linux机器如Centos上如何安装、配置influxdb"
---

很多数据有很强的时间属性，除了大家熟知的交易数据，有些类型的数据更甚，比如路况信息、大气温度、股票价格，可以通称为时间序列数据库。简单说来，可以划分为两类：1. 定期采集的数据，如天气信息、网络流量等；2. 非定期采集的数据，如性能故障告警等。不难看出，时间序列数据库有其典型的特点：海量；一旦写入很少修改。这些特点决定了应该有比关系型数据库更好的办法，针对存储和查询进行优化。

[InfluxDB](https://influxdata.com/)是这样一个时间序列数据库，具有很高的写入和查询性能。除此之外，其查询语言与SQL比较接近，与collectd、grafana的无缝集成，是我们搭建监控系统时，选择InfluxDB作为数据库的原因。

### 1. 安装
注：本文的安装、配置以Centos(7.0)操作系统为例。当前版本是0.9.6.1，安装前请检查最新版本。

{% highlight bash%}
wget https://s3.amazonaws.com/influxdb/influxdb-0.9.6.1-1.x86_64.rpm
sudo yum localinstall influxdb-0.9.6.1-1.x86_64.rpm
{% endhighlight %}

不过国内访问amazon s3非常慢，可以尝试下面的方法，在/etc/yum.repos.d/目录下写入influxdb.repo文件：

{% highlight shell%}
cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

sudo yum install influxdb
{%endhighlight%}

安装完成后，通过`sudo systemctl start influxdb`命令启用，并通过`ps -ef | grep influxdb`检查是否启动成功。

# 2. 基本概念
把InfluxDB中与关系型数据库的基本概念做简单映射，有助于我们快速了解。

MySQL | |InfluxDB
---|--| ---
数据库(Database) | | Database，逻辑存储容器
表（table） | | measurement，度量。不过是无模式的
列（column） | | time，时间戳；fields，字段，无索引；tags，标记，有索引

看一组CPU使用率的数据，对InfluxDB中数据的组织结构有个初步的了解：

time | host | instance | type_instance | value
--|--|--|--|--
1453348962593165000 | host1.com | 0 |   cpu | idle |    0.01
1453348962593165000 | host1.com | 0 |   cpu | user |    99.99
1453348962593165000 | host2.com | 0 |   cpu | idle |    0.01
1453348962593165000 | host2.com | 0 |   cpu | user |    99.99
1453348952593132000 | host1.com | 0 |   cpu | idle |    1.01
1453348952593132000 | host2.com | 0 |   cpu | user |    98.99
1453348952593132000 | host1.com | 0 |   cpu | idle |    1.01
1453348952593132000 | host2.com | 0 |   cpu | user |    98.99

其中的列分为时间、tags（上面的value列）和fields（上面的host, instance, type_instance列）。tags和fields的区分主要在于，前者有索引，用于需要作为条件过滤的场景，而fields一般不需要作为过滤条件。

InfluxDB中还有些特有的概念，retention policy：数据的存储保存策略，用来定义保存多久，需要几个备份；series：有共同的measurement、rentention policy和tag set的一组数据。
为了更好的理解series的概念，可以想象把上面的数据画到线条图上，需要四个线条来表示：host1+cpu0的idle占用率；host1+cpu0的user占用率；host2+cpu0的idle占用率；host2+cpu1的user占用率。每个线条随时间变化，值也不同。这里的线条就是series的概念。

# 3. 命令行交互基本用法
在命令行输入`influx`，就会进入命令行交互界面：

{%highlight shell%}
[user@host ~]$ influx
Connected to http://localhost:8086 version 0.9.6.1
InfluxDB shell 0.9.6.1
> show databases;    // 列出数据库列表
name: databases
---------------
name
_internal
test
> use test            // 使用test数据库
Using database test
> show measurements;  // 显示所有表(measurements)
name: measurements
------------------
name
cpu_value

> select * from cpu_value; // 查询数据
name: cpu_value
---------------
time      host      instance  type  type_instance value
1453271836852592000 test.tongshijia.com 0   cpu user    70904

{%endhighlight%}

是不是很熟悉的感觉？由于关系型数据库的列在InfluxDB中有多个对应，所以插入的语句有所不同：

{%highlight shell%}
> INSERT cpu_value,host=host1.com,instance=0,type=cpu,type_instance=user value=0.11
{%endhighlight%}
第一个字符串"cpu_value"指measurement名称，紧跟的连续几个键值对表示tags，空格后面的键值对表示fields。

# 4. HTTP API基本用法
除了命令行，InfluxDB还提供了基本的HTTP API，默认的端口是8086。查询数据就是向`query`发送GET请求，指定数据库及查询语句：

{%highlight shell%}
curl -G 'http://hostname:8086/query' --data-urlencode "db=test" --data-urlencode "q=SELECT * FROM cpu_value"

{
    "results": [
        {
            "series": [
                {
                    "name": "cpu_value",
                    "columns": [
                        "time",
                        "host",
                        "instance",
                        "type",
                        "type_instance",
                        "value"
                    ],
                    "values": [
                        [
                            "2016-01-21T06:34:04.852122375Z",
                            "host1.com",
                            "0",
                            "cpu",
                            "user",
                            0.11
                        ]
                    ]
                }
            ]
        }
    ]
}
{%endhighlight%}

写入数据与之类似，向`/write` POST一条请求：
{%highlight shell%}
curl -i -X POST 'http://hostname:8086/write?db=test' --data-binary "cpu_value,host=host1.com,instance=0,type=cpu,type_instance=user value=1.01"

HTTP/1.1 204 No Content
Request-Id: 7b19347c-c00b-11e5-8328-000000000000
X-Influxdb-Version: 0.9.6.1
Date: Thu, 21 Jan 2016 06:52:04 GMT
{%endhighlight%}

当然也可以使用HTTP API进行DDL相关的操作，向`/query`发送GET请求即可：
{%highlight shell%}
# 创建数据库
curl -G 'http://hostname.com:8086/query' --data-urlencode="q=CREATE DATABASE test"
# 删除数据库
curl -G 'http://hostname.com:8086/query' --data-urlencode "q=DROP DATABASE test"
{%endhighlight%}


# 5. 配置
看到这里，希望你对InfluxDB数据库的基本组织结构有了一定的了解。对监控系统来说，还需要做一些配置才行。

1. 创建数据库，名称为`collectd`
2. 修改配置文件，在25826端口监听collectd采集的数据：
{%highlight shell%}
sudo vim /etc/influxdb/influxdb.conf
[collectd]
  enabled = true
  bind-address = ":25826"
  database = "collectd"
  retention-policy = ""
  batch-size = 5000
  batch-timeout = "10s"
  typesdb = "/usr/share/collectd/types.db"
{%endhighlight%}

安装及配置到此就可以了，InfluxDB已经就绪，随时准备接收数据。

> 本文是《打造Linux监控系统》的第一篇，接下来会介绍如何使用collectd采集性能数据，以及如何grafana搭建炫酷的Dashboard。