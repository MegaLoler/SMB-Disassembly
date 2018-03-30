;;; nes important addresses:

ppu_ctrl = $2000
ppu_mask = $2001
ppu_status = $2002
oam_addr = $2003
ppu_scroll = $2005
ppu_addr = $2006
ppu_data = $2007
dmc_raw = $4011
oam_dma = $4014
apu_status = $4015



;;; reverse engineered labels

;; these are vars in ram

; this is used as a 16-bit pair for storing an address
zp01 = $06
zp02 = $07

;; these two are used for storing two parallel bytes in two parallel tables
zp03 = $00
zp04 = $01

addr01 = $07d7
reset_switch = $07ff
addr02 = $07a7
addr03 = $0770
addr12 = $0773
addr10 = $0774
ppu_ctrl_mirror = $0778
ppu_mask_mirror = $0779

addr04 = $04a0

; probably a 16-bit pair?
addr06 = $0300
addr07 = $0301

addr08 = $073f
addr09 = $0740


