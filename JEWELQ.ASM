;**********************************************************************************************
;*                               The ROM header                                               *
;**********************************************************************************************
INCLUDE "HARDWARE.INC"
INCLUDE "SOUND/AUDIO.INC"

def MainRAM equ $C000
def OAMRAM equ MainRAM+$100
def ObjRAM equ MainRAM+$200
def JoeOAM equ ObjRAM+$00
def Ghost1OAM equ ObjRAM+$08
def Ghost2OAM equ ObjRAM+$10
def Ghost3OAM equ ObjRAM+$18

def OAMData equ $FE00
def OAMSize equ $A0

;$0000-$003F: Reset vectors (unused)
SECTION "Reset $0000", ROM0[$0000]
RST_00:
	jp $0100

SECTION "Reset $0008", ROM0[$0008]
RST_08:
	jp $0100
	
SECTION "Reset $0010", ROM0[$0010]
RST_10:
	jp $0100

SECTION "Reset $0018", ROM0[$0018]
RST_18:
	jp $0100
	
SECTION "Reset $0020", ROM0[$0020]
RST_20:
	jp $0100
	
SECTION "Reset $0028", ROM0[$0028]
RST_28:
	jp $0100
	
SECTION "Reset $0030", ROM0[$0030]
RST_30:
	jp $0100
	
SECTION "Reset $0038", ROM0[$0038]
RST_38:
	jp $0100

SECTION "V-Blank IRQ Vector", ROM0[$0040]
VCTR_DRAW:
	reti

SECTION "STAT Vector", ROM0[$0048]
VCTR_STAT:
	reti

SECTION "TimerSec Vector", ROM0[$0050]
VCTR_TIMER:
	reti
	
SECTION "Serial Vector", ROM0[$0058]
VCTR_SERIAL:
	reti
	
SECTION "Joypad Vector", ROM0[$0060]
VCTR_JOYPAD:
	reti
	
;$0100-$0103: Startup handler
SECTION "Start", ROM0[$0100]
nop
jp Main

;$0104-$0133: Nintendo logo
DB $CE, $ED, $66, $66
DB $CC, $0D, $00, $0B
DB $03, $73, $00, $83
DB $00, $0C, $00, $0D
DB $00, $08, $11, $1F
DB $88, $89, $00, $0E
DB $DC, $CC, $6E, $E6
DB $DD, $DD, $D9, $99
DB $BB, $BB, $67, $63
DB $6E, $0E, $EC, $CC
DB $DD, $DC, $99, $9F
DB $BB, $B9, $33, $3E

;$0134-$013E: Title
DB "JEWEL QUEST"

;$013F-$0142: Game code (unused)
DS 4							

;$0143: GBC compatibility flag
DB $00											;$00 = Mono

;$0144-$0145: Licensee code (new)
DB "SW"											;SW = Swift

;$0146: SGB compatibility flag
DB $00											;$00 = No SGB function

;$0147: Cartridge type
DB $00											;$00 = ROM only

;$0148: ROM size
DB $00											;$00 = 32kb (256 KiB)

;$0149: RAM size
DB $00											;$00 = No RAM

;$014A: Destination code
DB $01											;$01 = Other

;$014B: Licensee code (old)
DB $33											;$33 = Redirect to new

;$014C: ROM version number
DB $00											;$00 = V1.0

;$014D: Header checksum (Needs to be patched)
DB $00

;$014E-$014F: Global checksum (Needs to be patched)
DB $00
DB $00

;**********************************************************************************************
;*                               Main section                                                 *
;**********************************************************************************************
;$0150: Start of the main section

Main:

.ResetScrollXY
	xor a							;Set register A to 0 with exclusive OR
	ld [rSCX], a					;Set SCX to 0
	ld [rSCY], a					;Set SCY to 0

.WaitVBL							;Wait for V-Blank (145 frames)
	call WaitVBL
	
.ScreenOff
	xor a
	ld [rLCDC], a
	
.SetPalette
	ld a, %11100100
	ld [rBGP], a					;Set background palette
	
CopyData:

.InitLogo							;Load logo image tiles
	ld hl, $8000					;Address in VRAM
	ld de, LogoTiles				;Start offset of tile data
	ld bc, LogoMap - LogoTiles		;Total size of the data
	call Copy
	
.CleanUp							;"Clean up" the screen's tile data
	ld hl, $9800
	ld bc, $9FFF - $9800
	call Clear
	
	ld hl, $C000					;"Clean up" work RAM
	ld bc, $DFFF - $C000
	call Clear
	
.InitLogoMap
	ld hl, CopyNum
	ld [hl], 21						;Tile skip amount (no more registers available)
	ld hl, $98A4
	ld de, LogoMap
	ld b, 7							;Number of columns
	ld c, 11						;Number of rows
	call CopyMap
	
CopyDMARoutine:
  ld  hl, DMARoutine
  ld  b, DMARoutineEnd - DMARoutine ; Number of bytes to copy
  ld  c, LOW(hOAMDMA) ; Low byte of the destination address
.copy
  ld  a, [hli]
  ldh [c], a
  inc c
  dec b
  jr  nz, .copy
  
.InitMusic							;Initialize the sound engine
	ld a, MUS_EMPTY
	call AudioROM+$00				;Call sound init routine
	pop af

.ScreenOn
	ld a, %10010001					;Turn on screen and BG layer, set bank to $8000
	ld [rLCDC], a
	
	jp Splash

;Splash screen (Swift logo)
Splash:
.SetTimerSec
	ld a, 5
	ld [TimerSec], a
	ld a, 60
	ld [TimerFrames], a
	
.WaitLoop							;Wait until the timer is done
	call SplashInput				;Skip the timer if button is pressed
	ld a, [TimerSec]
	or a
	jp z, Title
	call WaitFrameTick
	ld a, [TimerFrames]				;Check every frame
	dec a
	ld [TimerFrames], a
	or a
	jr nz, .WaitLoop
	ld a, [TimerSec]
	dec a
	ld [TimerSec], a
	or a
	jp z, Title
	ld a, 60
	ld [TimerFrames], a
	jr .WaitLoop

SplashInput:
	ld a, %00010000						;Check A, B, Start & Select
    ldh [rJOYP], a
    ldh a, [rJOYP]
    ldh a, [rJOYP]						;Multiple read to prevent input lag
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
	cpl
    and %00001111
	ld [CurInputB], a
    ld d, a
	
	ld a, d
	and JOYP_START						;If input, then continue		
	jr z, .Released

	ld a, [StartPrev]
	or a
	jr nz, .PressedAlready
	
	ld a, 1
	ld [StartPrev], a
	
	xor a
	ld [TimerSec], a
	ld [TimerFrames], a

	jp Title
	
.PressedAlready
	ld a, 1
	ld [StartPrev], a
	ret
	
.Released
	xor a
	ld [StartPrev], a
	ret
;Title screen
Title:
	ld a, [rLCDC]					;Turn off screen until new data is loaded
	and %01111111
	ld [rLCDC], a
	nop
	
	ld a, %11100100
	ld [rBGP], a					;Set background palette
	

.InitTitle
	ld hl, $8000					;Address in VRAM
	ld de, TitleTiles				;Start offset of tile data
	ld bc, TitleMap - TitleTiles	;Total size of the data
	call Copy

.CleanUp							;"Clean up" the screen's tile data
	ld hl, $9800
	ld bc, $9FFF - $9800
	call Clear
	
.InitTitleMap
	ld hl, CopyNum
	ld [hl], 12						;Tile skip amount (no more registers available)
	ld hl, $9800
	ld de, TitleMap
	ld b, 18						;Number of columns
	ld c, 20						;Number of rows
	call CopyMap
	
.ScreenOn
	ld a, [rLCDC]
	or %10000000
	ld [rLCDC], a
	
.ResetScore							;Reset score to 0
	xor a
	ld [Score], a
	
									;Temporarily disable input
.SetTimerSec
	ld a, 1
	ld [TimerSec], a
	ld a, 60
	ld [TimerFrames], a
	
.PlayTitleSong						;Play title music
	ld a, MUS_ACTION
	call AudioROM+$06

.TitleLoop							;Wait for Start to be pressed
	call TitleInput
	jr .TitleLoop
	
TitleInput:
	ld a, %00010000						;Check A, B, Start & Select
    ldh [rJOYP], a
    ldh a, [rJOYP]
    ldh a, [rJOYP]						;Multiple read to prevent input lag
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
	cpl
    and %00001111
	ld [CurInputB], a
    ld d, a
	
	ld a, d
	and JOYP_START						;If input, then continue		
	jr z, .Released

	ld a, [StartPrev]
	or a
	jr nz, .PressedAlready
	
	ld a, 1
	ld [StartPrev], a
	jp Intro
	
.PressedAlready
	ld a, 1
	ld [StartPrev], a
	ret
	
.Released
	xor a
	ld [StartPrev], a
	call WaitVBL
	ret

;Level 1
Level1:
	call LevelInit

.InitLevel1
	ld a, 20
	ld [PlayerX], a
	xor a
	ld [PlayerX+1], a
	ld a, 38
	ld [PlayerY], a
	xor a
	ld [PlayerY+1], a
	ld a, 1							;Level number flag
	ld [LevelNum], a
	
	
.InitEnemyXPos						;Enemy X positions
	ld hl, Enemy1X
	ld a, 55
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 67
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 69
	ld [hli], a
	xor a
	ld [hli], a
	
.InitEnemyYPos						;Enemy Y positions
	ld hl, Enemy1Y
	ld a, 16
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 96
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 148
	ld [hli], a
	xor a
	ld [hli], a

.InitEnemyXSpeeds					;Enemy X speeds	
	ld a, 2
	ld [Enemy1SpeedX], a
	ld [Enemy2SpeedX], a
	ld [Enemy3SpeedX], a

	ld a, 4
	ld [Enemy1SpeedX+1], a
	ld [Enemy2SpeedX+1], a
	ld [Enemy3SpeedX+1], a

.InitEnemyYSpeeds					;Enemy Y speeds	
	xor a
	ld [Enemy1SpeedY], a
	ld [Enemy2SpeedY], a
	ld [Enemy3SpeedY], a
	ld [Enemy1SpeedY+1], a
	ld [Enemy2SpeedY+1], a
	ld [Enemy3SpeedY+1], a
	
.InitJewelXPos						;Jewel X positions
	ld hl, Jewel1X
	xor a
	ld [hli], a
	ld a, 116
	ld [hli], a
	ld a, 48
	ld [hli], a
	
.InitJewelYPos						;Jewel Y positions
	ld hl, Jewel1Y
	ld a, 16
	ld [hli], a
	ld a, 48
	ld [hli], a
	ld a, 123
	ld [hli], a
	
	call InitObjSprites
	call ScreenOn
	jp LevelLoop
	
;Level 2
Level2:
	call LevelInit

.InitLevel2
	ld a, 32
	ld [PlayerX], a
	xor a
	ld [PlayerX+1], a
	ld a, 38
	ld [PlayerY], a
	xor a
	ld [PlayerY+1], a
	ld a, 2							;Level number flag
	ld [LevelNum], a
	
	
.InitEnemyXPos						;Enemy X positions
	ld hl, Enemy1X
	ld a, 4
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 67
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 118
	ld [hli], a
	xor a
	ld [hli], a
	
.InitEnemyYPos						;Enemy Y positions
	ld hl, Enemy1Y
	ld a, 17
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 17
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 0
	ld [hli], a
	xor a
	ld [hli], a

.InitEnemyXSpeeds					;Enemy X speeds	
	xor a
	ld [Enemy1SpeedX], a
	ld [Enemy2SpeedX], a
	ld [Enemy3SpeedX], a
	
	ld [Enemy1SpeedX+1], a
	ld [Enemy2SpeedX+1], a
	ld [Enemy3SpeedX+1], a
	
.InitEnemyYSpeeds					;Enemy Y speeds	
	ld a, 2
	ld [Enemy1SpeedY], a
	ld [Enemy2SpeedY], a
	ld [Enemy3SpeedY], a
	ld [Enemy1SpeedY+1], a
	ld [Enemy2SpeedY+1], a
	ld [Enemy3SpeedY+1], a
	
.InitJewelXPos						;Jewel X positions
	ld hl, Jewel1X
	ld a, 16
	ld [hli], a
	ld a, 38
	ld [hli], a
	ld a, 118
	ld [hli], a
	
.InitJewelYPos						;Jewel Y positions
	ld hl, Jewel1Y
	ld a, 150
	ld [hli], a
	ld a, 88
	ld [hli], a
	ld a, 88
	ld [hli], a

	call InitObjSprites	
	call ScreenOn
	jp LevelLoop
	
;Level 3
Level3:
	call LevelInit

.InitLevel3
	ld a, 67
	ld [PlayerX], a
	xor a
	ld [PlayerX+1], a
	ld a, 20
	ld [PlayerY], a
	xor a
	ld [PlayerY+1], a
	ld a, 3							;Level number flag
	ld [LevelNum], a
	
	
.InitEnemyXPos						;Enemy X positions
	ld hl, Enemy1X
	ld a, 16
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 69
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 89
	ld [hli], a
	xor a
	ld [hli], a
	
.InitEnemyYPos						;Enemy Y positions
	ld hl, Enemy1Y
	ld a, 32
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 96
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 120
	ld [hli], a
	xor a
	ld [hli], a

.InitEnemyXSpeeds					;Enemy X speeds	
	ld a, 2
	ld [Enemy1SpeedX], a
	xor a
	ld [Enemy2SpeedX], a
	ld a, 2
	ld [Enemy3SpeedX], a
	
	ld a, 12
	ld [Enemy1SpeedX+1], a
	ld [Enemy2SpeedX+1], a
	ld [Enemy3SpeedX+1], a

.InitEnemyYSpeeds					;Enemy Y speeds	
	xor a
	ld [Enemy1SpeedY], a
	ld a, 2
	ld [Enemy2SpeedY], a
	xor a
	ld [Enemy3SpeedY], a
	ld [Enemy1SpeedY+1], a
	ld a, 12
	ld [Enemy2SpeedY+1], a
	xor a
	ld [Enemy3SpeedY+1], a
	
.InitJewelXPos						;Jewel X positions
	ld hl, Jewel1X
	ld a, 24
	ld [hli], a
	ld a, 116
	ld [hli], a
	ld a, 145
	ld [hli], a
	
.InitJewelYPos						;Jewel Y positions
	ld hl, Jewel1Y
	ld a, 60
	ld [hli], a
	ld a, 60
	ld [hli], a
	ld a, 150
	ld [hli], a
	
	call InitObjSprites
	call ScreenOn
	jp LevelLoop

;Level 4
Level4:
	call LevelInit

.InitLevel4
	ld a, 61
	ld [PlayerX], a
	xor a
	ld [PlayerX+1], a
	ld a, 38
	ld [PlayerY], a
	xor a
	ld [PlayerY+1], a
	ld a, 4							;Level number flag
	ld [LevelNum], a
	
	
.InitEnemyXPos						;Enemy X positions
	ld hl, Enemy1X
	ld a, 16
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 24
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 83
	ld [hli], a
	xor a
	ld [hli], a
	
.InitEnemyYPos						;Enemy Y positions
	ld hl, Enemy1Y
	ld a, 32
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 64
	ld [hli], a
	xor a
	ld [hli], a
	ld a, 64
	ld [hli], a
	xor a
	ld [hli], a

.InitEnemyXSpeeds					;Enemy X speeds	
	ld a, 3
	ld [Enemy1SpeedX], a
	ld [Enemy2SpeedX], a
	ld [Enemy3SpeedX], a

	xor a
	ld [Enemy1SpeedX+1], a
	ld [Enemy2SpeedX+1], a
	ld [Enemy3SpeedX+1], a

.InitEnemyYSpeeds					;Enemy Y speeds	
	ld a, 3
	ld [Enemy1SpeedY], a
	ld [Enemy2SpeedY], a
	ld [Enemy3SpeedY], a
	
	xor a
	ld [Enemy1SpeedY+1], a
	ld [Enemy2SpeedY+1], a
	ld [Enemy3SpeedY+1], a
	
.InitJewelXPos						;Jewel X positions
	ld hl, Jewel1X
	xor a
	ld [hli], a
	ld a, 62
	ld [hli], a
	ld a, 112
	ld [hli], a
	
.InitJewelYPos						;Jewel Y positions
	ld hl, Jewel1Y
	ld a, 135
	ld [hli], a
	ld a, 86
	ld [hli], a
	ld a, 80
	ld [hli], a
	
	call InitObjSprites
	call ScreenOn
	jp LevelLoop

InitObjSprites:						;Initialize "object sprites" (aka "metasprites")
	ld hl, ObjRAM
	
	;Object 1: Indiana Joe
	xor a
	ld [hli], a						;Starting OAM entry
	ld a, 2
	ld [hli], a						;Object width
	ld a, 4
	ld [hli], a						;Object height
	ld a, [PlayerX]
	ld [hli], a						;Object X position
	ld a, [PlayerY]
	ld [hli], a						;Object Y position
	xor a
	ld [hli], a						;Current frame
	ld [hli], a						;Object ID
;	ld a, %00001111
	ld [hli], a						;X/Y flip
	
	;Object 2: Ghost 1
	ld a, 32
	ld [hli], a						;Starting OAM entry
	ld a, 2
	ld [hli], a						;Object width
	ld a, 2
	ld [hli], a						;Object height
	ld a, 55
	ld [hli], a						;Object X position
	ld a, 16
	ld [hli], a						;Object Y position
	xor a
	ld [hli], a						;Current frame
	ld a, 1
	ld [hli], a						;Object ID
	xor a
	ld [hli], a						;X/Y flip
	
	;Object 3: Ghost 2
	ld a, 48
	ld [hli], a						;Starting OAM entry
	ld a, 2
	ld [hli], a						;Object width
	ld a, 2
	ld [hli], a						;Object height
	ld a, 67
	ld [hli], a						;Object X position
	ld a, 96
	ld [hli], a						;Object Y position
	xor a
	ld [hli], a						;Current frame
	ld a, 1
	ld [hli], a						;Object ID
	xor a
	ld [hli], a						;X/Y flip
	
	;Object 4: Ghost 3
	ld a, 64
	ld [hli], a						;Starting OAM entry
	ld a, 2
	ld [hli], a						;Object width
	ld a, 2
	ld [hli], a						;Object height
	ld a, 69
	ld [hli], a						;Object X position
	ld a, 148
	ld [hli], a						;Object Y position
	xor a
	ld [hli], a						;Current frame
	ld a, 1
	ld [hli], a						;Object ID
	xor a
	ld [hli], a						;X/Y flip
	
	;Object 5: Jewel 1
	ld a, 80
	ld [hli], a						;Starting OAM entry
	ld a, 2
	ld [hli], a						;Object width
	ld a, 2
	ld [hli], a						;Object height
	ld a, [Jewel1X]
	ld [hli], a						;Object X position
	ld a, [Jewel1Y]
	ld [hli], a						;Object Y position
	xor a
	ld [hli], a						;Current frame
	ld a, 2
	ld [hli], a						;Object ID
	xor a
	ld [hli], a						;X/Y flip
	
	;Object 6: Jewel 2
	ld a, 96
	ld [hli], a						;Starting OAM entry
	ld a, 2
	ld [hli], a						;Object width
	ld a, 2
	ld [hli], a						;Object height
	ld a, [Jewel2X]
	ld [hli], a						;Object X position
	ld a, [Jewel2Y]
	ld [hli], a						;Object Y position
	xor a
	ld [hli], a						;Current frame
	ld a, 2
	ld [hli], a						;Object ID
	xor a
	ld [hli], a						;X/Y flip
	
	;Object 7: Jewel 3
	ld a, 112
	ld [hli], a						;Starting OAM entry
	ld a, 2
	ld [hli], a						;Object width
	ld a, 2
	ld [hli], a						;Object height
	ld a, [Jewel3X]
	ld [hli], a						;Object X position
	ld a, [Jewel3Y]
	ld [hli], a						;Object Y position
	xor a
	ld [hli], a						;Current frame
	ld a, 2
	ld [hli], a						;Object ID
	xor a
	ld [hli], a						;X/Y flip
	
	
	ld a, $FF						;End of objects
	ld [hl], a
	ret
	
LevelInit:
	ld a, [rLCDC]					;Turn off screen until new data is loaded
	ld a, %00000011					;Also turn sprites on, set bank to $9000
	ld [rLCDC], a
	nop
	
.SetPal
	ld a, %11010010					;Set sprite palette - white, light gray, and black
	ld [rOBP0], a
	
.InitCaveBG
	ld hl, $9000					;Address in VRAM
	ld de, CaveTiles				;Start offset of tile data
	ld bc, CaveMap - CaveTiles	;Total size of the data
	call Copy
	
.InitBlock							;Copy block graphics
	ld hl, $9200					;(not used)
	ld de, BlockTiles
	ld bc, BlockTilesEnd - BlockTiles
	call Copy

.CleanUp							;"Clean up" the screen's tile data
	ld hl, $9800
	ld bc, $9FFF - $9800
	call Clear
	ld a, 0							;0 value to fill in
	ld b, OAMSize					;Size of OAM
	ld hl, OAMData					;Address of OAM data
	call ClearOAM
	
.InitCaveBGMap
	ld hl, CopyNum
	ld [hl], 12						;Tile skip amount (no more registers available)
	ld hl, $9800
	ld de, CaveMap
	ld b, 18						;Number of columns
	ld c, 20						;Number of rows
	call CopyMap
	
	
.InitSprites
	ld hl, $8000					;Copy Indiana Joe (player) sprites
	ld de, JoeTiles
	ld bc, JoeTilesEnd - JoeTiles
	call Copy
	
	ld hl, $8150					;Copy fist sprites
	ld de, FistTiles				;(not used)
	ld bc, FistTilesEnd - FistTiles
	call Copy
	
	ld hl, $8200					;Copy ghost (enemy) sprites
	ld de, GhostTiles
	ld bc, GhostTilesEnd - GhostTiles
	call Copy
	
	ld hl, $8240					;Copy jewel sprites
	ld de, JewelTiles
	ld bc, JewelTilesEnd - JewelTiles
	call Copy
	
.InitPlayerSpeed
	ld hl, PlayerSpeed
	ld de, $0180					;1.5
	ld a, d
	ld [hli], a
	ld a, e
	ld [hl], a
	
.InitCollSizes
	ld a, 16
	ld [CollWSize], a
	ld [CollHSize], a
	
.InitPal
	ld a, %11100100
	ld [rBGP], a					;Set background palette
	
.PlayLevelSong						;Play level music
	ld a, MUS_SHOW
	call AudioROM+$06
	ret
	
ScreenOn:
	ld a, [rLCDC]
	or %10000000
	ld [rLCDC], a
	ret

LevelLoop:
	call WaitVBL
	call LevelInput
	call AnimPlayer
	call MoveEnemiesX
	call MoveEnemiesY
	call CheckEnemyColl
	call CheckJewelColl
	call CheckJewelsToGo
	call BuildShadowOAM
	ld a, HIGH(OAMRAM)
	call hOAMDMA
	jr LevelLoop
	
LevelInput:
	ld a, %00100000							;Check D-PAD input
    ldh [rJOYP], a
    ldh a, [rJOYP]
    ldh a, [rJOYP]							;Multiple read to prevent input lag
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
	cpl
    and %00001111
	ld d, a
	
	ld a, %00110000
    ldh [rJOYP], a
		
    ld a, d
	or a								;If input, then continue
	jr nz, .CheckLeft
	ld [CurInputA], a					;Otherwise, then set input variable and return
	jp .NoInput
	
.CheckLeft								;First, check left
	;Set player animation to walk
	ld a, 1
	ld [PlayerAnim], a
	ld a, d
	and a, $02
	jp z, .CheckRight
.Left									;If left, also flip sprite left
	ld a, [JoeOAM+7]
	or %11110000
	ld [JoeOAM+7], a
	push de
	ld a, [PlayerX]						;Move player left
	ld h, a
	ld a, [PlayerX+1]
	ld l, a
	ld a, [PlayerSpeed]
	cpl a
	ld d, a
	ld a, [PlayerSpeed+1]
	cpl a
	ld e, a

	add hl, de

	ld a, h
	ld [PlayerX], a
	ld a, l
	ld [PlayerX+1], a

	ld a, h
	ld [JoeOAM+3], a
	pop de
.CheckRight								;Then, check right
	ld a, d
	and a, $01
	jp z, .CheckUp
.Right
	ld a, [JoeOAM+7]					;If right, don't flip sprite
	and %00001111
	ld [JoeOAM+7], a
	push de
	ld a, [PlayerX]						;Move player right
	ld h, a
	ld a, [PlayerX+1]
	ld l, a
	ld a, [PlayerSpeed]
	ld d, a
	ld a, [PlayerSpeed+1]
	ld e, a

	add hl, de

	ld a, h
	ld [PlayerX], a
	ld a, l
	ld [PlayerX+1], a

	ld a, h
	ld [JoeOAM+3], a
	pop de
.CheckUp								;Then, check up
	ld a, d
	and a, $04
	jp z, .CheckDown
.Up
	push de
	ld a, [PlayerY]						;Move player up
	ld h, a
	ld a, [PlayerY+1]
	ld l, a
	ld a, [PlayerSpeed]
	cpl a
	ld d, a
	ld a, [PlayerSpeed+1]
	cpl a
	ld e, a

	add hl, de

	ld a, h
	ld [PlayerY], a
	ld a, l
	ld [PlayerY+1], a

	ld a, h
	ld [JoeOAM+4], a
	pop de
.CheckDown								;Finally, check down
	ld a, d
	and a, $08
	ret z
.Down
	push de
	ld a, [PlayerY]						;Move player down
	ld h, a
	ld a, [PlayerY+1]
	ld l, a
	ld a, [PlayerSpeed]
	ld d, a
	ld a, [PlayerSpeed+1]
	ld e, a

	add hl, de

	ld a, h
	ld [PlayerY], a
	ld a, l
	ld [PlayerY+1], a

	ld a, h
	ld [JoeOAM+4], a
	pop de
	ret
	
	
.NoInput
	xor a
	ld [PlayerAnim], a				;Set player animation to stand
	ret

;Set correct animations/frames for the player Indiana Joe
AnimPlayer:
	ld a, [PlayerAnim]
	or a
	jr nz, .Walk
.Stand
	xor a
	ld [JoeOAM+5], a
	ld [AnimTimer], a				;Reset animation timer
	ret
.Walk
	ld a, [AnimTimer]
	or a
	jr z, .Walk_0
	dec a
	ld [AnimTimer], a
	ret
.Walk_0
	ld a, 15
	ld [AnimTimer], a
	ld a, [JoeOAM+5]				;Check animation frame
	cp a, 0
	jr z, .Walk_1
	cp a, 4
	jr c, .Walk_1
	jr .Walk_2
.Walk_1
	inc a
	jr .Walk_3
.Walk_2
	ld a, 1
	jr .Walk_3
.Walk_3
	ld [JoeOAM+5], a
	ret


;Move the enemies (ghosts) - horizontal
MoveEnemiesX:
	ld a, 3							;Repeat the process for all 3 ghosts	
	ld [EnemyCount], a
	ld hl, Ghost1OAM+3
	ld de, Enemy1X
	ld bc, Enemy1SpeedX
.MoveEnemiesXLoop
	push hl							;Save OAM pointer
	push de							;Save position pointer
	
	ld a, [de]						;Load position
	ld [TempPosX], a
	inc de
	ld a, [de]
	ld [TempPosX+1], a
	
	ld a, [bc]						;Load speed
	ld [TempSpeedX], a
	inc bc
	ld a, [bc]
	ld [TempSpeedX+1], a
	
	dec bc							;Check if "negative" bit is set
	ld a, [TempSpeedX]	
	bit 7, a
	jr nz, .IsNeg
.IsPos								;If positive
	ld a, [TempPosX]				;HL = position
	ld h, a
	ld a, [TempPosX+1]
	ld l, a
	
	ld a, [TempSpeedX]				;DE = speed
	ld d, a
	ld a, [TempSpeedX+1]
	ld e, a
	
	add hl, de						;Add speed per frame
	ld a, l
	ld [TempPosX+1], a
	ld a, h
	ld [TempPosX], a
	cp 160							;Check if reached edge
	jr c, .WriteBack
.SetNeg
	ld a, [bc]
	set 7, a						;Set "negative" bit
	ld [bc], a
	jr .WriteBack
.IsNeg								;If negative
	and %01111111
	ld [TempSpeedX], a
	ld a, [TempPosX]				;HL = position
	ld h, a
	ld a, [TempPosX+1]
	ld l, a
	
	ld a, [TempSpeedX]				;DE = speed
	ld d, a
	ld a, [TempSpeedX+1]
	ld e, a
	ld a, l
	sub e							;Subtract speed per frame
	ld l, a						
	ld a, h
	sbc a, d
	ld h, a
	ld [TempPosX], a
	ld a, l
	ld [TempPosX+1], a
	jr nc, .WriteBack				;Check if reached edge
.SetPos
	ld a, [bc]
	res 7, a						;Reset "negative" bit
	ld [bc], a
.WriteBack
	pop de							;Restore position pointer
	ld a, [TempPosX]				;Load temporary position into final
	ld [de], a
	inc de
	ld a, [TempPosX+1]
	ld [de], a
	dec de
	pop hl							;Restore OAM pointer
	ld a, [TempPosX]
	ld [hl], a						;Update sprite X with whole-pixel position
	ld a, l
	add 8							;Go to next enemy's OAM X
	ld l, a
	jr nc, .NextEnemy
	inc h
.NextEnemy
	inc de							;Go to next enemy's position
	inc de
	inc bc							;Go to next enemy's speed
	inc bc
	ld a, [EnemyCount]
	dec a
	ld [EnemyCount], a
	jp nz, .MoveEnemiesXLoop
	ret
	
;Move the enemies (ghosts) - horizontal
MoveEnemiesY:
	ld a, 3							;Repeat the process for all 3 ghosts	
	ld [EnemyCount], a
	ld hl, Ghost1OAM+4
	ld de, Enemy1Y
	ld bc, Enemy1SpeedY
.MoveEnemiesYLoop
	push hl							;Save OAM pointer
	push de							;Save position pointer
	
	ld a, [de]						;Load position
	ld [TempPosY], a
	inc de
	ld a, [de]
	ld [TempPosY+1], a
	
	ld a, [bc]						;Load speed
	ld [TempSpeedY], a
	inc bc
	ld a, [bc]
	ld [TempSpeedY+1], a
	
	dec bc							;Check if "negative" bit is set
	ld a, [TempSpeedY]	
	bit 7, a
	jr nz, .IsNeg
.IsPos								;If positive
	ld a, [TempPosY]				;HL = position
	ld h, a
	ld a, [TempPosY+1]
	ld l, a
	
	ld a, [TempSpeedY]				;DE = speed
	ld d, a
	ld a, [TempSpeedY+1]
	ld e, a
	
	add hl, de						;Add speed per frame
	ld a, l
	ld [TempPosY+1], a
	ld a, h
	ld [TempPosY], a
	cp 144							;Check if reached edge
	jr c, .WriteBack
.SetNeg
	ld a, [bc]
	set 7, a						;Set "negative" bit
	ld [bc], a
	jr .WriteBack
.IsNeg								;If negative
	and %01111111
	ld [TempSpeedY], a
	ld a, [TempPosY]				;HL = position
	ld h, a
	ld a, [TempPosY+1]
	ld l, a
	
	ld a, [TempSpeedY]				;DE = speed
	ld d, a
	ld a, [TempSpeedY+1]
	ld e, a
	ld a, l
	sub e							;Subtract speed per frame
	ld l, a						
	ld a, h
	sbc a, d
	ld h, a
	ld [TempPosY], a
	ld a, l
	ld [TempPosY+1], a
	jr nc, .WriteBack				;Check if reached edge
.SetPos
	ld a, [bc]
	res 7, a						;Reset "negative" bit
	ld [bc], a
.WriteBack
	pop de							;Restore position pointer
	ld a, [TempPosY]				;Load temporary position into final
	ld [de], a
	inc de
	ld a, [TempPosY+1]
	ld [de], a
	dec de
	pop hl							;Restore OAM pointer
	ld a, [TempPosY]
	ld [hl], a						;Update sprite Y with whole-pixel position
	ld a, l
	add 8							;Go to next enemy's OAM Y
	ld l, a
	jr nc, .NextEnemy
	inc h
.NextEnemy
	inc de							;Go to next enemy's position
	inc de
	inc bc							;Go to next enemy's speed
	inc bc
	ld a, [EnemyCount]
	dec a
	ld [EnemyCount], a
	jp nz, .MoveEnemiesYLoop
	ret

CheckEnemyColl:						;Check distance between player and enemy
	;First, check horizontal
	ld hl, Enemy1X
	
	;Clear counter for current enemy
	xor a
	ld [EnemyCount], a
	
.CheckEnemyCollLoop					;Return if done checking all 3 enemies and no collision
	ld a, [EnemyCount]
	cp a, 3
	jp nc, .NoHitEnemy
	
.CheckEnemyCollX
	ld a, [hl]
	ld e, a
	ld a, [PlayerX]
	ld b, a
	ld a, [CollWSize]
	ld d, a
	;E = enemy X pos, B = player X pos, D = width
	ld a, b
	add d
	cp e
	jp c, .NextEnemy2		; player+W < enemy
	ld a, e
	add d
	cp b
	jp c, .NextEnemy2		; enemy+W < player
	
.CheckEnemyCollY
	ld bc, 6						;Now check Y
	add hl, bc
	
	ld a, [hl]
	ld e, a
	ld a, [PlayerY]
	ld b, a
	ld a, [CollHSize]
	ld d, a
	;E = enemy Y pos, B = player Y pos, D = height
	ld a, b
	add d
	cp e
	jp c, .NextEnemy		; player+H < enemy
	ld a, e
	add d
	cp b
	jp c, .NextEnemy		; enemy+H < player

;If player touches enemy, lose
.HitEnemy
	ld a, 1
	ld [CollWTest], a
	jp PlayerLose
		
.NextEnemy
	ld bc, -6						;Back to X variables
	add hl, bc
.NextEnemy2
	ld bc, 2						;Advance to next enemy variables
	add hl, bc
	ld a, [EnemyCount]
	inc a							;Increment enemy count
	ld [EnemyCount], a
	jp .CheckEnemyCollLoop
	
.NoHitEnemy							;No enemy hit
	xor a
	ld [CollWTest], a
	ret
	
CheckJewelColl:						;Check distance between player and jewel
	;First, check horizontal
	ld hl, Jewel1X
	
	;Clear counter for current jewel
	xor a
	ld [JewelCount], a
	
.CheckJewelCollLoop					;Return if done checking all 3 jewels and no collision
	ld a, [JewelCount]
	cp a, 3
	jp nc, .NoHitJewel
	
.CheckJewelActive
	ld a, [hl]						;Check if X value is $FF
	cp $FF
	jp z, .NextJewel2				;If so, then jewel already collected - go to next jewel
	
.CheckJewelCollX
	ld a, [hl]
	ld e, a
	ld a, [PlayerX]
	ld b, a
	ld a, [CollWSize]
	ld d, a
	;E = jewel X pos, B = player X pos, D = width (16)
	; Avoid sub underflow when E < D (e.g. X=0): use adds only
	ld a, b
	add d
	cp e
	jp c, .NextJewel2			; playerX+W < jewelX -> no collision
	ld a, e
	add d
	cp b
	jp c, .NextJewel2			; jewelX+W < playerX -> no collision
	
.CheckJewelCollY
	ld bc, 3						;Now check Y
	add hl, bc
	
	ld a, [hl]
	ld e, a
	ld a, [PlayerY]
	ld b, a
	ld a, [CollHSize]
	ld d, a
	;E = jewel Y pos, B = player Y pos, D = height (16)
	ld a, b
	add d
	cp e
	jp c, .NextJewel			; playerY+H < jewelY -> no collision
	ld a, e
	add d
	cp b
	jp c, .NextJewel			; jewelY+H < playerY -> no collision

;If player touches jewel, collect and add to score
.HitJewel
	ld a, 1
	ld [CollWTest], a
	ld a, [Score]					;Increment score
	inc a
	ld [Score], a
	ld bc, -3						;Go back to X, set position to FF (no collision)
	add hl, bc
	ld a, $FF						;Disable jewel collision
	ld [hl], a
	push hl							;Now make jewel disappear
	push de
	push bc
	ld hl,ObjRAM+32 				; Jewel object
	xor a
	ld d,a
	ld a, [JewelCount]
	ld e,a
	sla e							;Multiply by 8
	rl d
	sla e
	rl d
	sla e
	rl d
	add hl,de						;Add value to object RAM address
	ld de, 4						;Get Y value
	add hl,de
	xor a 							; Y=0 = off-screen on GB
	ld [hl],a
	pop bc
	pop de
	pop hl
	
	ld a, SFX_COLLECT			;Play sound effect
	call AudioROM+$24
	ret
		
.NextJewel
	ld bc, -3						;Back to X variables
	add hl, bc
.NextJewel2
	ld bc, 1						;Advance to next jewel variables
	add hl, bc
	ld a, [JewelCount]
	inc a
	ld [JewelCount], a
	jp .CheckJewelCollLoop
	
.NoHitJewel							;No jewel hit
	xor a
	ld [CollWTest], a
	ret
	
CheckJewelsToGo:
	ld a, [LevelNum]				;Check current level number
	cp 1
	jr z, .Level1Score
	cp 2
	jr z, .Level2Score
	cp 3
	jr z, .Level3Score
	cp 4
	jr z, .Level4Score
.Level1Score						;Level 1
	ld a, [Score]
	cp 3
	jp nc, .GotoNextLevel			;Player has collected enough jewels
	jp c, .NotDone					;Not enough jewels yet...
.Level2Score						;Level 2
	ld a, [Score]
	cp 6
	jp nc, .GotoNextLevel
	jp c, .NotDone
.Level3Score						;Level 3
	ld a, [Score]
	cp 9
	jp nc, .GotoNextLevel			;Player has collected enough jewels
	jp c, .NotDone					;Not enough jewels yet...
.Level4Score						;Level 4
	ld a, [Score]
	cp 12
	jp nc, .GotoNextLevel			;Player has collected enough jewels
	jp c, .NotDone					;Not enough jewels yet...
.NotDone
	ret
.GotoNextLevel
	ld a, [LevelNum]
	cp 1
	jp z, Level2
	cp 2
	jp z, Level3
	cp 3
	jp z, Level4
	cp 4
	jp z, PlayerWin
	jp Level1

WaitVBL:							;Wait for V-Blank (145 frames)
	ld a, [rLY]
	cp 144
	jr nz, WaitVBL
	call AudioROM+$0C				;Play music
	call AudioROM+$0F				;Play sound effects
	ret

WaitFrameTick:
	ld a, [rLY]						;Wait for V-Blank (145 frames)
	cp 144
	jr nc, WaitFrameTick
.WaitFrameTick2
	ld a, [rLY]						;Wait for V-Blank (145 frames)
	cp 144
	jr c, .WaitFrameTick2
	ret

;"You win!" screen
Intro:
	ld a, %10010001					;Turn on screen and BG layer, set bank to $8000
	ld [rLCDC], a

	ld a, [rLCDC]					;Turn off screen until new data is loaded
	and %01111111
	ld [rLCDC], a
	nop

.CleanUp							;"Clean up" the screen's tile data
	ld hl, $9800
	ld bc, $9FFF - $9800
	call ClearSpace
	
.InitFont							;Load font tiles
	ld hl, $8300					;Address in VRAM
	ld de, FontTiles				;Start offset of tile data
	ld bc, FontTilesEnd - FontTiles	;Total size of tile data
	call CopyFont
	
.InitIntroText						;Display intro text
	ld hl, $9800					;Address in VRAM (start of BG tilemap)
	ld de, TextIntro
	call CopyText

.SetPalette
	ld a, %11010010
	ld [rBGP], a			;Set background palette
	
.ScreenOn
	ld a, [rLCDC]
	or %10000000
	ld [rLCDC], a
	
.IntroLoop							;Wait for Start to be pressed
	call IntroInput
	jr .IntroLoop
	
IntroInput:
	ld a, %00010000						;Check A, B, Start & Select
    ldh [rJOYP], a
    ldh a, [rJOYP]
    ldh a, [rJOYP]						;Multiple read to prevent input lag
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
	cpl
    and %00001111
	ld [CurInputB], a
    ld d, a
	
	ld a, d
	and JOYP_START						;If input, then continue		
	jr z, .Released

	ld a, [StartPrev]
	or a
	jr nz, .PressedAlready
	
	ld a, 1
	ld [StartPrev], a
	jp Level1
	
.PressedAlready
	ld a, 1
	ld [StartPrev], a
	ret
	
.Released
	xor a
	ld [StartPrev], a
	call WaitVBL
	ret

;"You lose!" screen
PlayerLose:
	ld a, %10010001					;Turn on screen and BG layer, set bank to $8000
	ld [rLCDC], a

	ld a, [rLCDC]					;Turn off screen until new data is loaded
	and %01111111
	ld [rLCDC], a
	nop
	

.InitLose
	ld hl, $8000					;Address in VRAM
	ld de, LoseTiles				;Start offset of tile data
	ld bc, LoseMap - LoseTiles		;Total size of the data
	call Copy

.CleanUp							;"Clean up" the screen's tile data
	ld hl, $9800
	ld bc, $9FFF - $9800
	call Clear
	
.InitLoseMap
	ld hl, CopyNum
	ld [hl], 28					;Tile skip amount (no more registers available)
	ld hl, $98A8
	ld de, LoseMap
	ld b, 5						;Number of columns
	ld c, 4						;Number of rows
	call CopyMap
	
.InitFont							;Load font tiles
	ld hl, $8300					;Address in VRAM
	ld de, FontTiles				;Start offset of tile data
	ld bc, FontTilesEnd - FontTiles	;Total size of tile data
	call CopyFont
	
.InitLoseText						;Display "You lose!" text
	ld hl, $9840					;Address in VRAM (start of BG tilemap)
	ld de, TextLose
	call CopyText
	
.InitScoreText
    ld hl, $99E6
    ld de, TextScore
    call CopyText

.DisplayScore
    ld hl, $99EC            ; First digit tilemap position
    ld a, [Score]            ; A = binary score

    ld b, 0                  ; B = tens digit

.CalculateTens
    cp 10
    jr c, .HaveDigits        ; If A < 10, A is the ones digit
    sub 10
    inc b
    jr .CalculateTens

.HaveDigits
    ; B = tens digit
    ; A = ones digit

    ld c, a                  ; Save ones digit

    ld a, b
    add a, $40
    ld [hl+], a              ; Display tens digit

    ld a, c
    add a, $40
    ld [hl], a               ; Display ones digit
	
	
.SetPalette
	ld a, %11010010
	ld [rBGP], a					;Set background palette
	
.PlayGhostSound
	ld a, MUS_EMPTY					;Turn off music
	call AudioROM+$06
	ld a, SFX_GHOST					;Play sound effect
	call AudioROM+$24
	
.ScreenOn
	ld a, [rLCDC]
	or %10000000
	ld [rLCDC], a
	
.LoseLoop							;Wait for Start to be pressed
	call LoseInput
	jr .LoseLoop
	
LoseInput:
	ld a, %00010000						;Check A, B, Start & Select
    ldh [rJOYP], a
    ldh a, [rJOYP]
    ldh a, [rJOYP]						;Multiple read to prevent input lag
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
	cpl
    and %00001111
	ld [CurInputB], a
    ld d, a
	
	ld a, d
	and JOYP_START						;If input, then continue		
	jr z, .Released

	ld a, [StartPrev]
	or a
	jr nz, .PressedAlready
	
	ld a, 1
	ld [StartPrev], a
	jp Title
	
.PressedAlready
	ld a, 1
	ld [StartPrev], a
	ret
	
.Released
	xor a
	ld [StartPrev], a
	call WaitVBL
	ret

;"You win!" screen
PlayerWin:
	ld a, %10010001					;Turn on screen and BG layer, set bank to $8000
	ld [rLCDC], a

	ld a, [rLCDC]					;Turn off screen until new data is loaded
	and %01111111
	ld [rLCDC], a
	nop

.CleanUp							;"Clean up" the screen's tile data
	ld hl, $9800
	ld bc, $9FFF - $9800
	call ClearSpace
	
.InitFont							;Load font tiles
	ld hl, $8300					;Address in VRAM
	ld de, FontTiles				;Start offset of tile data
	ld bc, FontTilesEnd - FontTiles	;Total size of tile data
	call CopyFont
	
.InitWinText						;Display "You win!" text
	ld hl, $9906					;Address in VRAM (start of BG tilemap)
	ld de, TextWin
	call CopyText
	
.InitScoreText
    ld hl, $99E6
    ld de, TextScore
    call CopyText

.DisplayScore
    ld hl, $99EC            ; First digit tilemap position
    ld a, [Score]            ; A = binary score

    ld b, 0                  ; B = tens digit

.CalculateTens
    cp 10
    jr c, .HaveDigits        ; If A < 10, A is the ones digit
    sub 10
    inc b
    jr .CalculateTens

.HaveDigits
    ; B = tens digit
    ; A = ones digit

    ld c, a                  ; Save ones digit

    ld a, b
    add a, $40
    ld [hl+], a              ; Display tens digit

    ld a, c
    add a, $40
    ld [hl], a               ; Display ones digit
	
	
.SetPalette
	ld a, %11010010
	ld [rBGP], a			;Set background palette
	
.PlayWinSong				;Play win music
	ld a, MUS_FANFARE
	call AudioROM+$06
	
.ScreenOn
	ld a, [rLCDC]
	or %10000000
	ld [rLCDC], a
	
.WinLoop							;Wait for Start to be pressed
	call WinInput
	jr .WinLoop
	
WinInput:
	ld a, %00010000						;Check A, B, Start & Select
    ldh [rJOYP], a
    ldh a, [rJOYP]
    ldh a, [rJOYP]						;Multiple read to prevent input lag
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
    ldh a, [rJOYP]
	cpl
    and %00001111
	ld [CurInputB], a
    ld d, a
	
	ld a, d
	and JOYP_START						;If input, then continue		
	jr z, .Released

	ld a, [StartPrev]
	or a
	jr nz, .PressedAlready
	
	ld a, 1
	ld [StartPrev], a
	jp Title
	
.PressedAlready
	ld a, 1
	ld [StartPrev], a
	ret
	
.Released
	xor a
	ld [StartPrev], a
	call WaitVBL
	ret

CopyMap:

.StartRow
	push bc
	
.CopyRow
	ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, .CopyRow
	
.EndRow
	ld a, [CopyNum]					;Get tile skip amount (from RAM as we ran out of registers)
	push bc
	ld b, a
	ld a, l
	add b
	pop bc
	jr nc, .NextRow
	inc h

.NextRow
	ld l, a
	pop bc
	dec b
	jr nz, .StartRow
	ret

Clear:								;Fill in both tilemaps with white space
	xor a
	ld [hli], a
	dec bc
	ld a, b
	or c
	jr nz, Clear
	ret
	
ClearSpace:							;Fill in both tilemaps with space text character
	ld a, $30
	ld [hli], a
	dec bc
	ld a, b
	or c
	jr nz, ClearSpace
	ret
	
Copy:								;Multi-purpose data copy function
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, Copy
	ret
	
CopyFont:							;Copy 1-bit font tile data
	ld a, [de]
	ld [hli], a						;Load twice to convert to 2-bit
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, CopyFont
	ret	
	
BuildShadowOAM:						;Copy an "object sprite" to shadow OAM
	ld hl, ObjRAM
	
.LoopObj
	push de
	ld a, [hl]
	cp $FF							;Check if end of objects
	jr z, .DoneObjects

	ld de, TempObjRAM
	ld b, 8							;8 bytes

.Copy8								;Copy object parameters
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .Copy8
	
	;Parameters:
    ; TempObjRAM+0: startOam
    ; +1: w
    ; +2: h
    ; +3: baseX
    ; +4: baseY
    ; +5: frame
    ; +6: objIndex
    ; +7: flip flags
	
	push hl
	push de
	push bc
	call ExpandObjToShadow
	pop bc
	pop de
	pop hl
	pop de
	jr .LoopObj
	
.DoneObjects
	pop de
	ret
	
ExpandObjToShadow:
	ld hl, TempObjRAM
	ld de, OAMRAM
	
	xor a							;First, clear variables
	ld [TempTX], a
	ld [TempTY], a
	ld [TempTilesCnt], a
	
	ld a, [hli]						;Byte 1: Starting OAM entry
	ld [TempStartOAM], a
	
	ld a, [hli]						;Byte 2: Object width (in tiles)
	ld [TempW], a
	
	ld a, [hli]						;Byte 3: Object height (in tiles)
	ld [TempH], a
	
	ld a, [hli]						;Byte 4: Object X position
	ld [TempBaseX], a
	
	ld a, [hli]						;Byte 5: Object Y position
	ld [TempBaseY], a
	
	ld a, [hli]						;Byte 6: Current frame
	ld [TempFrame], a
	
	ld a, [hli]						;Byte 7: Map/sprite index
	ld [TempObjID], a
	
	ld a, [hli]						;Byte 8: X/Y flip (xxxx yyyy)
	ld [TempFlip], a
	
	;Determine if flips are active
	ld a, [TempFlip]
	and %11110000
	ld [XFlip], a
	ld a, [TempFlip]
	and %00001111
	ld [YFlip], a
	
	;Adjust base X/Y values based on flip values
.CheckXFlip
	ld a, [XFlip]
	or a
	jr z, .InitXNoFlip
.InitXFlip
	ld a, [TempBaseX]
	ld c, a
	ld a, [TempW]
	ld b, a
	ld a, c
	inc b
.InitXMult
	add 8
	dec b
	jr nz, .InitXMult
	ld [TempBaseX], a
.InitXNoFlip

.CheckYFlip
	ld a, [YFlip]
	or a
	jr z, .InitYNoFlip
.InitYFlip
	ld a, [TempBaseY]
	ld c, a
	ld a, [TempW]
	ld b, a
	ld a, c
	inc b
.InitYMult
	add 8
	dec b
	jr nz, .InitYMult
	ld [TempBaseY], a
.InitYNoFlip

.ClearTileNum
	;Clear tile number
	xor a	
	ld [TempTilesCnt], a
	ld [TempTile], a
	
	;Multiply width*height
.Multiply
	xor a
	ld [TempTilesCnt], a
	ld a, [TempW]
	ld b, a
	ld a, [TempH]
	ld c, a
.MultiplyLoop
	ld a, [TempTilesCnt]
	add b
	ld [TempTilesCnt], a
	dec c
	jr nz, .MultiplyLoop
	
	;Get start of OAM entry
	ld a, [TempStartOAM]
	add e
	ld e, a
	jr nc, .Expand2
	inc d
.Expand2
	;Get W and H values
	ld a, [TempW]
	ld b, a
	ld a, [TempH]
	ld c, a
	
	ld a, [TempBaseY]				;Set effective Y address as base
	ld [TempEffTY], a

.DoCol
	ld a, [TempTY]					;Check if any rows remaining
	cp c
	ret z							;Return if done
	
.DoRow
	xor a
	ld [TempTX], a					;Set effective X address as base
	ld a, [TempBaseX]
	ld [TempEffTX], a
	
.RowLoop
	ld a, [TempTX]					;Check if any columns remaining
	cp b
	jp z, .DoneRow

	ld a, [XFlip]					;If so, then check X flip
	or a
	ld a, [TempEffTX]
	jr nz, .Flip
.NoFlip
	add 8							;If not flipped, then add 8 for next column
	ld [TempEffTX], a
	jr .GetID
.Flip
	sub 8							;If flipped, then subtract 8 for next column
	ld [TempEffTX], a

;Get frame ID from index in pointer table
.GetID
	push hl
	push de
	ld hl, ObjFramesList			;First, get object table offset
	ld a, [TempObjID]
	add a							;2 bytes per entry
	add l
	ld l, a
	jr nc, .GetID2
	inc h
.GetID2
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	
	ld a, [TempTilesCnt]			;Now, get current frame
	ld l, a
	ld a, [TempFrame]
	ld h, a
	
	or a							;If frame is not 0, then add to offset
	jr z, .GetFrameTile
	xor a

.MultFrame							;Multiply offset by object size
	ld a, l
	dec h
	add e
	ld e, a
	ld a, h
	jr nc, .MultFrame2
	inc d
.MultFrame2
	or a
	jr z, .GetFrameTile
	jr .MultFrame
	
.GetFrameTile						;Finally, get the correct tile
	ld a, [TempTile]
	add e
	ld e, a
	jr nc, .GetFrameTile2
	inc d
.GetFrameTile2
	ld a, [de]
	
	pop de							;Restore original values
	pop hl
	ld [TempTileID], a

.ShadCopy
	ld a, [TempEffTY]				;Load effective Y address
	ld [de], a
	inc de
	ld a, [TempEffTX]				;Load effective X address
	ld [de], a
	inc de
	ld a, [TempTileID]				;Load tile number
	ld [de], a
	inc de
	
	ld a, [YFlip]					;Load Y flip
	or a
	jr z, .ShadCopy2
	ld a, [de]
	or %01000000
	ld [de], a
.ShadCopy2
	ld a, [XFlip]					;Load X flip
	or a
	jr z, .ShadCopy3
	ld a, [de]
	or %00100000
.ShadCopy3
	ld [de], a
	ld a, [TempTile]				;Increase current tile number
	inc a
	ld [TempTile], a
	ld a, [TempTX]					;Also increase X count
	inc a
	ld [TempTX], a
.ShadCopy4
	inc de
	jp .RowLoop
	
.DoneRow
	xor a							;Reset X count
	ld [TempTX], a
	ld a, [TempTY]					;Increment Y count
	inc a
	ld [TempTY], a
	ld a, [YFlip]
	or a
	ld a, [TempEffTY]
	jr nz, .FlipY
.NoFlipY
	add 8
	ld [TempEffTY], a
	jp .DoCol
.FlipY
	sub 8
	ld [TempEffTY], a
	jp .DoCol
	

ClearOAM:							;Fill in the OAM data with empty data (or any other byte specified)
	ld [hli], a
	dec b
	jr nz, ClearOAM
	ret

;Copy DMA routine
DMARoutine:
	ldh [rDMA], a

	ld  a, 40
.wait
	dec a
	jr  nz, .wait
	ret
DMARoutineEnd:

;Specialized text data copy function	
CopyText:
	ld a, [de]						;Get current byte from source
	inc de
	dec bc
	cp $FF
	jr z, .CopyDone
	or a							;Check if the value is 0
	jr nz, .WriteByte				;If not, then write to VRAM
	
	ld a, h							;Otherwise, advance to next "row"
	and a							;Get sign
	ld a, l
	and a, $1F						;Get current position in row ($20 = length of row)

	push bc							;Otherwise, add to total position
	push de
	ld b, a
	ld a, $20
	sub b
	pop bc
	
	add l
	ld l, a
	pop bc
	jr nc, .NoCarryAdd
	inc h
.NoCarryAdd
	jr .CheckDone
	
.WriteByte
	add a, $10						;Convert ASCII values to tile values by adding $10 to each character
	ld [hli], a						;Then write to VRAM
	jr .CheckDone

.CheckDone							;Check if done copying
	ld a, b
	or c
	jr nz, CopyText
	
.CopyDone
	ret

;**********************************************************************************************
;*                               Data                                                         *
;**********************************************************************************************

;$3400-$3B1B: Title screen image data (Length: $071C)
SECTION "TitleGFX", ROM0 [$2000]
TitleTiles:
	incbin "GFX/TITLE.GFX"
TitleMap:
	incbin "GFX/TITLE.MAP"
TitleMapEnd:
LogoTiles:
	incbin "GFX/LOGO.GFX"
LogoMap:
	incbin "GFX/LOGO.MAP"
LogoEnd:
CaveTiles:
	incbin "GFX/CAVE.GFX"
CaveMap:
	incbin "GFX/CAVE.MAP"
CaveMapEnd:
JoeTiles:
	incbin "GFX/JOE.GFX"
JoeTilesEnd:
GhostTiles:
	incbin "GFX/GHOST.GFX"
GhostTilesEnd:
JewelTiles:
	incbin "GFX/JEWEL.GFX"
JewelTilesEnd:
BlockTiles:
	incbin "GFX/BLOCK.GFX"
BlockTilesEnd:
FistTiles:
	incbin "GFX/FIST.GFX"
FistTilesEnd:
LoseTiles:
	incbin "GFX/LOSE.GFX"
LoseTilesEnd:
LoseMap:
	incbin "GFX/LOSE.MAP"
LoseMapEnd:
FontTiles:
	incbin "GFX/FONT.GFX"
FontTilesEnd:

;**********************************************************************************************
;*                               Character frame data                                         *
;**********************************************************************************************
ObjFramesList:
	dw JoeFrames
	dw GhostFrames
	dw JewelFrames

;Indiana Joe tile reference/mapping for frames
JoeFrames:
	db $00, $01, $02, $03, $04, $05, $06, $07		;Stand
	db $00, $01, $02, $03, $04, $05, $06, $08		;Walk (1)
	db $00, $01, $02, $03, $09, $0A, $0B, $0C		;Walk (2)
	db $00, $01, $02, $03, $0D, $0E, $0F, $10		;Walk (3)
	db $00, $01, $02, $03, $11, $12, $13, $14		;Walk (4)
JoeFramesEnd:
;Ghost tile reference/mapping for frames
GhostFrames:
	db $20, $21, $22, $23
GhostFramesEnd:
;Jewel tile reference/mapping for frames
JewelFrames:
	db $24, $25, $26, $27
JewelFramesEnd:
;Introduction text
TextIntro:
db "YOU ARE THE EXPLORER", 0
db "INDIANA JOE.", 0
db "YOU ARE", 0
db "INVESTIGATING AN", 0
db "ANCIENT TEMPLE WHICH", 0
db "HAS JEWELS.", 0
db "BUT THIS TEMPLE IS", 0
db "HAUNTED! IT HAS", 0
db "GHOSTS!", 0
db "COLLECT THE JEWELS!", 0
db "AVOID THE GHOSTS!", 0
db $FF
TextIntroEnd:
;Lose screen text
TextLose:
db "BOOOOOOOOOOOOO!", 0
db "YOU LOSE!", 0
db $FF
TextLoseEnd:
;Win screen text
TextWin:
db "YOU WIN!", 0
db $FF
TextWinEnd:
;Score text
TextScore:
db "SCORE: ", 0
db $FF
TextScoreEnd:

include "SOUND/AUDIO.ASM"								;Audio code and data

;**********************************************************************************************
;*                               RAM Variables                                                *
;**********************************************************************************************
SECTION "Variables", WRAM0[MainRAM]

TimerSec: 					ds 1
TimerFrames:				ds 1
CopyNum:					ds 1
CurInputA: 					ds 1						;D-PAD input
CurInputB: 					ds 1						;Other button input
StartPrev:					ds 1
PlayerX:					ds 2
PlayerY:					ds 2
PlayerAnim:					ds 1
PlayerSpeed:				ds 2
AnimTimer:					ds 1
Enemy1SpeedX:				ds 2
Enemy2SpeedX:				ds 2
Enemy3SpeedX:				ds 2
Enemy1SpeedY:				ds 2
Enemy2SpeedY:				ds 2
Enemy3SpeedY:				ds 2
Enemy1X:					ds 2
Enemy2X:					ds 2
Enemy3X:					ds 2
Enemy1Y:					ds 2
Enemy2Y:					ds 2
Enemy3Y:					ds 2
EnemyCount:					ds 1
CollWSize:					ds 1
CollHSize:					ds 1
CollWTest:					ds 1
CollHTest:					ds 1
Jewel1X:					ds 1
Jewel2X:					ds 1
Jewel3X:					ds 1
Jewel1Y:					ds 1
Jewel2Y:					ds 1
Jewel3Y:					ds 1
JewelCount:					ds 1
JewelsActive:				ds 1
TempObjRAM:					ds 8
TempStartOAM:				ds 1
TempW:						ds 1
TempH:						ds 1
TempBaseX:					ds 1
TempBaseY:					ds 1
TempFrame:					ds 1
TempObjID:					ds 1
TempFlip:					ds 1
XFlip:						ds 1
YFlip:						ds 1
TempTilesCnt:				ds 1
TempTX:						ds 1
TempTY:						ds 1
TempEffTX:					ds 1
TempEffTY:					ds 1
TempTile:					ds 1
TempTileID:					ds 1
TempX:						ds 1
TempY:						ds 1
TempPosX:					ds 2
TempPosY:					ds 2
TempSpeedX:					ds 2
TempSpeedY:					ds 2
Score:						ds 1
LevelNum:					ds 1

SECTION "OAM Variables", WRAM0[OAMRAM]
ds 100

SECTION "Object Sprite Variables", WRAM0[ObjRAM]
ds 100

SECTION "OAM DMA", HRAM
hOAMDMA:
  ds DMARoutineEnd - DMARoutine ; Reserve space to copy the routine to
