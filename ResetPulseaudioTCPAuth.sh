#!/bin/bash

temp_f="./wyoming-satellite/temp"
env_f="./wyoming-satellite/.env"
sip_f="./wyoming-satellite/satellite-ip"
container_name=smoochie-satellite


rm $env_f
rm $sip_f

echo "pulse_host_ip=$(ip -4 -o a| grep docker0 | awk '{print $4}' | cut -d/ -f1)" > $temp_f
touch $temp_f $env_f $sip_f

cat $temp_f

if cmp -s $env_f $temp_f; then
    printf 'The file "%s" is the same as "%s"\n' $env_f $temp_f  > /dev/null 2>&1
else
    echo "Detected changed docker host IP. Restarting stack."
    mv $temp_f $env_f
#    docker compose up -d --remove-orphans --force-recreate --build $container_name
    docker compose up -d --remove-orphans --force-recreate --build
fi

echo "Starting PulseAudio TCP Server..."
pulse_container_ip="$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name)"

echo $pulse_container_ip > $temp_f

if cmp -s $sip_f $temp_f; then
    printf 'The file "%s" is the same as "%s"\n' $env_f $temp_f  > /dev/null 2>&1
else
    echo "Detected changed $container_name IP. Reauthorizing and restarting PusleAudio TCP server."
    mv $temp_f $sip_f
    pactl unload-module module-native-protocol-tcp > /dev/null 2>&1
    pactl load-module module-native-protocol-tcp  port=34567 auth-ip-acl=$pulse_container_ip
fi

touch $temp_f
rm $temp_f


