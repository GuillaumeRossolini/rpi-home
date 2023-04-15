# Collection of scripts to set up Raspbery Pi's for the home

Raspberry Pi's, and especially Raspberry Pi Zero's, are inexpensive computers that work well for some home automation and other experiments.

Or at least, if supply were still like in 2019, they'd be great. There are alternatives of course, but I selfishly haven't tried any of them because I have a stash of pi's.

Anyway, if anyone is looking to set up their tiny computer for home automation, this repository might help.


# What I've been using

Tools I need on my desktop or laptop:
- the *Raspberry Pi Imager* or any other flasher (Balena Etcher, for example)
- - this one lets me provision some default settings like my SSH key and the WiFi settings, keyboard layout _etc._;
- Windows doesn't have a good SSH program, so I'm using either *PuTTY* or *WSL* (the latter has my preference but it's a little more complicated to set up);
- macOS already has a good *Terminal* app for SSH;

The services I like to have at home are:
- an ad blocker that isn't intrusive and also works for my guests, like the *Pi-Hole*;
- an AirPlay receiver on my Hi-Fi speakers, like *Shairport-Sync*;


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

It's your choice whether you want to shut it down with an SSH command (`sudo shutdown now` then wait until the blinking light stops) or by unpluging the power cable, but either action needs to happen before changing the hardware configuration. The safest of the two is the SSH way.


# Setting up a new Raspberry Pi (all except the Pico models)

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

^ To navigate this tool, use the TAB key to change fileds and the ENTER key to validate your choices.

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

Let's apply any system updates. For context, `apt` here represents a kind of App Store where there are several "sources", at least one of them being managed by the maintainers of the Linux flavour you are using (called a "distribution"), and possibly other additional sources for third-party apps you may add. The `apt update` command downloads the listing of apps that are available from all these sources, and `apt upgrade` applies them. Then run `apt dist-upgrade` and `apt autoremove` just to be thourough, but a fresh install shouldn't need these last two commands.
```sh
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo apt autoremove
```

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

# keep watch on the pihole's statistics (Ctr+C to stop)
docker exec -it pihole1 pihole -c

# reset the entire pihole's config (to start over)
docker stop pihole1
sudo rm -R /home/pihole/volumes/etc-pihole/* /home/pihole/volumes/etc-dnsmasq.d/*
docker start pihole1
```


# Troubleshooting

## WiFi

If the WiFi isn't working, try to plug in a keyboard and screen, using "pi" as a username and "raspberry" as the password (or whatever you set up in the Imager settings), then locate the WiFi config like this:
```sh
find /etc -name "wpa_supplicant.conf" -print 2>/dev/null
```
^ the file you want is probably under `/etc/wpa_supplicant/wpa_supplicant.conf`

Edit that file according to the WPA Supplicant documentation, which I won't repeat here.

Also, edit this file if you need to add more SSH keys:
```sh
nano ~/.ssh/authorized_keys
```

## SSH from your computer to the Pi

If the `ssh pi@raspberry` command fails, try checking the permissions on your SSH key:
```sh
iot@desktop-gr:~$ whoami
iot
iot@desktop-gr:~$ ls -alh ~/.ssh
total 24K
drwx------ 2 iot iot 4.0K Apr 15 13:56 .
drwxr-xr-x 3 iot iot 4.0K Apr 15 13:56 ..
-rw------- 1 iot iot  419 Jun 14  2021 id_ed25519
-rw-r--r-- 1 iot iot  108 Jun 14  2021 id_ed25519.pub
-rw------- 1 iot iot 4.8K Apr 14 13:06 known_hosts
```

What's important here are the `r`, `w` and `x` flags, as we call them, on most of the lines after the last command. Of course, my user is called `iot` but yours will be different (you can check that by calling the `whoami` command).

Context: this output represent _read_, _write_ and _execute_ system permissions for the file's owner, for its group and for everyone else, respectively. So `-rw-------` means that the user can _read_ & _write_ but nobody else can do anything, while `-rw-r--r--` means that everybody can _read_, but only the user can _write_ and nobody can _execute_. The two lines that start with `d` represent folders (directories), the single dot being the folder being listed and the double dot its parent folder.

If the output isn't exactly like I'm showing above (we are looking at the first and last columns, except for the line that reads `..` at the end), that's probably why `ssh` fails. You can repair your system like this:
```sh
chmod 0700 ~/.ssh
chmod 0600 ~/.ssh/id_ed25519
chmod 0644 ~/.ssh/id_ed25519.pub
chmod 0600 ~/.ssh/known_hosts
```

Context: These commands change the permission bits on the folder and files where `1` means e`x`ecute, `2` means `w`rite and `4` means `r`ead. They are written in octal notation (that's what the leading zero means) so the second number is for the user, the third for the group, and the last for everyone else. The idea here is that only the public key should be readable by everyone on the system, none of these files and folders can be modified by anyone other than their owner (they are really private), and none of these files are available for execution by anyone (because they aren't programs).

Crash course in modern cryptography (asymmetric encryption): Here, the `~/.ssh/id_ed25519` file without the `.pub` is your private key while `~/.ssh/id_ed25519.pub` is your public key; if you ever lose your public key, it can be recreated from this private key. Essentially, both keys can encrypt messages but only the private key has the ability to decrypt them. The private key is also the only one that can compute a digital signature for a message, although both keys can then assess that signature. The inner workings are mathematically complex and I won't pretend to understand them, much less explain them here. The public key is the one you can freely share, and that's the one that other systems can use to encrypt messages so that only you can open them (with your private key). That's why the `ssh-keygen` tool suggests creating a password for the private key. Generally speaking, the use cases for asymmetric cryptography are: either you want to send an encrypted message to an individual without anyone else being able to read it, or an individual wants to send a message that anyone can read while ensuring that they have a way to verify the source of the message and that it wasn't modified in transit. This is the technology used for most communications between automated systems. For example, every time you visit a web page or whenever you use Signal/WhatsApp, a variation of this is in play behind the scenes.

Other reasons why `ssh` might fail are:
* the Raspberry Pi is not available on the network: try again in a minute or two?
* you have installed more than one Raspberry Pi with the same hostname over time and your `ssh` program is now confused, but it's also giving you directions for how to fix this;
* the hostname <> IP address resolution failed: if you can plug a screen, try looking for the IP address towards the end of the boot sequence;
* your computer's programs are out of date.

```sh
iot@desktop-gr:~$ ssh pi@rpiaudio
ssh: Could not resolve hostname rpiaudio: Name or service not known
```
^ Here I typed the hostname wrong, there is no box called `rpiaudio` on my network, instead it's `rpiaudio-gr`.

In most cases, a good way to find the issue is to run the following command. It's very verbose but it often points out the issue (with some googling around):
```sh
ssh -vvv pi@raspberry
```


## Errors writing files on the system // broken MicroSD card

The type of memory cards used for Raspberry Pi boards is often very cheap and they break easily. They simply have a limited life span and they weren't built with robustness in mind, because they can be replaced cheaply. Sometimes they are even broken right out of the box. Other times you stored them somewhere and small tempretature or humidity changes broke them before you opened their box. Yet others work fine for a while, but then they fail at some point.

I find that broken memory cards tend to fail in the `apt update` or `apt upgrade` stages. Here is an example I got today:
```
Reading package lists... Error!
E: Encountered a section with no Package: header
E: Problem with MergeList /var/lib/dpkg/status
E: The package lists or status file could not be parsed or opened.
```

If you reboot the Raspberry Pi at that moment with a screen plugged in, you might observe a different boot sequence from the previous one, and this time it might say something about a "Kernel panic".

It's time to throw away this memory card and to try a new one. There is no repairing it.

Although, before you throw out your memory card, try flashing it again with a different adapter first, or a diferent computer.

Flash card life span is a good reason why we try to avoid writing log files when the system is running. We don't want the MicroSD card to break too fast. It's going to fail eventually, but writing files makes it happen much faster.

I've had PiHole running on the same MicroSD card for years now (I'm probably just lucky that the bad sectors are being avoided), but several cards have failed me out of the box in the last week. It seems unpredictable.



## Running some diagnostics

Check free disk space. A full disk is often the root cause of many issues. I can't tell you what to do if anything gets above 95% (`Use%` column with `dh`), you'll have to figure that out, but this is a good start.
```sh
df -h
sudo du -h --max-depth=0 /home /usr /var
sudo du -h --max-depth=1 /home /usr /var /run
sudo du -h --max-depth=3 /usr/local
```

Running any of the `*top` programs (Ctrl+C to exit)
```sh
top
htop
atop
sudo iotop
```

Check that Docker is running, which may possibly complain with some `WARNING` messages but it shouldn't bail with a message about the socket.
```sh
docker info

# or to automate it, try something like this (on two lines to make it more readable)
docker info --format "{{json .}}" \
  | jq -r "{Name, ServerVersion, KernelVersion, OperatingSystem, OSVersion, OSType, Architecture, Containers, ContainersRunning, Swarm}"
```

Check what Docker containers are running (also automatable with the `--format` parameter)
```sh
docker ps
docker ps --no-trunc
```
