
# Consul-Zeus

Consul-Zeus is a [Consul](https://www.consul.io) container with built in [Zeus](https://github.com/Elders/Zeus) checks for monitoring.

#### Arguments

Consul-Zeus provides a few extra arguments for configuring Zeus:
##### ZEUS_OPTIONS

Setting the env variable ZEUS_OPTIONS in the container will make consul pass those options to Zeus on every check:

###### Example:

Please not that due to the way that arguments are parssed all the white spaces are replaced with '+'. If you start the container with docker compose you can write all the arguments normally.

> docker run -e ZEUS_OPTIONS="machine+-e+cpu.usage:below:30+-f" --name consul eldersoss/consul-zeus:latest agent -server -bootstrap

Having "machine+-e+cpu.usage:below:30+-f" will make the consul check fail if the cpu usage is above 30%

> docker run -e ZEUS_OPTIONS="machine+-e+ram.free:above:2000+-f" --name consul eldersoss/consul-zeus:latest agent -server -bootstrap

Having "machine+-e+ram.free:above:2000+-f" will make the consul check fail if the free memory is below 2000MB

> docker run -e ZEUS_OPTIONS="machine+-e+ram.free:above:2000+cpu.usage:below:30+-f" --name consul eldersoss/consul-zeus:latest agent -server -bootstrap

Having ""machine+-e+ram.free:above:2000+cpu.usage:below:30+-" will make the consul check fail if either the memory is below 2000MB or the cpu usage is above 30%

For more assertions over the RAM and HDD you can check [Zeus Documentation](https://github.com/Elders/Zeus)

##### ZEUS_INTERVAL

Setting this variable will make consul execute zeus checks on specified interval. Please note that the default value for consul checks is 5 minutes. Setting up this bellow 5 minutes is not recommended becouse it will make Consul execute a lot of checks and it will result into a lot of data transfere between the Consul Cluster Nodes.

###### Example:

> docker run -e ZEUS_INTERVAL=10s --name consul eldersoss/consul-zeus:latest agent -server -bootstrap

Having ZEUS_INTERVAL=10s will make consul execute zeus check every 10 seconds.

> docker run -e ZEUS_INTERVAL=1m --name consul eldersoss/consul-zeus:latest agent -server -bootstrap

Having ZEUS_INTERVAL=10s will make consul execute zeus check every minute.

#### Quick runs

Due to the large number of ports beeing exposed here are several quick copy-paste solutions to run the container.

##### FIRST NODE/SINGLE NODE

Before using this please read the Consul Documentation about ["-boostrap"](https://www.consul.io/docs/agent/options.html#_bootstrap) or its possible to have data a **Cluster Outage**...

```
docker run -d -p 8500:8500 -p 8400:8400 -p 8300:8300/tcp -p 8301:8301 -p 8302:8302  -p 8300:8300/udp -p 8301:8301/udp -p 8302:8302/udp -p 8600:8600 -p 8600:8600/udp -e ZEUS_OPTIONS="machine+-e+cpu.usage:below:50+-f" --net=host --name consul eldersoss/consul-zeus:latest agent -node={UNIQUE CONSUL NODE/SERVER NAME} -ui -advertise={DOCKER HOST IP} -bootstrap -client={DOCKER HOST IP}
```
Executing this will open up all Consul ports and it will configure Zeus to fail if the CPU usage is above 50%. It will also enable the consul administration for you. You can check it at your {DOCKER HOST IP}:8500

Please NOTE that you have to change the following -> {UNIQUE CONSUL NODE/SERVER NAME} {DOCKER HOST IP} {DOCKER HOST IP} and the command should look like this:

```
docker run -d -p 8500:8500 -p 8400:8400 -p 8300:8300/tcp -p 8301:8301 -p 8302:8302  -p 8300:8300/udp -p 8301:8301/udp -p 8302:8302/udp -p 8600:8600 -p 8600:8600/udp -e ZEUS_OPTIONS="machine+-e+cpu.usage:below:50+-f" --net=host --name consul eldersoss/consul-zeus:latest agent -node=CASSANDRA-NODE-1 -ui -advertise=192.168.99.100 -bootstrap -client=192.168.99.100
```

##### SAFE JOINING NODE


```
docker run -p -d 8500:8500 -p 8400:8400 -p 8300:8300/tcp -p 8301:8301 -p 8302:8302  -p 8300:8300/udp -p 8301:8301/udp -p 8302:8302/udp -p 8600:8600 -p 8600:8600/udp -e ZEUS_OPTIONS="machine+-e+cpu.usage:below:50+-f" --net=host --name consul eldersoss/consul-zeus:latest agent -ui -node={UNIQUE CONSUL NODE/SERVER NAME} -advertise={DOCKER HOST IP} -retry-join={ANY CONSUL NODE IP} -bootstrap -client={DOCKER HOST IP} -bootstrap-expect=2
```
Executing this will open up all Consul ports and it will configure Zeus to fail if the CPU usage is above 50%. It will also join the Consul node into the cluster and it will enable the consul administration for you. You can check it at your {DOCKER HOST IP}:8500

Please note that your Consul node **will not start** until you have at least two members in the cluster, you can read more at ["-bootstrap-expect"](https://www.consul.io/docs/agent/options.html#_bootstrap_expect). And you have to also change the following -> {UNIQUE CONSUL NODE/SERVER NAME} {DOCKER HOST IP} {ANY CONSUL NODE IP} and the command should look like this:

```
docker run -p -d 8500:8500 -p 8400:8400 -p 8300:8300/tcp -p 8301:8301 -p 8302:8302  -p 8300:8300/udp -p 8301:8301/udp -p 8302:8302/udp -p 8600:8600 -p 8600:8600/udp -e ZEUS_OPTIONS="machine+-e+cpu.usage:below:50+-f" --net=host --name consul eldersoss/consul-zeus:latest agent -ui -node=CASSANDRA-NODE-2 -advertise=192.168.99.100 -retry-join=192.168.0.101 -bootstrap -client=192.168.99.100 -bootstrap-expect=2
```

##### READ MORE

Please note that those are pretty basic consul configurations, and they are not production ready. Please read the full [Consul](https://www.consul.io/docs/) and [Zeus](https://github.com/Elders/Zeus) Documentations so that you could have an optimal setup for your system.

