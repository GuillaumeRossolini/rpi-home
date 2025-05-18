#!/bin/bash

# start from a freshly flashed SDCard
#   - it should have your SSH public key
#   - the WiFi should be working
#   - /etc/ssh/sshd_config should already have sane defaults

# the following is meant to be written interactively (line by line)
# and not to be ran as an unattended install

# change default hostname and reboot
sudo raspi-config
sudo reboot now

# apply system updates
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo apt autoremove
sudo reboot now

# change the default time server
echo "FallbackNTP=time.google.com" | sudo tee -a /etc/systemd/timesyncd.conf
sudo systemctl restart systemd-timesyncd.service
timedatectl show-timesync | grep ServerName
# ServerName=time.google.com

# disable power management, which stops the Wifi sometimes
sudo nano /etc/rc.local # this isn't working on bookworm
# add this line before the exit: (without the # at the start)
#/sbin/iwconfig wlan0 power off

# install some basic monitoring tools
sudo apt install -y btop

# if you need docker-compose
sudo apt install -y docker.io docker-compose jq
sudo usermod -aG docker pi
# ^ you won't be able to make full use until either and exit/reconnect or a reboot

# if you need git (which some hat drivers do)
sudo apt install -y git
sudo git config --global pull.ff only
sudo git config --global init.defaultBranch main

# one last reboot
sudo reboot now

# check that Docker is running
docker info

# if you want to automate it, try something like this
docker info --format "{{json .}}" \
  | jq -r "{Name, ServerVersion, KernelVersion, OperatingSystem, OSVersion, OSType, Architecture, Containers, ContainersRunning, Swarm}"

# specifically for the PiHole
sudo mkdir -p /home/pihole/volumes/etc-dnsmasq.d
sudo mkdir -p /home/pihole/volumes/etc-pihole

# copy the contents of the corresponding file here
nano docker-compose.yml

# start the Docker containers
docker-compose up -d

# or a one-liner, easier if you need to iterate a bunch if times
> docker-compose.yml && nano docker-compose.yml && docker-compose up --remove-orphans -d

# look at the logs (Ctrl+C to stop)
docker logs -f -t --tail 50 pihole1

# show the pihole versions
docker exec -it pihole1 pihole -v

# update the pihole privacy setting
docker exec -it pihole1 /bin/bash -c "[ \$(cat /etc/pihole/pihole-FTL.conf | grep PRIVACYLEVEL | wc -l) -eq 0 ] && echo "PRIVACYLEVEL=\$PIHOLE_PRIVACYLEVEL" >> /etc/pihole/pihole-FTL.conf || sed -i "s/.*PRIVACYLEVEL=.*/PRIVACYLEVEL=\$PIHOLE_PRIVACYLEVEL/g" /etc/pihole/pihole-FTL.conf"

# ask pihole to update its blocked domains
docker exec -it pihole1 pihole -g

# keep watch on the pihole's statistics (Ctr+C to stop)
docker exec -it pihole1 pihole -c

# reset the entire pihole's config (to start over)
docker stop pihole1
sudo rm -R /home/pihole/volumes/etc-pihole/* /home/pihole/volumes/etc-dnsmasq.d/*
docker start pihole1
