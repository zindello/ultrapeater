To enable serial port access in U-Boot and the Linux kernel, source code
modifications are required, as the default ttyS2 pins conflict with those
used by the radio.

The U-Boot and Linux kernel images were built by cloning the [luckfox-pico](https://github.com/LuckfoxTECH/luckfox-pico)
repository and following [these](https://forums.luckfox.com/viewtopic.php?t=975) instructions.

Apply the [ttyS0.diff](ttyS0.diff) file to the luckfox-pico repository (e.g. `patch -p1 < ttyS0.patch`)
to change the default serial port from ttyS2 to ttyS0, then run the
`./build.sh uboot` and `./build.sh kernel` to generate the suitable images.


In case the above link explaining what changes are required is no longer valid,
here's a copy/paste of the appropriate entry that was followed:

```

The complete process is as follows

Modify ddrbin

1 Navigate to `$SDK/sysdrv/source/uboot/rkbin/tools`

Code: Select all

cd <SDK>/sysdrv/source/uboot/rkbin/tools 

2 Back up the default `.bin` file

Code: Select all

cp ../bin/rv11/rv1106_ddr_924MHz_v1.15.bin ../bin/rv11/rv1106_ddr_924MHz_v1.15.bin.bak

3 Modify `ddrbin_param.txt`

Code: Select all

uart id=4
uart iomux=1
uart baudrate=115200

4 Modify `ddr.bin`

Code: Select all

./ddrbin_tool rv1106 ddrbin_param.txt ../bin/rv11/rv1106_ddr_924MHz_v1.15.bin

5 Check if the modification was successful

Code: Select all

./ddrbin_tool rv1106 -g new_ddrbin_param.txt ../bin/rv11/rv1106_ddr_924MHz_v1.15.bin
cat new_ddrbin_param.txt


Modify U-Boot Device Tree

Edit `sysdrv/source/uboot/u-boot/arch/arm/dts/rv1106.dtsi`

Code: Select all

fiq_debugger: fiq-debugger {
	compatible = "rockchip,fiq-debugger";
	rockchip,serial-id = <4>;
	rockchip,wake-irq = <0>;
	rockchip,irq-mode-enable = <0>;
	rockchip,baudrate = <115200>;	/* Only 115200 and 1500000 */
	interrupts = <GIC_SPI 125 IRQ_TYPE_LEVEL_HIGH>;
	status = "disabled";
};

uart4: serial@ff4e0000 {
	compatible = "rockchip,rv1106-uart", "snps,dw-apb-uart";
	reg = <0xff4e0000 0x100>;
	interrupts = <GIC_SPI 29 IRQ_TYPE_LEVEL_HIGH>;
	reg-shift = <2>;
	reg-io-width = <4>;
	dmas = <&dmac 15>, <&dmac 14>;
	clock-frequency = <24000000>;
	clocks = <&cru SCLK_UART4>, <&cru PCLK_UART4>;
	clock-names = "baudclk", "apb_pclk";
	pinctrl-names = "default";
	pinctrl-0 = <&uart4m1_xfer>;
	status = "disabled";
};

Edit `sysdrv/source/uboot/u-boot/arch/arm/dts/rv1106-u-boot.dtsi`

Code: Select all

	chosen {
		stdout-path = &uart4;
		u-boot,spl-boot-order = &sdmmc, &spi_nand, &emmc;
	};

Modify Kernel Device Tree

Edit the corresponding model’s DTS file (located in `$SDK/sysdrv/source/kernel/arch/arm/boot/dts`)

Code: Select all

&fiq_debugger {
	rockchip,serial-id = <4>;
	rockchip,baudrate = <115200>;
	rockchip,irq-mode-enable = <1>;
	status = "okay";
};

&rgb {
	status = "disabled";
};

&uart4 {
	status = "disabled";
	pinctrl-names = "default";
	pinctrl-0 = <&uart4m1_xfer>;
};

```
