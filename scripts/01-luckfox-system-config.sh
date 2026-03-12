#!/bin/bash

# Temp
LUCKFOX_FDT_DUMP_TXT=/tmp/.fdt_dump.txt
LUCKFOX_PIN_DIAGRAM_FILE=/tmp/.pin_diagram.txt
LUCKFOX_CHANGE_TXT=/tmp/.change.txt

# Overlay
LUCKFOX_DYNAMIC_DTS=/tmp/.overlay.dts
LUCKFOX_DYNAMIC_DTBO=/tmp/.overlay.dtbo
LUCKFOX_FDT_DTB=/tmp/.fdt.dtb
LUCKFOX_FDT_OVERLAY_DTS=/tmp/.fdt_overlay.dts
LUCKFOX_FDT_OVERLAY_DTBO=/tmp/.fdt_overlay.dtbo
LUCKFOX_FDT_HDR_DTB=/tmp/.fdt_header.dtb
LUCKFOX_FDT_HDR_OVERLAY_DTS=/tmp/.fdt_header_overlay.dts
LUCKFOX_FDT_HDR_OVERLAY_DTBO=/tmp/.fdt_header_overlay.dtbo

# Config
LUCKFOX_CFG_FILE=/etc/luckfox.cfg

function luckfox_sha256_convert() {
        local sha256_hash=$1
        local formatted_hash=""

        for ((i = 0; i < ${#sha256_hash}; i += 8)); do
                formatted_hash+="0x${sha256_hash:$i:8} "
        done

        echo "$formatted_hash"
}

function luckfox_set_pin_parameter() {
        local parameter_name="$1"
        local parameter_value="$2"

        if grep -q "$parameter_name=" "$LUCKFOX_PIN_DIAGRAM_FILE"; then
                sed -i "s/^$parameter_name=.*/$parameter_name=$parameter_value/" "$LUCKFOX_PIN_DIAGRAM_FILE"
        else
                echo "$parameter_name=$parameter_value" >>"$LUCKFOX_PIN_DIAGRAM_FILE"
        fi
}

function luckfox_get_pin_mode() {
        local input="$1"
        local flag

        IFS=' ' read -r -a phandle_values <<<"$input"
        for phandle_value in "${phandle_values[@]}"; do
                pins_value=$(grep -B1 "phandle = <$phandle_value>" "$LUCKFOX_FDT_DUMP_TXT" | grep "rockchip,pins" | sed -e 's/^.*<\(.*\)>.*$/\1/')

                if [ -n "$pins_value" ]; then
                        IFS=' ' read -r -a pins_array <<<"$pins_value"
                        for ((i = 0; i < ${#pins_array[@]}; i += 4)); do
                                gpio_bank_hex=${pins_array[i]}
                                gpio_num_hex=${pins_array[i + 1]}
                                gpio_mode_hex=${pins_array[i + 2]}

                                gpio_bank=$((gpio_bank_hex))
                                gpio_num=$((gpio_num_hex))
                                gpio_mode=$((gpio_mode_hex))

                                current_gpio_mode_raw="$(iomux "$gpio_bank" "$gpio_num")"
                                current_gpio_mode=$(echo "$current_gpio_mode_raw" | sed 's/.*= \([0-9]*\)/\1/')

                                if [ "$gpio_mode" == "$current_gpio_mode" ]; then
                                        flag=1
                                fi
                        done
                        echo "$flag"
                        return
                fi
        done

}

function luckfox_get_pinctrl_addr() {
        local pinctrl_node="$1"
        local search_num="$2"

        local phandle_value
        if [ -z "$search_num" ]; then
                search_num=3
        fi

        phandle_value=$(grep -A "$search_num" "$pinctrl_node {" $LUCKFOX_FDT_DUMP_TXT | grep 'phandle' | awk '{print $3}' | sed 's/[<>;]//g')
        echo "$phandle_value"
}

function luckfox_set_pin_mark() {
        local pin="$1"
        local action="$2"

        #if grep -o -q "*$pin" "$LUCKFOX_PIN_DIAGRAM_FILE" ; then
        #    return
        #fi

        if [ "$action" == 1 ]; then
                pin=$(echo "$pin" | tr -d ' ')
                sed -i "s/ \($pin\)/\*\1/" $LUCKFOX_PIN_DIAGRAM_FILE
        elif [ "$action" == 0 ]; then
                if [[ "$pin" == \** ]]; then
                        pin="${pin:1}"
                fi
                sed -i "s/\*\($pin\)/ \1/" $LUCKFOX_PIN_DIAGRAM_FILE
        fi
}

function luckfox_set_pin_mode() {
        #region
        local input="$1"
        local reset_action="$2"

        IFS=' ' read -r -a phandle_values <<<"$input"
        for phandle_value in "${phandle_values[@]}"; do
                pins_value=$(grep -B1 "phandle = <$phandle_value>" "$LUCKFOX_FDT_DUMP_TXT" | grep "rockchip,pins" | sed -e 's/^.*<\(.*\)>.*$/\1/')

                if [ -n "$pins_value" ]; then
                        IFS=' ' read -r -a pins_array <<<"$pins_value"
                        for ((i = 0; i < ${#pins_array[@]}; i += 4)); do
                                gpio_bank_hex=${pins_array[i]}
                                gpio_num_hex=${pins_array[i + 1]}
                                gpio_mode_hex=${pins_array[i + 2]}

                                gpio_bank=$((gpio_bank_hex))
                                gpio_num=$((gpio_num_hex))
                                gpio_mode=$((gpio_mode_hex))

                                if [ "$reset_action" == 1 ]; then
                                        iomux "$gpio_bank" "$gpio_num" 0
                                else
                                        iomux "$gpio_bank" "$gpio_num" "$gpio_mode"
                                fi
                        done
                fi
        done
        #endregion
}

function luckfox_fdt_overlay() {
        #region
        local fdt_content="$1"
        local fdt_dtb_size fdt_size fdt_size_hex fdt_hash_data

        echo "$fdt_content" >$LUCKFOX_FDT_OVERLAY_DTS
        # fdt overlay
        dtc -I dts -O dtb $LUCKFOX_FDT_OVERLAY_DTS -o $LUCKFOX_FDT_OVERLAY_DTBO

        fdtoverlay -i $LUCKFOX_FDT_DTB -o $LUCKFOX_FDT_DTB $LUCKFOX_FDT_OVERLAY_DTBO >/dev/null 2>&1
        fdt_dtb_size=$(ls -la $LUCKFOX_FDT_DTB | awk '{print $5}')

        kernel_offset=$(fdtdump $LUCKFOX_FDT_HDR_DTB | grep -A 2 "kernel {" | grep "data-position" | sed -n 's/.*<\(0x[0-9a-fA-F]*\)>.*/\1/p')
        fdt_offset=$(fdtdump $LUCKFOX_FDT_HDR_DTB | grep -A 2 "fdt {" | grep "data-position" | sed -n 's/.*<\(0x[0-9a-fA-F]*\)>.*/\1/p')

        kernel_offset_dec=$((kernel_offset))
        fdt_offset_dec=$((fdt_offset))
        result_dec=$((kernel_offset_dec - fdt_offset_dec))

        dd if=$LUCKFOX_FDT_DTB of=$LUCKFOX_CHIP_MEDIA bs=1 seek=2048 count="$fdt_dtb_size" >/dev/null 2>&1

        fdt_size=$(ls -la $LUCKFOX_FDT_DTB | awk '{print $5}')
        fdt_size_hex=$(printf "%x\n" "$fdt_size")
        fdt_hash_data=$(luckfox_sha256_convert "$(sha256sum $LUCKFOX_FDT_DTB | awk '{print $1}')")
        fdt_header_content="
/dts-v1/;
/plugin/;

&{/images/fdt}{
    data-size=<0x$fdt_size_hex>;
    hash{
        value=<$fdt_hash_data>;
    };
};
"
        echo "$fdt_header_content" >$LUCKFOX_FDT_HDR_OVERLAY_DTS
        dtc -I dts -O dtb $LUCKFOX_FDT_HDR_OVERLAY_DTS -o $LUCKFOX_FDT_HDR_OVERLAY_DTBO
        fdtoverlay -i $LUCKFOX_FDT_HDR_DTB -o $LUCKFOX_FDT_HDR_DTB $LUCKFOX_FDT_HDR_OVERLAY_DTBO >/dev/null 2>&1
        dd if=$LUCKFOX_FDT_HDR_DTB of=$LUCKFOX_CHIP_MEDIA bs=1 seek=0 count=2048 >/dev/null 2>&1
        #endregion
}

function luckfox_disable_rgb() {
        action=0
        local gpio0_phandle reset_gpio_action enable_gpio_action

        local pre_action

        pre_action=$(luckfox_get_pin_mode "$(luckfox_get_pinctrl_addr "lcd-pins")")
        # create fdt overlay content

        local rgb_action=disabled
        local cma_action=disabled


        # create fdt_content
        local fdt_content="
/dts-v1/;
/plugin/;

&{/syscon@ff000000/rgb}{
    status=\"$rgb_action\";
};

&{/panel}{
    status=\"$rgb_action\";
};

&{/reserved-memory/linux,cma}{
        status=\"$cma_action\";
};

"
        # Get GPIO0 phandle
        #gpio0_phandle=$(luckfox_get_pinctrl_addr  "gpio@ff380000" 11)

        local lcd_time_content="
/dts-v1/;
/plugin/;

&{/panel/display-timings/timing0}{
        clock-frequency = <$rgb_clk_hex>;
        hactive = <$rgb_h_hex>;
        vactive = <$rgb_v_hex>;
        hback-porch = <$rgb_hb_hex>;
        hfront-porch = <$rgb_hf_hex>;
        vback-porch = <$rgb_vb_hex>;
        vfront-porch = <$rgb_vf_hex>;
        hsync-len = <$rgb_h_len_hex>;
        vsync-len = <$rgb_v_len_hex>;
        hsync-active = <$rgb_h_active_hex>;
        vsync-active = <$rgb_v_active_hex>;
        de-active = <$rgb_de_active_hex>;
        pixelclk-active = <$rgb_pclk_active_hex>;
};
"

        # fdt overlay
        luckfox_fdt_overlay "$fdt_content"
        if [ "$action" == 1 ]; then
                luckfox_fdt_overlay "$lcd_time_content"
        elif [ "$action" == 0 ] && [ "$pre_action" == 1 ]; then
                luckfox_set_pin_mode "$(luckfox_get_pinctrl_addr "lcd-pins")" 1
        fi

        luckfox_set_pin_parameter "RGB_ENABLE" "$action"

        # set pins mark
        luckfox_set_pin_mark "GPIO1_D0" "$action"
        luckfox_set_pin_mark "GPIO1_D1" "$action"
        luckfox_set_pin_mark "GPIO1_C2" "$action"
        luckfox_set_pin_mark "GPIO1_C3" "$action"
        luckfox_set_pin_mark "GPIO1_C1" "$action"

        luckfox_set_pin_mark "GPIO1_C6" "$action"
        luckfox_set_pin_mark "GPIO2_A7" "$action"
        luckfox_set_pin_mark "GPIO2_A6" "$action"
        luckfox_set_pin_mark "GPIO1_D3" "$action"
        luckfox_set_pin_mark "GPIO1_C0" "$action"
        luckfox_set_pin_mark "GPIO1_D2" "$action"

        luckfox_set_pin_mark "GPIO1_C7" "$action"
        luckfox_set_pin_mark "GPIO2_B0" "$action"
        luckfox_set_pin_mark "GPIO2_B1" "$action"

        luckfox_set_pin_mark "GPIO1_C4" "$action"
        luckfox_set_pin_mark "GPIO1_C5" "$action"
        luckfox_set_pin_mark "GPIO2_A1" "$action"
        luckfox_set_pin_mark "GPIO2_A0" "$action"
        luckfox_set_pin_mark "GPIO2_A5" "$action"
        luckfox_set_pin_mark "GPIO2_A4" "$action"
        luckfox_set_pin_mark "GPIO2_A2" "$action"
        luckfox_set_pin_mark "GPIO2_A3" "$action"
        #endregion
}

luckfox_disable_rgb
echo "RGB_ENABLE=0" >> /etc/luckfox.cfg

echo "Increase the size of the tmpfs"
mount -o remount,size=32M /run
echo "tmpfs /run tmpfs rw,nodev,nosuid,size=32M 0 0" | tee -a /etc/fstab

echo "Regenerating SSH keys"
rm /etc/ssh/ssh_host_*
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub
chown root:root /etc/ssh/ssh_host_*
systemctl restart ssh

echo "Disable all the services that we're not going to need"
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.timer
systemctl mask apt-daily.service # try prevent daily updates
systemctl mask apt-daily-upgrade.service # try prevent daily updates
systemctl disable unattended-upgrades
systemctl disable smbd nmbd # samba services, can be enabled via menu
systemctl disable vsftpd.service
systemctl disable ModemManager.service
systemctl disable getty@tty1.service
systemctl disable acpid
systemctl disable acpid.socket
systemctl disable acpid.service
systemctl mask alsa-restore.service
systemctl disable alsa-restore.service
systemctl disable alsa-state.service
systemctl mask sound.target
systemctl disable sound.target
systemctl disable veritysetup.target
systemctl disable systemd-pstore.service

echo "Prepare the switch to networkd"
networkfile="/etc/systemd/network/10-wired.network"
mac="$(awk '/Serial/ {print $3}' /proc/cpuinfo | tail -c 11 | sed 's/^\(.*\)/a2\1/' | sed 's/\(..\)/\1:/g;s/:$//')"
cat << EOF > $networkfile
[Match]
Name=eth0
[Link]
MACAddress=$mac
[Network]
DHCP=yes
EOF

echo "#### NOTE IP AND SSH IDENTITY WILL CHANGE ON RESTART ####"

systemctl disable NetworkManager
systemctl disable NetworkManager-dispatcher
systemctl disable NetworkManager-wait-online
systemctl enable systemd-networkd

reboot