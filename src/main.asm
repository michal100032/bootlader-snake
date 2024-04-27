org 0x7C00
bits 16

cli
hlt

%assign size $-$$
%warning Size: size bytes

times 510-size db 0
dw 0xAA55