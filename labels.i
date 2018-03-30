; nes important addresses:

ppu_ctrl = $2000
ppu_mask = $2001
ppu_status = $2002
ppu_scroll = $2005
ppu_addr = $2006
ppu_data = $2007
dmc_raw = $4011
apu_status = $4015



; reverse engineered labels

; this is used as a 16-bit pair for storing an address
zp01 = $06
zp02 = $07

addr01 = $07d7
reset_switch = $07ff
addr02 = $07a7
addr03 = $0770
ppu_ctrl_mirror = $0778

addr04 = $04a0

; probably a 16-bit pair?
addr06 = $0300
addr07 = $0301

addr08 = $073f
addr09 = $0740
