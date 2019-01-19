\ Select a kernel on an installation that complies with the Boot Loader
\ Specification [1] (along with a quirk for getting the kernel parmeters
\ from gubenv.
\
\ This is pretty stupid -- it merely picks the snippet with newest
\ timestamp. If anyone needs to boot something else, they should just use
\ the Forth shell. If a wrong kernel ends up being chosen, just touch(1)
\ the right snippet.
\
\ [1] The Boot Loader Specification:
\     <https://github.com/systemd/systemd/blob/master/docs/BOOT_LOADER_SPECIFICATION.md>
\
\ Copyright (C) 2019 Lubomir Rintel
\ Licensed under the same terms as OpenFirmware

\ It's like a half-solved cryptogram where the solution is a piece
\ of FORTH code written by someone who doesn't know FORTH.
\
\       -- XKCD 1833 <https://xkcd.com/1833/>

variable yyym
variable ddhhmmss

0 yyym !
0 ddhhmmss !

: fix-path ( $ -- $ )
    " last:" 2swap $cat2
    2dup
    begin dup 0<> while
        1 -
        2dup + dup c@
        ascii / = if ascii \ swap c! else drop then
    repeat
    2drop
;

: load-grubenv ( file$ -- )
    " " to boot-file
    $read-file  abort" Could not read grubenv"
    2dup
    begin
        linefeed left-parse-string
        ascii = left-parse-string

        2dup " kernelopts" $= if  2over to boot-file  then
        2drop 2drop

        dup 0 =
    until
    2drop
    free-mem
;

: load-bls-entry ( file$ -- )
    " " to boot-device
    " " to ramdisk
    $read-file  abort" Could not read BLS file"
    2dup
    begin
        linefeed left-parse-string
        bl left-parse-string

        2dup " linux"  $=  if  2over fix-path to boot-device  else
        2dup " initrd" $=  if  2over fix-path to ramdisk
        then then
        2drop 2drop

        dup 0 =
    until
    2drop
    free-mem
;

: load-newest-bls-entry ( -- )
    " last:\loader\entries\*.conf" begin-search
    begin  another-match?  while
        rot drop \ drop permissions
        rot drop \ drop size
        2swap 4 << or \ year | month

        dup yyym @ >= if
            d# 6 roll \ seconds
            d# 6 roll d# 8 << or \ minutes
            d# 5 roll d# 16 << or \ hours
            d# 4 roll d# 24 << or \ days

            swap dup yyym @ >
            swap yyym !
            swap dup ddhhmmss @ >
            rot or if
                ddhhmmss !
                2dup " last:\loader\entries\" 2swap $cat2 load-bls-entry
            else
                drop
            then
        else
            drop
            rot drop
            rot drop
            rot drop
        then

        drop drop
    repeat
;

" last:1,\EFI\fedora\grubenv" load-grubenv
load-newest-bls-entry
