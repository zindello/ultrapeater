# UltraPeater

> A 1W MeshCore repeater hat for the LuckFox Pico Ultra, powered by pyMC_Repeater.

The UltraPeater is designed to integrate with MeshCore systems running pyMC_Repeater. It can be optioned with an E22 or E22P radio. More information at [zindello.com.au/ultrapeater](https://zindello.com.au/ultrapeater).

---

## Why the LuckFox Pico Ultra?

The LuckFox Pico Ultra was chosen to keep a consistent platform across Zindello Industries products. While not as powerful as its similarly priced Lyra cousin, it has more than enough processing power for pyMC_Repeater and runs a lower power footprint. The software has been confirmed to work on both the cheaper "B" and regular variants.

---

## What You'll Need Before Starting

- The [UltraPeater board](https://zindello.com.au/ultrapeater)
- A LuckFox Pico Ultra (AliExpress is often the best source)
- A computer
- Your Wi-Fi network name (SSID) and password (only required if you have the Wi-Fi model)

---

## Step 1 — Flash the LuckFox

Flash your LuckFox with the **Ubuntu image** using the instructions at the link below.

> ⚠️ **IMPORTANT: Use the Ubuntu image, not the BuildRoot image.**

[https://wiki.luckfox.com/Luckfox-Pico-Ultra/Flash-image](https://wiki.luckfox.com/Luckfox-Pico-Ultra/Flash-image)

---

## Step 2 — Find the IP Address of Your LuckFox

Once flashed and powered on, the LuckFox will connect to your network via ethernet. You'll need its IP address to connect via SSH.

The easiest way to find it is through your **router's admin page**:

1. Open a web browser and go to your router's admin address. Common addresses are:
   - `http://192.168.1.1`
   - `http://192.168.0.1`
   - `http://10.0.0.1`
   - (Check the label on the back of your router if unsure)
2. Log in with your router's admin username and password (also usually on the router label).
3. Look for a section called **Connected Devices**, **DHCP Clients**, **Device List**, or similar.
4. Find the device named `luckfox` in the list — the IP address will be shown next to it.

> **Note:** The IP address and SSH identity will change after you run the first script. To avoid SSH warnings on reconnection, connect using the following options:
> ```bash
> ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null pico@<ip-address>
> ```

---

## Step 3 — Connect via SSH

Open a terminal on your computer and run:

```bash
ssh pico@<ip-address>
```

Replace `<ip-address>` with the IP you found in the previous step.

> **Windows users:** Windows 10 and 11 include SSH built into Command Prompt and PowerShell. Alternatively, you can use [PuTTY](https://www.putty.org/).

When prompted for a password, enter: `luckfox`

---

## Step 4 — Download and Run the Setup Scripts

Once logged in, download this repository to the home directory by running:

```bash
git clone https://github.com/zindello/ultrapeater.git
```

There are four scripts to run in order. All scripts must be run with `sudo`.

---

### Script 1 — System Configuration

```bash
sudo bash ultrapeater/scripts/01-luckfox-system-config.sh
```

This script will:

- Disable the default RGB display GPIO configuration
- Increase the tmpfs size to prevent systemctl errors
- Disable a number of unneeded system services
- Regenerate the SSH keys for the system
- Disable NetworkManager and enable systemd-networkd (a much lighter network management option)
- Configure a static MAC address for the device
- Reboot the system

This script runs relatively quickly, with a short pause during SSH key regeneration.

> ⚠️ **The system's IP address will change after this reboot.** You will need to find the new address in your router before reconnecting.

> When you log back in you will be prompted to change the password for the `pico` user. Once changed, you will be logged out and will need to log back in with your new password before continuing.

---

### Script 2 — System Update

```bash
sudo bash ultrapeater/scripts/02-luckfox-system-update.sh
```

This script will:

- Update the apt package cache
- Update the system with the latest packages
- Upgrade Python to 3.10
- Configure a GPIO group and set the correct permissions
- Configure the GPIO pins for the UltraPeater
- Reboot the system

This script will take a little longer to run as it updates all out-of-date packages on the LuckFox Ubuntu image.

---

### Script 3 — Install pyMC Repeater

```bash
sudo bash ultrapeater/scripts/03-install-pymc-repeater.sh
```

This script installs pyMC_Repeater and sets up the service.

This is the longest script to run — it installs all Python dependencies and builds everything needed to support pyMC_Repeater. You might want to make a coffee while this one runs.

---

### Script 4 — Install pyMC Console

```bash
sudo bash ultrapeater/scripts/04-install-pymc-console.sh
```

This script installs pyMC_Console, an alternative more feature-rich console switchable via the UI. This script won't take long to run at all.

---

## Step 5 — Configure Wi-Fi (Optional)

If your device supports Wi-Fi and you'd like to connect it to a wireless network, run:

```bash
sudo bash ultrapeater/scripts/05-setup-wireless.sh
```

This script will install wpa_supplicant, configure a DHCP client on the `wlan0` interface, scan for available networks, and prompt you to enter an SSID and passphrase.

---

## Step 6 — Access the Web Interface

Once installation is complete, open a web browser on any device connected to the same network and go to:

```
http://<ip-address>:8000/
```

You should see the UltraPeater web interface, where you can configure and monitor your MeshCore repeater. In the **Board Setup** page, select the UltraPeater board that matches your purchase.

---

## Updating

### pyMC Repeater

Updates can be performed directly from the web UI.

> ⚠️ **DEPRECATED — 10-update-pymc-repeater.sh**
> This script has been deprecated. Only run it if you installed prior to 14/4/2026. Run it once to upgrade to a version that supports the web updater, then use the UI to update going forward.

### pyMC Console

To update pyMC Console, simply run Script 4 again:

```bash
sudo bash ultrapeater/scripts/04-install-pymc-console.sh
```

---

## Troubleshooting

**I can't find the device in my router:**
- Try waiting a few more minutes and refreshing the router device list.
- Some routers take a while to show newly connected devices.
- Remember that the IP address changes after Script 1 runs — make sure you're looking for the updated address.

**The web interface won't load:**
- Make sure you're using `http://` not `https://`.
- Make sure you're on the same network as the UltraPeater.
- Make sure you're including `:8000` at the end of the address.
- Ensure all four scripts have completed successfully before attempting to access the interface.

---

## Credit

Credit goes to @theshaun for his work on the Femto — many of these scripts lean heavily on that foundation — as well as @RightUp and the team for their work on pyMC_Repeater.
