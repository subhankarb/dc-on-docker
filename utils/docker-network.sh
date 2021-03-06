#! /usr/bin/env bash

# Docker picks the default network based on the network name
# in the alphabetical order.  We put this prefix to all the
# network names so that those networks won't to be picked
# as the default networks.
#
# https://github.com/docker/docker/issues/21741
net_prefix="znet"

# create fabric networks
create_fabric_networks()
{
	for i in {0..2}; do
		docker network inspect ${net_prefix}${i} > /dev/null
		if [ $? != 0 ]; then
			docker network create --internal \
				--subnet=172.16.${i}.0/24 \
				--gateway=172.16.${i}.254 ${net_prefix}${i}
		fi
	done
}

# create spine networks
create_spine_networks()
{
	for j in {1..2}; do
		for i in {1..2}; do
			docker network inspect ${net_prefix}${j}${i} > /dev/null
			if [ $? != 0 ]; then
				docker network create --internal \
					--subnet=172.16.${j}${i}.0/24 \
					--gateway=172.16.${j}${i}.254 \
					${net_prefix}${j}${i}
			fi
		done
	done
}

# create leaf networks
create_leaf_networks()
{
	for i in 30 31 40 41 50 51 60 61; do
		docker network inspect ${net_prefix}${i} > /dev/null
		if [ $? != 0 ]; then
			docker network create --internal \
				--subnet=172.16.${i}.0/24 \
				--gateway=172.16.${i}.254 \
				${net_prefix}${i}
		fi
	done
}

# connect fabric switch
connect_fabric_switches()
{
	docker inspect fab1 > /dev/null
	if [ $? = 0 ]; then
		docker network connect ${net_prefix}0 fab1
		docker network connect ${net_prefix}1 fab1
		docker network connect ${net_prefix}2 fab1
	fi
}

# connect servers to fabric networks
connect_servers_to_fabric_networks()
{
	for i in {1..2}; do
		docker inspect server${i} > /dev/null
		if [ $? = 0 ]; then
			docker network connect ${net_prefix}${i} server${i}
		fi
	done
}

# connect spine switches
connect_spine_switches()
{
	for i in {1..2}; do
		docker inspect spine${i} > /dev/null
		if [ $? = 0 ]; then
			docker network connect ${net_prefix}${i} spine${i}
			docker network connect ${net_prefix}${i}1 spine${i}
			docker network connect ${net_prefix}${i}2 spine${i}
		fi
	done
}

# connect servers to spine networks
connect_servers_to_spine_networks()
{
	for i in 11 12 21 22; do
		docker inspect server${i} > /dev/null
		if [ $? = 0 ]; then
			docker network connect ${net_prefix}${i} server${i}
		fi
	done
}

# connect leaf switches
connect_leaf_switches()
{
	for i in {1..2}; do
		docker inspect leaf${i} > /dev/null
		if [ $? = 0 ]; then
			docker network connect ${net_prefix}1${i} \
				leaf${i}
			docker network connect ${net_prefix}$(expr ${i} + 2)0 \
				leaf${i}
			docker network connect ${net_prefix}$(expr ${i} + 2)1 \
				leaf${i}
		fi
	done
	for i in {3..4}; do
		docker inspect leaf${i} > /dev/null
		if [ $? = 0 ]; then
			docker network connect ${net_prefix}2$(expr ${i} - 2) \
				leaf${i}
			docker network connect ${net_prefix}$(expr ${i} + 2)0 \
				leaf${i}
			docker network connect ${net_prefix}$(expr ${i} + 2)1 \
				leaf${i}
		fi
	done
}

# connect servers to leaf networks
connect_servers_to_leaf_networks()
{
	for i in 30 31 40 41 50 51 60 61; do
		docker inspect server${i} > /dev/null
		if [ $? = 0 ]; then
			docker network connect ${net_prefix}${i} server${i}
		fi
	done
}

# main
create_fabric_networks
create_spine_networks
create_leaf_networks
connect_fabric_switches
connect_spine_switches
connect_leaf_switches
connect_servers_to_fabric_networks
