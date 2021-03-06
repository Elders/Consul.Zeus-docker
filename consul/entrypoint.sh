#!/bin/bash
set -e
# Note above that we run dumb-init as PID 1 in order to reap zombie processes
# as well as forward signals to all processes in its session. Normally, sh
# wouldn't do either of these functions so we'd leak zombies as well as do
# unclean termination of all our sub-processes.
# You can set CONSUL_BIND_INTERFACE to the name of the interface you'd like to
# bind to and this will look up the IP and pass the proper -bind= option along
# to Consul.
CONSUL_BIND=
if [ -n "$CONSUL_BIND_INTERFACE" ]; then
  CONSUL_BIND_ADDRESS=$(ip -o -4 addr list $CONSUL_BIND_INTERFACE | head -n1 | awk '{print $4}' | cut -d/ -f1)
  if [ -z "$CONSUL_BIND_ADDRESS" ]; then
    echo "Could not find IP for interface '$CONSUL_BIND_INTERFACE', exiting"
    exit 1
  fi

  CONSUL_BIND="-bind=$CONSUL_BIND_ADDRESS"
  echo "==> Found address '$CONSUL_BIND_ADDRESS' for interface '$CONSUL_BIND_INTERFACE', setting bind option..."
fi
# You can set CONSUL_CLIENT_INTERFACE to the name of the interface you'd like to
# bind client intefaces (HTTP, DNS, and RPC) to and this will look up the IP and
# pass the proper -client= option along to Consul.
CONSUL_CLIENT=
if [ -n "$CONSUL_CLIENT_INTERFACE" ]; then
  CONSUL_CLIENT_ADDRESS=$(ip -o -4 addr list $CONSUL_CLIENT_INTERFACE | head -n1 | awk '{print $4}' | cut -d/ -f1)
  if [ -z "$CONSUL_CLIENT_ADDRESS" ]; then
    echo "Could not find IP for interface '$CONSUL_CLIENT_INTERFACE', exiting"
    exit 1
  fi

  CONSUL_CLIENT="-client=$CONSUL_CLIENT_ADDRESS"
  echo "==> Found address '$CONSUL_CLIENT_ADDRESS' for interface '$CONSUL_CLIENT_INTERFACE', setting client option..."
fi
# CONSUL_DATA_DIR is exposed as a volume for possible persistent storage. The
# CONSUL_CONFIG_DIR isn't exposed as a volume but you can compose additional
# config files in there if you use this image as a base, or use CONSUL_LOCAL_CONFIG
# below.
CONSUL_DATA_DIR=./consul/data
CONSUL_CONFIG_DIR=./consul/config
# You can also set the CONSUL_LOCAL_CONFIG environemnt variable to pass some
# Consul configuration JSON without having to bind any volumes.
if [ -n "$CONSUL_LOCAL_CONFIG" ]; then
	echo "$CONSUL_LOCAL_CONFIG" > "$CONSUL_CONFIG_DIR/local.json"
fi
# If the user is trying to run Consul directly with some arguments, then
# pass them to Consul.

if [ "${1:0:1}" = '-' ]; then
    set -- ./consul/consul "$@"
fi
# Look for Consul subcommands.
echo "Client Binding: $CONSUL_BIND"

echo "Node name:" $HOST_HOSTNAME
if [ "$1" = 'agent' ]; then
    shift
    set -- ./consul/consul agent \
        -data-dir="$CONSUL_DATA_DIR" \
        -config-dir="$CONSUL_CONFIG_DIR" \
        $CONSUL_BIND \
        $CONSUL_CLIENT \
        "$@"
elif [ "$1" = 'version' ]; then
    # This needs a special case because there's no help output.
    set -- consul "$@"
elif consul --help "$1" 2>&1 | grep -q "consul $1"; then
    # We can't use the return code to check for the existence of a subcommand, so
    # we have to use grep to look for a pattern in the help output.
    set -- consul "$@"
fi
# If we are running Consul, make sure it executes as the proper user.

##Configure Zeus


if [ -z "$ZEUS_INTERVAL" ]; then
    echo ZEUS_INTERVAL not set. Setting default 5m...
    ZEUS_INTERVAL=5m
fi


if [ -z "$ZEUS_OPTIONS" ]; then
   echo ZEUS_OPTIONS not set
   echo Setting default \"machine -f\"...
   ZEUS_OPTIONS="machine -f"
   echo You could set zeus options with passing to docker -e ZEUS_OPTIONS=machine+-e+cpu.usage:above:30+-f replacing hte whitespaces with + because of the Docker parser
fi

AZURE_DISCOVERY="\"retry_join\": [\"provider=azure tag_name=$AZURE_TAG_NAME tag_value=$AZURE_TAG_VALUE tenant_id=$AZURE_TENANT_ID client_id=$AZURE_CLIENT_ID subscription_id=$AZURE_SUB_ID secret_access_key=$AZURE_SECRET\"],"
if [ -z "$AZURE_SUB_ID" ]; then
   echo AZURE_SUB_ID not set
   echo AZURE discovery mode not enabled
   AZURE_DISCOVERY=""
   echo You could enable azure discovery by setting docker -e AZURE_SUB_ID=xxx -e AZURE_TENANT_ID=xxx -e AZURE_CLIENT_ID=xxx -e AZURE_SECRET=xxx -e AZURE_TAG_NAME=xxx -e AZURE_TAG_VALUE=xxx 
   echo ALL azure parser SHOULD BE URL ENCODED
fi
echo OPTS $ZEUS_OPTIONS
delimiter='", "'
ZEUS_OPTIONS="${ZEUS_OPTIONS//+/$delimiter}"
cat > /var/consul/config/config.json <<EOF
{
	"data_dir": "data",
	"check_update_interval": "$ZEUS_INTERVAL",
	"ports": {
		"http": 8500
	},
  $AZURE_DISCOVERY
	"log_level": "ERR",
	"checks": [{
		"id": "sys-health",
		"name": "System Information",
		"args": ["/var/zeus/debian.8-x64/Zeus", "$ZEUS_OPTIONS"],
		"interval": "$ZEUS_INTERVAL",
		"timeout": "1m"
	}],
  "enable_script_checks": true
}
EOF

tail -n 100 /var/consul/config/config.json


echo RUNNING "$@"
exec "$@"
