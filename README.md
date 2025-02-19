# Collection of scripts to set up Raspbery Pi's for the home

(NB: this was not tested with PiHole v6)

Raspberry Pi's, and especially Raspberry Pi Zero's, are inexpensive computers that work well for some home automation and other experiments.

Or at least, if supply were still like in 2019, they'd be great. There are alternatives of course, but I selfishly haven't tried any of them because I have a stash of pi's.

Anyway, if anyone is looking to set up their tiny computer for home automation, this repository might help.

Complete video recordings are available at: https://youtube.com/playlist?list=PLW4t6juigJ6tPH3m6DsibJxMRQV5RwtHs


# What I've been using

Tools I need on my desktop or laptop:
- the *Raspberry Pi Imager* or any other flasher (Balena Etcher, for example)
- - this one lets me provision some default settings like my SSH key and the WiFi settings, keyboard layout _etc._;
- Windows doesn't have a good SSH program, so I'm using either *PuTTY* or *WSL* (the latter has my preference but it's a little more complicated to set up);
- macOS already has a good *Terminal* app for SSH;

The services I like to have at home are:
- an ad blocker that isn't intrusive and also works for my guests, like the *Pi-Hole*;
- an AirPlay receiver on my Hi-Fi speakers, like *Shairport Sync*;


# First time set up for your computer

First off, you need an SSH key on your local machine. Assuming you are using WSL on Windows, Terminal on macOS or whatever program you like on Linux, open it and run the following command:
```sh
cat ~/.ssh/id_ed25519.pub
```

^ If it displays something like `ssh-ed25519` and a bunch of characters, you're already set up and you can go ahead and flash the memory card, pasting this entire line in the "Enable SSH / Allow public-key authentication only" box in the Imager settings.

But if that command failed, you'll need to set it up before doing anything else. Try these commands one by one:
```sh
mkdir ~/.ssh
chmod 0700 ~/.ssh
ssh-keygen -t ed25519 -C "your.address@example.com"
cat ~/.ssh/id_ed25519.pub
```

The `ssh-keygen` tool will guide you through the key creation. If the defaults look fine, you can just hit Enter whenever they ask a question.

NB: The email address here doesn't really matter, it can be any identifier that is helpful for you down the line. It doesn't need to be a valid address, or even an email at all. Just type in anything that will remind you where this key is from, or even leave the example I'm showing here.

NB: Whether you choose a password or not is up to you, but if your computer is only used by you, and this is a home setup for experimentation, and unless you choose a password that you actually remember, then I'd suggest leaving the password empty. _However_, usually, you want passwords to be unique to each service; so if you are security-minded, feel free to make up a new password and save it with your other secrets.

Everything up until now has been the first time setup for your own computer. You only have to do it once.


# Hardware handling precautions

Be careful while handling these tiny unprotected electronics.

They won't hurt you, but you might break them.

Generally, try to touch only the plastic and the edges of everything. Try to avoid placing your fingers on metal parts and connectors, especially when the devices are powered on. Again, they won't hurt you but your fingers may bridge the gap between wires and that could short circuit the device, destroy its memory, _etc_.

Don't plug in or remove the memory card while the device is powered. If the system is in the middle of an operation, that might be enough to break your memory card. Instead, power down the device before adding or removing the memory card. I'm sure you can handle your camera more easily, but that's more expensive equipment than these cheap devices.

Raspberry Pi Zero especially, is sensitive to stuff being plugged in our out while it is in operation, and it might reboot just on principle. Try to get your screen, keyboard and whatnot plugged (or not) before powering on the Zero.

It's your choice whether you want to shut it down with an SSH command (`sudo shutdown now` then wait until the blinking light stops) or by unpluging the power cable, but either action needs to happen before changing the hardware configuration. The safest way is the SSH command followed by unplugging the cable.


# Flashing the microSD card for a Raspberry Pi (all except the Pico models)

_Flashing_ is what we call the process of erasing a flash drive (in this case a microSD card) and installing a new operating system on it (in this case the Raspberry OS).

_[Last verified with Raspberry Pi OS Lite (32-bit) released 2023-02-21 and (64-bit) released 2023-02-21]_

1. Place the memory card in the adapter, then the adapter in your computer;
2. Don't forget to configure the SSH and WiFi settings in the Imager tool before flashing;
3. Flash the memory card with the Imager/etcher tool of your choice;
4. Remove the memory card from the adapter and insert it into the (not powered) Raspberry Pi;
5. Power on the Raspberry Pi.

After a minute or two (the first boot sequence is a little longer than that), run this login command in your chosen terminal app:
```sh
ssh pi@raspberry
```

^ If you chose to protect your SSH key with a password, this is where you are asked for it.

When successful, the terminal should change its prompt, showing a welcome message, some basic system information and a new prompt like this:
```
pi@raspberry:~ $
```

# Initial Raspberry Pi setup

After the first boot and logging via SSH into the rpi, this is usually the sequence of actions I take to prepare the device.

Making sure that `sshd` is secure enough
```sh
sudo nano /etc/ssh/sshd_config
```

> `PubkeyAuthentication` should say `yes`

> `PermitRootLogin` should say `prohibit-password`

> `PasswordAuthentication` should say `no`

If you don't feel comfortable changing them, leave them as they are. A home setup doesn't necessarily need to be extra tight. This is just what I always check first.

Change the hostname in System settings
```sh
sudo raspi-config
```

^ To navigate this tool, use the TAB key to change fields and the ENTER key to validate your choices.

It's fine to keep the hostname as `raspberry`, unless you have several Raspberry Pi's on your network. Then you need a naming convention. I've been using something like "pihole-gr" or "rpiaudio-gr" with my initials because I tend to prepare others for family members as well.

When asked to reboot, accept.

You can also reboot at any time with
```sh
pi@pihole-gr:~ $ sudo reboot now
pi@pihole-gr:~ $ Connection to pihole-gr closed by remote host.
Connection to pihole-gr closed.
iot@desktop-gr:~$
```

After a minute or two, log back into the Raspberry Pi, making sure to use the new hostname
```sh
ssh pi@pihole-gr
```

Let's apply any system updates. For context, `apt` here represents a kind of App Store where there are several "sources", at least one of them being managed by the maintainers of the Linux flavour you are using (called a "distribution"), and possibly other additional sources for third-party apps you may add. The `apt update` command downloads the listing of apps that are available from all these sources, and `apt upgrade` applies them. Reboot to make sure any new kernels and other critical updates are loaded.
```sh
sudo apt update
sudo apt upgrade
sudo reboot now
```

You can also run `apt dist-upgrade` and `apt autoremove` just to be thourough, but a fresh install shouldn't need these last two commands.
```sh
sudo apt dist-upgrade
sudo apt autoremove
sudo reboot now
```

NB: If you know your Linux well, you can probably skip a lot of these reboots. But I am being cautious for this demonstration, so, lots of reboots.

I usually change the time server used to synchronize the clock
```sh
echo "FallbackNTP=time.google.com" | sudo tee -a /etc/systemd/timesyncd.conf
sudo systemctl restart systemd-timesyncd.service
timedatectl show-timesync | grep ServerName
```

Another default setting that I like to change is the Power Management, which stops the Wifi sometimes at inopportune times, and I usually need my RaspberryPi's to be awake at all times:
```sh
sudo nano /etc/rc.local
# add this line before the "exit 0": (without the # at the start)
#/sbin/iwconfig wlan0 power off
```

This is how the end of that file should look like now:
```
/sbin/iwconfig wlan0 power off
exit 0
```

Sometimes it helps to be able to see how the device is behaving and there are many tools for that, the best-known of which are `top` and `htop` and they come pre-installed. However, they don't provide much insight into the more constrained components of the Raspberry Pi, the slowest of which is the memory card. This is why I usually install `atop` and `iotop`, which are harder to read but more comprehensive in this regard. Unfortunately, `atop` comes pre equipped with a background service that archives the system's health every two minutes or so, which clogs up the disk, so I usually disable it.
```sh
sudo apt install atop iotop
sudo service atop stop
sudo systemctl disable atop.service
sudo find /var/log/atop -name "atop_*" -print -delete
```

If you need Docker to run some containers (which is what I do later in this guide), this is how I install it
```sh
sudo apt install docker.io docker-compose jq
sudo usermod -aG docker pi
```

If you need git (which some hat drivers do)
```sh
sudo apt install git
sudo git config --global pull.ff only
sudo git config --global init.defaultBranch main
```

The system is ready, let's do one last reboot
```sh
sudo reboot now
```


# Specifically for the PiHole

```sh
# prepare the space for the database files
sudo mkdir -p /home/pihole/volumes/etc-dnsmasq.d
sudo mkdir -p /home/pihole/volumes/etc-pihole

# copy/paste the contents of the docker-compose.pihole.yml file into docker-compose.yml
nano docker-compose.yml

# also make the necessary changes in the docker-compose.yml
# for example your hostname, preferred WEBPASSWORD, WEB_BIND_ADDR & FTLCONF_LOCAL_IPV4, etc.
# please refer to the PiHole's documentation

# the only setting in that file that isn't native is PIHOLE_PRIVACYLEVEL, and I scripted it below

# start the Docker containers (it may take a minute or two, except the first run which will be considerably longer)
docker-compose up -d

# or a one-liner, easier if you need to iterate a bunch of times
> docker-compose.yml && nano docker-compose.yml && docker-compose up --remove-orphans -d

# watch the logs (Ctrl+C to stop)
docker logs -f -t --tail 50 pihole1

# show the pihole versions
docker exec -it pihole1 pihole -v

# update the pihole privacy setting
docker exec -it pihole1 /bin/bash -c "[ \$(cat /etc/pihole/pihole-FTL.conf | grep PRIVACYLEVEL | wc -l) -eq 0 ] && echo "PRIVACYLEVEL=\$PIHOLE_PRIVACYLEVEL" >> /etc/pihole/pihole-FTL.conf || sed -i "s/.*PRIVACYLEVEL=.*/PRIVACYLEVEL=\$PIHOLE_PRIVACYLEVEL/g" /etc/pihole/pihole-FTL.conf"

# ask pihole to update its blocked domains
docker exec -it pihole1 pihole -g

# keep watch on the pihole's statistics (Ctrl+C to stop)
docker exec -it pihole1 pihole -c

# reset the entire pihole's config (to start over)
docker stop pihole1
sudo rm -R /home/pihole/volumes/etc-pihole/* /home/pihole/volumes/etc-dnsmasq.d/*
docker start pihole1
```
