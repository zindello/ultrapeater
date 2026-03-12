# Ultrapeater

The UltraPeater is a 1W radio hat designed to sit on a LuckFox Ultra Pico, to be integrated mainly with MeshCore systems in Australia running pyMC_Repeater. It can be optioned with an E22 or an E22P radio.

More information at https://zindello.com.au/ultrapeater

## Why the Luckfox Pico Ultra?

The LuckFox Pico Ultra was chosen to keep a consistent platform between the Zindello Industries products and while not as powerful as it's similarly priced Lyra cousin, has more than enough processing power for pyMC_Repeater and runs a lower power footprint.

The software has been confirmed to work on both the cheaper "B" and regular variants.

## Getting started

Once you have purchased your UltraPeater and your LuckFox (AliExpress is often the best) you'll need to flash it with the LuckFox Ubuntu Image, instructions at the URL below:

Once flashed, you will need to login to your router and obtain the IP address of the LuckFox. The hostname will show up as "luckfox". Login via ssh, user: pico | password: luckfox

I suggest you change the password once logged in using the "passwd" command.

### IMPORTANT: USE THE UBUNTU IMAGE NOT THE BUILDROOT IMAGE

https://wiki.luckfox.com/Luckfox-Pico-Ultra/Flash-image

## Software Installation

Once logged in, download this repo to the pico home director

sudo apt install -y git && git clone https://github.com/zindello/ultrapeater.git

Change into the ultrapeater/scripts folder. There are four scripts to run. They need to be run with sudo

``` sudo bash 01-luckfox-system-config.sh ```

This script will:  
Disable the default RGB display GPIO configuation.  
Increase the tmpfs size to prevent systemctl errors.  
Disable a bunch of unneeded system services.  
Regenerate the ssh keys for the system.  
Disable a whole heap of unneeded services (These could probably be uninstalled). 
Disable NetworkManager (It's bloat and you don't need it anyway).  
Configure a static mac address for the device.  
Enable systemd-networkd (Much lighter network management option)
Reboot the system.

### NOTE: The system's IP address WILL change at this point and you will have to get the new address out of the router.

``` sudo bash 02-luckfox-system-update.sh ```

This script will:  
Update the apt caches.  
Update the system with the latest packages.  
Upgrade python to 3.10.  
Configure a GPIO group and set the permissions.  
Configure the GPIO pins for the correct functions needed for the UltraPeater.   

``` sudo bash 03-install-pymc-repeater.sh ```

This script will install pyMC_Repeater and setup the service.

``` sudo bash 04-install-pymc-console.sh ```

This script will install pyMC_Console (An alternative, more feature rich console, switchable via the UI)

Once the installation is complete, you can login to the pyMC Repeater console on https://<Your Ultrapeater IP>:5000/ and configure the system. In the "Board Setup" page, please select the UltraPeater board that matches your purchase.



