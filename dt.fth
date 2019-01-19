\ Update the Device Tree to what mainline Linux expects
\
\ Copyright (C) 2019 Lubomir Rintel
\ Licensed under the same terms as OpenFirmware

\ include/dt-bindings/gpio/gpio.h
0 constant GPIO_ACTIVE_HIGH
1 constant GPIO_ACTIVE_LOW
6 constant GPIO_OPEN_DRAIN

\ include/dt-bindings/clock/marvell,mmp2.h
d#  60 constant MMP2_CLK_TWSI0
d#  61 constant MMP2_CLK_TWSI1
d#  63 constant MMP2_CLK_TWSI3
d#  65 constant MMP2_CLK_TWSI5
d#  66 constant MMP2_CLK_GPIO
d#  68 constant MMP2_CLK_RTC
d#  73 constant MMP2_CLK_UART0
d#  74 constant MMP2_CLK_UART1
d#  75 constant MMP2_CLK_UART2
d#  76 constant MMP2_CLK_UART3
d#  77 constant MMP2_CLK_SSP0
d#  78 constant MMP2_CLK_SSP1
d#  79 constant MMP2_CLK_SSP2
d#  81 constant MMP2_CLK_TIMER
d# 106 constant MMP2_CLK_DISP0
d# 101 constant MMP2_CLK_SDH0
d# 102 constant MMP2_CLK_SDH1
d# 103 constant MMP2_CLK_SDH2
d# 104 constant MMP2_CLK_SDH3
d# 105 constant MMP2_CLK_USB
d# 112 constant MMP2_CLK_CCIC0
d# 120 constant MMP2_CLK_SP

\ include/dt-bindings/input/linux-event-codes.h
5 constant EV_SW
0 constant SW_LID
1 constant SW_TABLET_MODE
2 constant SW_HEADPHONE_INSERT
4 constant SW_MICROPHONE_INSERT

\ include/dt-bindings/interrupt-controller/irq.h
2 constant IRQ_TYPE_EDGE_FALLING

\ DT patches

: replace-clocks ( clock -- )
    " clocks" delete-property
    " /clocks" encode-phandle  ( clock addr len )
    rot			       ( addr len clock )
    encode-int encode+
    " clocks" property
;

" dev /" evaluate
    \ Be able to boot a generic MMP2 kernel.
    " mrvl,mmp2" +compatible

    \ If this is absent, the kernel disables the L2 cache. Sad.
    new-device
        " l2-cache" device-name
        " marvell,tauros2-cache" +compatible
        3 " marvell,tauros2-cache-features" integer-property
    finish-device

    new-device
        " clocks" device-name
        " marvell,mmp2-clock" +compatible

        h# d4050000 encode-int          h# 1000 encode-int encode+
        h# d4282800 encode-int encode+  h#  400 encode-int encode+
        h# d4015000 encode-int encode+  h# 1000 encode-int encode+
        " reg" property

        " mpmu" encode-string
        " apmu" encode-string encode+
        " apbc" encode-string encode+
        " reg-names" property

        1 " #clock-cells" integer-property
        1 " #reset-cells" integer-property

        MMP2_CLK_SP " protected-clocks" integer-property
    finish-device

    new-device
        " fixedregulator0" device-name
        " regulator-fixed" +compatible
        " wlan" " regulator-name" string-property
        d# 3300000 " regulator-min-microvolt" integer-property
        d# 3300000 " regulator-max-microvolt" integer-property
        0 0 encode-bytes " enable-active-high" property

        " /gpio@d4019000" encode-phandle
        d# 34 encode-int encode+
        d# 0 encode-int encode+
        " gpio" property
    finish-device

    new-device
        " pwrseq0" device-name
        " mmc-pwrseq-sd8787" +compatible

        " /gpio@d4019000" encode-phandle
        d# 57 encode-int encode+
        d# 0 encode-int encode+
        " powerdown-gpios" property

        " /gpio@d4019000" encode-phandle
        d# 58 encode-int encode+
        d# 0 encode-int encode+
        " reset-gpios" property
    finish-device

    new-device
        " gpio-keys" device-name
        " gpio-keys" +compatible

        new-device
            " lid" device-name
            " Lid" " label" string-property
            EV_SW " linux,input-type" integer-property
            SW_LID " linux,code" integer-property
            0 0 encode-bytes " wakeup-source" property

            " /gpio@d4019000" encode-phandle
            d# 129 encode-int encode+
            GPIO_ACTIVE_LOW encode-int encode+
            " gpios" property
        finish-device

        new-device
            " tablet_mode" device-name
            " E-Book Mode" " label" string-property
            EV_SW " linux,input-type" integer-property
            SW_TABLET_MODE " linux,code" integer-property
            0 0 encode-bytes " wakeup-source" property

            " /gpio@d4019000" encode-phandle
            d# 128 encode-int encode+
            GPIO_ACTIVE_LOW encode-int encode+
            " gpios" property
        finish-device

        new-device
            " microphone_insert" device-name
            " Microphone Plug" " label" string-property
            EV_SW " linux,input-type" integer-property
            SW_MICROPHONE_INSERT " linux,code" integer-property
            d# 100 " debounce-interval" integer-property
            0 0 encode-bytes " wakeup-source" property

            " /gpio@d4019000" encode-phandle
            d# 96 encode-int encode+
            GPIO_ACTIVE_HIGH encode-int encode+
            " gpios" property
        finish-device

        new-device
            " headphone_insert" device-name
            " Headphone Plug" " label" string-property
            EV_SW " linux,input-type" integer-property
            SW_HEADPHONE_INSERT " linux,code" integer-property
            d# 100 " debounce-interval" integer-property
            0 0 encode-bytes " wakeup-source" property

            " /gpio@d4019000" encode-phandle
            d# 97 encode-int encode+
            GPIO_ACTIVE_HIGH encode-int encode+
            " gpios" property
        finish-device
    finish-device
device-end

\ early_init_dt_scan_nodes() won't be able to find a memory node without
\ this and the boot will fail very early
" dev /memory@0" evaluate
    " memory" " device_type" string-property
device-end

" dev /interrupt-controller@d4282000" evaluate
    " simple-bus" +compatible
    1 " #address-cells" integer-property
    1 " #size-cells" integer-property
    0 0 encode-bytes " ranges" property
device-end

" dev /usb2-phy@d4207000" evaluate
    " marvell,mmp2-usb-phy" +compatible
    0 " #phy-cells" integer-property
device-end

" dev /usb@d4208000" evaluate
    MMP2_CLK_USB replace-clocks
    " clock-names" delete-property
    " USBCLK" " clock-names" string-property
    " /usb2-phy@d4207000" encode-phandle " phys" property
    " usb" " phy-names" string-property
device-end

" dev /sdhci@d4280000" evaluate
    MMP2_CLK_SDH0 replace-clocks
    " clock-names" delete-property
    " io" " clock-names" string-property
    d# 50000000 " clock-frequency" integer-property
    d# 31 " mrvl,clk-delay-cycles" integer-property
    0 0 encode-bytes " broken-cd" property
device-end


" dev /sdhci@d4280800" evaluate
    MMP2_CLK_SDH1 replace-clocks
    " clock-names" delete-property
    " bus-width" delete-property
    " io" " clock-names" string-property
    d# 50000000 " clock-frequency" integer-property
    0 0 encode-bytes " no-1-8-v" property
    d# 4 " bus-width" integer-property
    0 0 encode-bytes " wakeup-source" property
    0 0 encode-bytes " keep-power-in-suspend" property
    " /fixedregulator0" encode-phandle " vmmc-supply" property
    " /pwrseq0" encode-phandle " mmc-pwrseq" property
device-end

" dev /sdhci@d4281000" evaluate
    MMP2_CLK_SDH2 replace-clocks
    " clock-names" delete-property
    " io" " clock-names" string-property
    d# 50000000 " clock-frequency" integer-property
    d# 31 " mrvl,clk-delay-cycles" integer-property
    0 0 encode-bytes " no-1-8-v" property
device-end

" dev /ap-sp@d4290000" evaluate
    MMP2_CLK_SP replace-clocks
    " clock-names" delete-property
    " sp" " clock-names" string-property
device-end

" dev /gpio@d4019000" evaluate
    MMP2_CLK_GPIO replace-clocks
    " marvell,mmp2-gpio" +compatible
    0 0 encode-bytes " ranges" property
    " #interrupt-cells" delete-property
    2 " #interrupt-cells" integer-property
device-end

" dev /flash@d4035000" evaluate
    MMP2_CLK_SSP0 replace-clocks
    " marvell,mmp2-ssp" +compatible
device-end

" dev /ec-spi@d4037000" evaluate
    MMP2_CLK_SSP2 replace-clocks
    " marvell,mmp2-ssp" +compatible
    0 0 encode-bytes " spi-slave" property

    " /gpio@d4019000" encode-phandle
    d# 125 encode-int encode+
    d# 0 encode-int encode+
    " ready-gpios" property

    new-device
        " slave" device-name
        " olpc,xo1.75-ec" +compatible
        0 0 encode-bytes " spi-cpha" property

        " /gpio@d4019000" encode-phandle
        d# 155 encode-int encode+
        d# 0 encode-int encode+
        " cmd-gpios" property
    finish-device
device-end

" dev /flash@d4035000/dropins@20000" evaluate
    \ spi_master spi0: cannot find modalias for /flash@d4035000/dropins@20000
    " disabled" " status" string-property
device-end

" dev /timer@d4014000"      evaluate MMP2_CLK_TIMER replace-clocks device-end
" dev /uart@d4030000"       evaluate MMP2_CLK_UART0 replace-clocks device-end
" dev /uart@d4017000"       evaluate MMP2_CLK_UART1 replace-clocks device-end
" dev /uart@d4018000"       evaluate MMP2_CLK_UART2 replace-clocks device-end
" dev /uart@d4016000"       evaluate MMP2_CLK_UART3 replace-clocks device-end
" dev /i2c@d4011000"        evaluate MMP2_CLK_TWSI0 replace-clocks device-end
" dev /i2c@d4031000"        evaluate MMP2_CLK_TWSI1 replace-clocks device-end
" dev /i2c@d4033000"        evaluate MMP2_CLK_TWSI3 replace-clocks device-end
" dev /i2c@d4034000"        evaluate MMP2_CLK_TWSI5 replace-clocks device-end
" dev /wakeup-rtc@d4010000" evaluate MMP2_CLK_RTC   replace-clocks device-end

\ FIXME
" dev /audio@d42a0c00" evaluate " clocks" delete-property device-end
" dev /sspa@d42a0d00"  evaluate " clocks" delete-property device-end
" dev /vmeta@f0400000" evaluate " clocks" delete-property device-end

" dev /i2c@d4031000/rtc@68" evaluate " dallas,ds1338"       +compatible device-end
" dev /battery@0"           evaluate " olpc,xo1.5-battery"  +compatible device-end
" dev /i2c@d4034000/accelerometer" evaluate " st,lis3lv02d" +compatible device-end

\ The simple-framebuffer node describes the frame buffer set up by the
\ firmware so that the kernel is able to use it before it loads the
\ real display driver.

" /display@d420b000" select-dev
    \ Load some values from the real display device first
    vdisp
    hdisp
    fb-mem-va
unselect

" dev /chosen" evaluate
    1 " #address-cells" integer-property
    1 " #size-cells" integer-property
    0 0 encode-bytes " ranges" property

    new-device
        " framebuffer" device-name
        " simple-framebuffer" +compatible

        >physical  encode-int
        2over * 2 *  encode-int encode+
        " reg" property

        2dup
        " width" integer-property
        " height" integer-property

        2 * " stride" integer-property
        drop

        " r5g6b5" " format" string-property
        " /display@d420b000" encode-phandle " display" property
        MMP2_CLK_DISP0 replace-clocks
    finish-device
device-end

\ DRM

" dev /display@d420b000" evaluate
    " marvell,mmp2-lcd" +compatible
    MMP2_CLK_DISP0 replace-clocks
    " clock-names" delete-property
    " axiclk" " clock-names" string-property

    new-device
        " port" device-name
        new-device
            " endpoint" device-name
            d# 18 " bus-width" integer-property
        finish-device
    finish-device
device-end

" dev /dcon-i2c/dcon@d" evaluate
    " himax,hx8837" +compatible

    h# 0d " reg" integer-property

    " /gpio@d4019000" encode-phandle
    d# 100 encode-int encode+
    d# 0 encode-int encode+
    " /gpio@d4019000" encode-phandle encode+
    d# 101 encode-int encode+
    d# 0 encode-int encode+
    " stat-gpios" property

    " /gpio@d4019000" encode-phandle
    d# 142 encode-int encode+
    d# 0 encode-int encode+
    " load-gpios" property

    " /gpio@d4019000" encode-phandle " interrupt-parent" property

    d# 124 encode-int
    IRQ_TYPE_EDGE_FALLING encode-int encode+
    " interrupts" property

    new-device
        " ports" device-name
        1 " #address-cells" integer-property
        0 " #size-cells" integer-property

	: decode-unit  ( adr len -- phys )  $number  if  0  then  ;
	: encode-unit  ( phys -- adr len )  (u.)  ;
	: open  ( -- true )  true  ;
	: close  ( -- )  ;

        new-device
            " port" device-name
            0 " reg" integer-property
            new-device
                " endpoint" device-name
                " /display@d420b000/port/endpoint" encode-phandle " remote-endpoint" property
            finish-device
        finish-device

        new-device
            " port" device-name
            1 " reg" integer-property
            new-device
                " endpoint" device-name
            finish-device
        finish-device
    finish-device
device-end

" dev /" evaluate
    new-device
        " panel" device-name
        " simple-panel" +compatible
        " innolux,ls075at011" +compatible

         new-device
             " port" device-name
             new-device
                 " endpoint" device-name
                 " /dcon-i2c/dcon@d/ports/port@1/endpoint" encode-phandle " remote-endpoint" property
             finish-device
         finish-device
     finish-device
device-end

" dev /dcon-i2c/dcon@d/ports/port@1/endpoint" evaluate
    " /panel/port/endpoint" encode-phandle " remote-endpoint" property
device-end

" dev /display@d420b000/port/endpoint" evaluate
    " /dcon-i2c/dcon@d/ports/port@0/endpoint" encode-phandle " remote-endpoint" property
device-end

" dev /" evaluate
    new-device
        " reserved-memory" device-name
        1 " #address-cells" integer-property
        1 " #size-cells" integer-property
        0 0 encode-bytes " ranges" property

        new-device
            " framebuffer" device-name
            " marvell,armada-framebuffer" +compatible
            " marvell,mmp2-framebuffer" +compatible
            h# 02000000 " size" integer-property
            h# 02000000 " alignment" integer-property
            0 0 encode-bytes " no-map" property
        finish-device
    finish-device

    new-device
        " display-subsystem" device-name
        " marvell,mmp2-display-subsystem" +compatible
        " marvell,armada-display-subsystem" +compatible

        " /display@d420b000/port" encode-phandle " ports" property
        " /reserved-memory/framebuffer" encode-phandle " memory-region" property
    finish-device
device-end

" dev /camera@d420a000" evaluate
    " camera" device-name
    " marvell,mmp2-ccic" +compatible

    MMP2_CLK_CCIC0 replace-clocks
    " clock-names" delete-property
    " axi" " clock-names" string-property

    0 " #clock-cells" integer-property
    " mclk" " clock-output-names" string-property

    new-device
        " port" device-name
        new-device
            " endpoint" device-name
        finish-device
    finish-device
device-end

" dev /camera-i2c" evaluate
    " gpios" delete-property
    " /gpio@d4019000" encode-phandle
    d# 109 encode-int encode+
    GPIO_OPEN_DRAIN encode-int encode+
    " /gpio@d4019000" encode-phandle encode+
    d# 108 encode-int encode+
    GPIO_OPEN_DRAIN encode-int encode+
    " gpios" property

    " #size-cells" delete-property
    0 " #size-cells" integer-property

    d# 1000 " i2c-gpio,timeout-ms" integer-property
device-end

" dev /camera-i2c/image-sensor@21" evaluate
    " ovti,ov7670" +compatible

    " reg" delete-property
    h# 21 " reg" integer-property

    " /gpio@d4019000" encode-phandle
    d# 102 encode-int encode+
    d# 1 encode-int encode+
    " reset-gpios" property

    " /gpio@d4019000" encode-phandle
    d# 150 encode-int encode+
    d# 1 encode-int encode+
    " powerdown-gpios" property

    \ 14 replace-clocks
    " /camera@d420a000" encode-phandle " clocks" property
    " xclk" " clock-names" string-property

    new-device
       " port" device-name
        new-device
            " endpoint" device-name
            h# 1 " hsync-active" integer-property
            h# 1 " vsync-active" integer-property
            " /camera@d420a000/port/endpoint" encode-phandle " remote-endpoint" property
        finish-device
    finish-device
device-end

" dev /camera@d420a000/port/endpoint" evaluate
    " /camera-i2c/image-sensor@21/port/endpoint" encode-phandle " remote-endpoint" property
device-end
