\ Boot script for running mainline kernel on OLPC
\
\ Copyright (C) 2019 Lubomir Rintel
\ Licensed under the same terms as OpenFirmware

visible unfreeze

\ Apply various OpenFirmware band-aids
" fload last:\boot\fixes.fth" evaluate

\ Update the device tree
" fload last:\boot\dt.fth" evaluate

\ Select a kernel following the BLS
" fload last:\boot\bls.fth" evaluate

\ Present a menu
" fload last:\boot\menu.fth" evaluate

boot
