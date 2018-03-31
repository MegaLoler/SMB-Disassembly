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
frame_counter = $4017
joy1 = $4016



;;; reverse engineered labels

;; these are vars in ram

; this is used as a 16-bit pair for storing an address
zp01 = $06
zp02 = $07

;; these two are used for storing two parallel bytes in two parallel tables
zp03 = $00
zp04 = $01

zp05 = $09

addr01 = $07d7
addr20 = $07dd
reset_switch = $07ff
addr02 = $07a7
apu_status_mirror = $0770
addr17 = $0772
addr12 = $0773
addr10 = $0774
addr18 = $0777
addr19 = $0776
ppu_ctrl_mirror = $0778
ppu_mask_mirror = $0779

addr04 = $04a0

; probably a 16-bit pair?
addr06 = $0300
addr07 = $0301

; scroll mirrors!
ppu_scroll_mirror_x = $073f
ppu_scroll_mirror_y = $0740

; looks related to controllers
addr13 = $06fc
addr14 = $06fd

addr15 = $074a
addr16 = $074b

; some kind of counter
addr21 = $0747

addr22 = $077f

; start of some array af counters?
addr23 = $0780

addr24 = $07a8
addr25 = $0722
