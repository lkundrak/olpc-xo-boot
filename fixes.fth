\ OpenFirmware bug fixes
\
\ Copyright (C) 2019 Lubomir Rintel
\ Licensed under the same terms as OpenFirmware

\ Fix the node name strings. Previously the tree would look like this:
\
\   "/"
\     "/subnode@0"
\       "/subnode@0/leaf0"
\     "/subnode@1"
\
\ Whereas the correct version would be:
\
\   ""
\     "subnode@0"
\       "leaf0"
\     "subnode@1"
\
h# 100 buffer: xbuf
: phandle>basename
    push-device
    root-device?  if  pop-device 0 0 exit  then
    canon-buf canon-len canon-max
    xbuf to canon-buf
    0 to canon-len
    h# 100 to canon-max
    get-node-name canon+
    append-instance-address
    pop-device
    canon-len
    swap to canon-max
    swap to canon-len
    swap to canon-buf
    xbuf swap
;
patch phandle>basename phandle>devname flatten-path

\ This fixes the size_dt_struct field of the FDT header.
\ It's not clear why is it commented out in OFW, but it claims to implement
\ the version 17 of the specification, which must supply this field.
\ Linux won't boot without it.
: patch-struct-size
    fdt-ptr  fdt h# 80 +  -  fdt h# 24 +  be-l!  \ Set struct size
    fdt-strings-len
;
patch patch-struct-size fdt-strings-len flatten-device-tree

\ .fdt dumper routine lacked a line break after raw byte sequence:
\
\   interrupt-names      72 ... 72 interrupt-parent 0008d05c
\
\ Whereas the correct version would be:
\
\   interrupt-names      72 ... 72
\   interrupt-parent 0008d05c
\
: patch-cdump-cr  cdump cr  ;
patch patch-cdump-cr cdump .fdt-value
