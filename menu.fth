\ A primitive boot menu with a counter.
\
\ Copyright (C) 2019 Lubomir Rintel
\ Licensed under the same terms as OpenFirmware

variable entries

: heapstr
   dup alloc-mem swap 3dup move rot drop
;

: bootentry
   entries @ .
   type cr
   entries dup @ 1 + swap !
;

: bootselect
   \ Display the counter
   0 swap \ Default to zero
   1 swap
   do
      i .d " seconds left to make a choice... " type
      d# 10 0 do
         key? if
            drop
            key 30 - \ ord(30) = '0'
            dup entries @ u>= if drop 0 then \ Turn to zero if out of range
            unloop leave
         then
         d# 100 ms
      loop
      (cr
   -1 +loop

   cr " Booting entry: " type dup . cr

   \ Set the boot entry
   entries @ swap do
      2dup to ramdisk
      free-mem
      2dup to boot-file
      free-mem
      2dup to boot-device
      free-mem
      entries dup @ 1 - swap !
   loop

   \ Discard the rest
   entries @ 0 > if
      entries @ 0 do
         free-mem
         free-mem
         free-mem
      loop
   then
;

cr

\ An entry for whatever previous code (the BLS script) has figured out
" Default" bootentry
boot-device heapstr
boot-file heapstr
ramdisk heapstr

\ Chain to another boot script
" Boot from internal eMMC" bootentry
" int:\olpc.fth" heapstr
" " heapstr
" " heapstr

\ Pick another kernel
" Fedora" bootentry
" ext:\vmlinuz-5.0.0-0.rc2.git1.2.lr1.fc29.armv7hl" heapstr
" root=LABEL=XO175 rhgb quiet" heapstr
" ext:\initramfs-5.0.0-0.rc2.git1.2.lr1.fc29.armv7hl.img" heapstr

\ Load an image from some random internet idiot
" Network boot" bootentry
" http:\\v3.sk\~lkundrak\xo175\vmlinuz" heapstr
" console=tty0 console=ttyS2,115200 earlyprintk root=/dev/mmcblk0p1 rootwait" heapstr
" " heapstr

cr

d# 5 bootselect
