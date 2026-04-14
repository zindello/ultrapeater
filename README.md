# Ultrapeater

The UltraPeater is a 1W radio hat designed to sit on a LuckFox Ultra Pico, to be integrated mainly with MeshCore systems in Australia running pyMC_Repeater. It can be optioned with an E22 or an E22P radio.

More information at https://zindello.com.au/ultrapeater

## Why the Luckfox Pico Ultra?

The LuckFox Pico Ultra was chosen to keep a consistent platform between the Zindello Industries products and while not as powerful as it's similarly priced Lyra cousin, has more than enough processing power for pyMC_Repeater and runs a lower power footprint.

The software has been confirmed to work on both the cheaper "B" and regular variants.

## Getting started

Once you have purchased your UltraPeater and your LuckFox (AliExpress is often the best) you'll need to flash it with the LuckFox Ubuntu Image, instructions at the URL below:

Once flashed, you will need to login to your router and obtain the IP address of the LuckFox. The hostname will show up as "luckfox". Login via ssh, user: pico | password: luckfox.  

The IP address and ssh identity WILL change after you clone this repo and run the first script, so I suggest logging in with the following SSH options:

``` ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pico@<ip_to_device> ```

I suggest you change the password once logged in using the "passwd" command.

### IMPORTANT: USE THE UBUNTU IMAGE NOT THE BUILDROOT IMAGE

https://wiki.luckfox.com/Luckfox-Pico-Ultra/Flash-image

## Software Installation

Once logged in, download this repo to the pico home directory using the following command.

``` pico@luckfox:~$ git clone https://github.com/zindello/ultrapeater.git ```

There are four scripts to run. They need to be run with sudo

### Script 1 01-luckfox-system-config.sh

``` pico@luckfox:~$ sudo bash ultrapeater/scripts/01-luckfox-system-config.sh ```

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

This script will run relatively quickly, with a short pause during the ssk key regeneration.

### NOTE: The system's IP address WILL change at this point and you will have to get the new address out of the router.

### Script 2 02-luckfox-system-update.sh

``` pico@luckfox:~$ sudo bash ultrapeater/scripts/02-luckfox-system-update.sh ```

This script will: 
Prompt you to change the password for the "pico" user, then boot you out.  
On second run:  
Update the apt caches.  
Update the system with the latest packages.  
Upgrade python to 3.10.  
Configure a GPIO group and set the permissions.  
Configure the GPIO pins for the correct functions needed for the UltraPeater.  
Reboot the system

This script will take a little longer to run - it's updating all of the out of date packages on the LuckFox Ubuntu image.  

### Script 3 03-install-pymc-repeater.sh

``` pico@luckfox:~$ sudo bash ultrapeater/scripts/03-install-pymc-repeater.sh ```

This script will install pyMC_Repeater and setup the service.

This script will take the longest to run - it's installing off of the Python dependencies and building all of the parts that are needed to support pyMC_Repeater - you might want to make a coffee while this one runs.  

### DEPRECATED -- Script 4 04-install-pymc-console.sh

``` pico@luckfox:~$ sudo bash ultrapeater/scripts/04-install-pymc-console.sh ```

This script has now been deprecated. ONLY RUN IF YOU INSTALLED PRIOR TO 14/4/2026.  

Run once to upgrade to a version that supports the web updater from the web UI and then use the UI to update. Ensure you ALSO run the 99-01-fix-polkit-and-ota-update.sh script AS WELL if your install predates 14/4/2026 so that the web updates work.   

This script will install pyMC_Console (An alternative, more feature rich console, switchable via the UI).  

This script won't take long to run at all.  

### WIFI Config 05-setup-wireless.sh

``` pico@luckfox:~$ sudo bash ultrapeater/scripts/05-setup-wireless.sh ```

This script will allow you to configure the wifi on a device with it supported. It will install wpa_supplicant, configure a DHCP client on the wlan0 interface, scan that interface for available networks and prompt you to enter an SSID and a Passphrase to connect to that network.

## BUGFIX Scripts

### Polkit and Web Upgrade fix - 99-01-fix-polkit-and-ota-update.sh

This script fixes the service not restarting properly from the web UI, and also fixes the issue of OTA updates not working. Run this script to allow upgrading of pyMC Repeater from the web UI.

## Login

Once the installation is complete, you can login to the pyMC Repeater console on https://<Your Ultrapeater IP>:8000/ and configure the system. In the "Board Setup" page, please select the UltraPeater board that matches your purchase.



## Credit

Credit must go to @theshaun for his work he did on the Femto, a lot of these scripts have leaned heavily into the work that he did there, as well as a lot of the general work done by @RightUp and the team on pyMC_Repeater.


