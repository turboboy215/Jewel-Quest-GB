def AudioROM equ $4000
def AudioRAM equ $D000
def WaveRAM equ $FF30

SECTION "Audio", ROMX[$4000], BANK[$1]

	jp Init


	jp GetSFXMacro


	jp LoadSong


	jp PlaySongSFX


	jp PlaySong


	jp PlaySFXC1


	jp ClearChVol


	jp MusicOn


	jp CheckVolR1


	jp CheckVolNew


	jp ClearAudio


	jp SetTempo


	jp LoadSFX

SetTempo:
	ld [Tempo], a
	ret

PlaySongSFX:
	call PlaySong
	call PlaySFXC1
	ret

;Check the volume of the right speaker - if it is too low, then muteCheckVolR1:
	ldh a, [rNR50]
	;If volume is 0, then load 0 into B
	and %00000111
	jr z, .CheckVolR10

;Otherwise, decrease and load value into B
	dec a
	or %00001000
	ld b, a
	jp CheckVolL1

;Right volume is 0
.CheckVolR10
	ld b, 0

;Now, check the volume of the left speakerCheckVolL1:
	ldh a, [rNR50]
	;If volume is 0, then load 0 into A
	and %01110000
	jr z, .CheckVolL10

;Otherwise, decrease and load value into A
	sub $10
	jp CtrlCheck


;Left volume is 0
.CheckVolL10
	ld a, 0

;Check if the resulting values are 0 or notCtrlCheck:
	or b
	cp 0
	;If not 0, then load new value into NR50
	jr nz, SetMasterVol

	;Otherwise, set values to 0
	call ClearChVol

;Load the value into master volume controlSetMasterVol:
	ldh [rNR50], a
	ret


;Clear all audioClearAudio:
	xor a
	ldh [rNR51], a
	ld [MasterPan], a
	ldh [rNR50], a
	ld [PlayFlag], a
	ret


;Clear each channel's volumeClearChVol:
	ld a, 0
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	ld [PlayFlag], a
	ret


;Turn music onMusicOn:
	ld a, $FF
	ld [PlayFlag], a
	ret


;Check the status of the audioCheckVolNew:
	;Set the music play flag
	call MusicOn
	;Check the master volume control
	ldh a, [rNR50]
	cp 0
	;If not 0, then check L and R volumes again
	jr nz, CheckVolR2

	;Otherwise, set volumes off
	ld a, %10001000
	ldh [rNR50], a
	ret


;Check the volume of the right speaker again - if it is not full, then set to maxCheckVolR2:
	and %00000111
	cp %00000111
	jr z, CheckVolL2

	;Increase volume
	add 1
	ld b, a


;Check the volume of the left speaker againCheckVolL2:
	ldh a, [rNR50]
	;If at full volume
	and %01110000
	srl a
	srl a
	srl a
	srl a
	cp %00000111
	ret z

	;...Then increase volume by 1
	add 1
	sla a
	sla a
	sla a
	sla a
	
	;Set all volume bits
	or b
	or %10001000
	ldh [rNR50], a
	ret


;Get SFX from numberLoadSFX:
	add a
	add a
	ld hl, SFXTab
	add l
	ld l, a
	jr nc, GetSFX

	inc h


;Get first channel macro valueGetSFX:
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .GetSFXP2

	call PlaySFXFromMacro


;Get second channel macro value
.GetSFXP2
	inc hl
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .GetSFXP3

	call PlaySFXFromMacro


;Get third channel macro value
.GetSFXP3
	inc hl
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .GetSFXP4

	call PlaySFXFromMacro


;Get fourth channel macro value
.GetSFXP4
	inc hl
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .ExitSFX

	call PlaySFXFromMacro


;If no channels used, then return
.ExitSFX
	ret

PlaySFXFromMacro:
	push hl
	call GetSFXMacro
	pop hl
	ret


;Clear RAM and copy waveformInit:

	;Disable audio
	ld a, 0
	ldh [rNR52], a
	nop
	ldh [rNR52], a
	
	;Clear RAM values
	ld [C1SFXPos], a
	ld [C1SFXPos+1], a
	ld [C2SFXPos], a
	ld [C2SFXPos+1], a
	ld [C3SFXPos], a
	ld [C3SFXPos+1], a
	ld [C4SFXPos], a
	ld [C4SFXPos+1], a
	ld [C1PlayFlag], a
	ld [C2PlayFlag], a
	ld [C3PlayFlag], a
	ld [C4PlayFlag], a
	
	;Set default tempo
	ld a, 255
	ld [Tempo], a

	;Set timer/beat counter
	ld a, 1
	ld [BeatCounter], a
	
	;Copy the waveform into wave RAM
	ld de, WaveRAM
	ld hl, Waveform
	ld b, $10

.CopyWave
	ld a, [hl]
	ld [de], a
	inc hl
	inc de
	dec b
	jr nz, .CopyWave

	call ChannelInit
	ret


;Load songLoadSong:
;Get song number from A
	ld l, a
	ld h, $00
	
	;Get song address
	;x10 bytes = Song entry length
	add hl, hl
	ld d, h
	ld e, l
	add hl, hl
	add hl, hl
	add hl, de
	;Add to the song table
	ld de, SongTab
	add hl, de
	
	;Load starting positions and note length pointers into RAM
	ld a, [hl+]
	ld [C1Pos], a
	ld a, [hl+]
	ld [C1Pos+1], a
	ld a, [hl+]
	ld [C2Pos], a
	ld a, [hl+]
	ld [C2Pos+1], a
	ld a, [hl+]
	ld [C3Pos], a
	ld a, [hl+]
	ld [C3Pos+1], a
	ld a, [hl+]
	ld [C4Pos], a
	ld a, [hl+]
	ld [C4Pos+1], a
	ld a, [hl+]
	ld [NoteLens], a
	ld a, [hl+]
	ld [NoteLens+1], a
	;Set default note lengths
	ld a, 1
	ld [C1Len], a
	ld [C2Len], a
	ld a, 2
	ld [C3Len], a
	ld [C4Len], a
	;Enable play flags
	ld a, 3
	ld [C1PlayFlag], a
	ld [C2PlayFlag], a
	ld [C3PlayFlag], a
	ld [C4PlayFlag], a
	ld [PlayFlag], a
	ld a, 255
	ld [Tempo], a
	ld a, 1
	ld [BeatCounter], a
ChannelInit:
	;Turn on channels
	ld a, %10001111
	ldh [rNR52], a
	nop
	nop
	ldh [rNR52], a
	;Initialize CH1 sweep
	ld a, %00001000
	ldh [rNR10], a
	
	;Set panning and master volume
	ld a, %11111111
	ldh [rNR51], a
	ld [MasterPan], a
	ld a, %01110111
	ldh [rNR50], a
	
	;Turn on CH3 DAC
	ld a, %10000000
	ldh [rNR30], a
	
	;Clear all channels' volume
	xor a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	
	;Disable macro transpose
	ld [C1MacroTrans], a
	ld [C2MacroTrans], a
	ld [C3MacroTrans], a
	ld [C4MacroTrans], a
	
	;Clear macro flag
	ld [C1InMacro], a
	ld [C2InMacro], a
	ld [C3InMacro], a
	ld [C4InMacro], a
	
	;Also disable Ch4 vibrato sequence
	ld [C4VibSeqDelay], a
	ret

PlaySong:
	;Check to see if the song is currently playing
	ld a, [PlayFlag]
	and a
	ret z

	;Get the current song tempo and number of beats
	ld a, [Tempo]
	ld b, a
	ld a, [BeatCounter]
	add b
	ld [BeatCounter], a
	;Don't update if no overflow
	ret nc
StartC1:
	;Set current channel number (0)
	xor a
	ld [CurChan], a
	;Save current code position for restart
	ld hl, CurRestartPos
	ld de, StartC1
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C1MacroTrans]
	ld [CurTrans], a
	ld hl, C1PlayFlag
	ld de, rNR11
	call GetNextByte
	;Check if the current channel is active
	ld a, [C1PlayFlag]
	and %00000001
	;If not, then skip to channel 2
	jp z, StartC2

	;Check if the current channel is active for SFX
	ld a, [C1SFXPos+1]
	and a
	;If so, then skip to channel 2
	jp nz, StartC2

	;Get instrument parameter bytes
	;Process the channel envelope from sequence
	ld hl, C1EnvSeqDelay
	ld de, C1EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR12
	call CheckEnvSeqDelay
	ld de, C1EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	ld hl, C1PlayFlag
	ld de, rNR13
	call SetPerLo
	;Process the channel vibrato from sequence
	ld hl, C1VibSeqDelay
	ld de, C1VibSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	;Get the low of the frequency
	ld de, C1Freq+1
	call CheckVibSeqDelay
	ld de, C1VibSeq
	;Store updated vibrato sequence pos. in RAM
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Check delay for pitch modulation sequence
	ld a, [C1ModSeqDelay]
	and a
	;If value is 0, then skip
	jr z, StartC2

.C1ProcessModSeq
	;Otherwise, decrement
	dec a
	ld [C1ModSeqDelay], a
	and a
	;If delay has not yet finished, then return
	jr nz, StartC2

	;Load sequence pointer from RAM
	ld a, [C1ModSeq]
	ld c, a
	ld a, [C1ModSeq+1]
	ld b, a
	ld a, [bc]
	;If reached loop point (FF)...
	cp $FF
	jr z, .C1ProcessModLoop

	;Otherwise, store the next value as new delay in RAM
	ld [C1ModSeqDelay], a
	inc bc
	;Next byte = note frequency change
	ld a, [bc]
	;Add to current note
	ld e, a
	ld a, [CurNoteC1]
	add e
	push af
	;Get the high frequency byte and add it
	ld de, FreqsHi
	add e
	ld e, a
	jr nc, .C1ProcessModSeq2

	inc d

.C1ProcessModSeq2
	ld a, [de]
	ld [C1Freq], a
	pop af
	;Now get the low frequency byte and add it
	ld de, FreqsLo
	add e
	ld e, a
	jr nc, .C1ProcessModSeq3

	inc d

.C1ProcessModSeq3
	ld a, [de]
	ld [C1Freq+1], a
	;Advance to the next part of the sequence
	inc bc
	;Store the updated pointer in RAM
	ld a, c
	ld [C1ModSeq], a
	ld a, b
	ld [C1ModSeq+1], a
	jp StartC2


;Go to pitch modulation sequence loop
.C1ProcessModLoop
	;Reset the delay to 1
	ld a, 1
	ld [C1ModSeqDelay], a
	;Go to the position in the following pointer (2 bytes)
	inc bc
	ld a, [bc]
	ld [C1ModSeq], a
	inc bc
	ld a, [bc]
	ld [C1ModSeq+1], a
StartC2:
	;Set current channel number (1)
	ld a, 1
	ld [CurChan], a
	;Save current code position for restart	
	ld hl, CurRestartPos
	ld de, StartC2
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C2MacroTrans]
	ld [CurTrans], a
	ld hl, C2PlayFlag
	ld de, rNR21
	call GetNextByte
	;Check if the current channel is active
	ld a, [C2PlayFlag]
	and %00000001
	;If not, then skip to channel 3
	jp z, StartC3

	;Check if the current channel is active for SFX
	ld a, [C2SFXPos+1]
	and a
	;If so, then skip to channel 3
	jp nz, StartC3

	;Get instrument parameter bytes
	;Process the channel envelope from sequence
	ld hl, C2EnvSeqDelay
	ld de, C2EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR22
	call CheckEnvSeqDelay
	ld de, C2EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	ld hl, C2PlayFlag
	ld de, rNR23
	call SetPerLo
	;Process the channel vibrato from sequence
	ld hl, C2VibSeqDelay
	ld de, C2VibSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	;Get the low of the frequency
	ld de, C2Freq+1
	call CheckVibSeqDelay
	ld de, C2VibSeq
	;Store updated vibrato sequence pos. in RAM
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Check delay for pitch modulation sequence
	ld a, [C2ModSeqDelay]
	and a
	;If value is 0, then skip
	jr z, StartC3

.C2ProcessModSeq
	;Otherwise, decrement
	dec a
	ld [C2ModSeqDelay], a
	and a
	;If delay has not yet finished, then return
	jr nz, StartC3

	;Load sequence pointer from RAM
	ld a, [C2ModSeq]
	ld c, a
	ld a, [C2ModSeq+1]
	ld b, a
	ld a, [bc]
	cp $FF
	jr z, .C2ProcessModLoop

	;Otherwise, store the next value as new delay in RAM
	ld [C2ModSeqDelay], a
	inc bc
	;Next byte = note frequency change
	ld a, [bc]
	;Add to current note
	ld e, a
	ld a, [CurNoteC2]
	add e
	push af
	;Get the high frequency byte and add it
	ld de, FreqsHi
	add e
	ld e, a
	jr nc, .C2ProcessModSeq2

	inc d

.C2ProcessModSeq2
	ld a, [de]
	ld [C2Freq], a
	pop af
	;Now get the low frequency byte and add it
	ld de, FreqsLo
	add e
	ld e, a
	jr nc, .C2ProcessModSeq3

	inc d

.C2ProcessModSeq3
	ld a, [de]
	ld [C2Freq+1], a
	;Advance to the next part of the sequence
	inc bc
	;Store the updated pointer in RAM
	ld a, c
	ld [C2ModSeq], a
	ld a, b
	ld [C2ModSeq+1], a
	jp StartC3


;Go to pitch modulation sequence loop
.C2ProcessModLoop
	;Reset the delay to 1
	ld a, 1
	ld [C2ModSeqDelay], a
	;Go to the position in the following pointer (2 bytes)
	inc bc
	ld a, [bc]
	ld [C2ModSeq], a
	inc bc
	ld a, [bc]
	ld [C2ModSeq+1], a
StartC3:
	;Set current channel number (2)
	ld a, 2
	ld [CurChan], a
	;Save current code position for restart
	ld hl, CurRestartPos
	ld de, StartC3
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C3MacroTrans]
	ld [CurTrans], a
	ld hl, C3PlayFlag
	ld de, rNR31
	call GetNextByte
	;Check if the current channel is active
	ld a, [C3PlayFlag]
	and %00000001
	;If not, then skip to channel 4
	jp z, StartC4

	;Check if the current channel is active for SFX
	ld a, [C3SFXPos+1]
	and a
	;If so, then skip to channel 3
	jp nz, StartC4

	;Get instrument parameter bytes
	;Set period
	ld hl, C3PlayFlag
	ld de, rNR33
	call SetPerLo
	;Process the channel envelope from sequence
	ld hl, C3EnvSeqDelay
	ld de, C3EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR32
	call CheckEnvSeqDelay
	ld de, C3EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Process the channel vibrato from sequence
	ld hl, C3VibSeqDelay
	ld de, C3VibSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	;Get the low of the frequency
	ld de, C3Freq+1
	call CheckVibSeqDelay
	ld de, C3VibSeq
	;Store updated vibrato sequence pos. in RAM
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Check delay for pitch modulation sequence
	ld a, [C3ModSeqDelay]
	and a
	;If value is 0, then skip
	jr z, StartC4

.C3ProcessModSeq
	;Otherwise, decrement
	dec a
	ld [C3ModSeqDelay], a
	and a
	;If delay has not yet finished, then return
	jr nz, StartC4

	;Load sequence pointer from RAM
	ld a, [C3ModSeq]
	ld c, a
	ld a, [C3ModSeq+1]
	ld b, a
	ld a, [bc]
	;If reached loop point (FF)...
	cp $FF
	jr z, .C3ProcessModLoop

	;Otherwise, store the next value as new delay in RAM
	ld [C3ModSeqDelay], a
	inc bc
	;Next byte = note frequency change
	ld a, [bc]
	;Add to current note
	ld e, a
	ld a, [CurNoteC3]
	add e
	push af
	;Get the high frequency byte and add it
	ld de, FreqsHi
	add e
	ld e, a
	jr nc, .C3ProcessModSeq2

	inc d

.C3ProcessModSeq2
	ld a, [de]
	ld [C3Freq], a
	pop af
	;Now get the low frequency byte and add it
	ld de, FreqsLo
	add e
	ld e, a
	jr nc, .C2ProcessModSeq3

	inc d

.C2ProcessModSeq3
	ld a, [de]
	ld [C3Freq+1], a
	;Advance to the next part of the sequence
	inc bc
	;Store the updated pointer in RAM
	ld a, c
	ld [C3ModSeq], a
	ld a, b
	ld [C3ModSeq+1], a
	jp StartC4


;Go to pitch modulation sequence loop
.C3ProcessModLoop
	;Reset the delay to 1
	ld a, 1
	ld [C3ModSeqDelay], a
	;Go to the position in the following pointer (2 bytes)
	inc bc
	ld a, [bc]
	ld [C3ModSeq], a
	inc bc
	ld a, [bc]
	ld [C3ModSeq+1], a
StartC4:
	;Set current channel number (3)
	ld a, 3
	ld [CurChan], a
	;Save current code position for restart
	ld hl, CurRestartPos
	ld de, StartC4
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C4MacroTrans]
	ld [CurTrans], a
	ld hl, C4PlayFlag
	ld de, rNR41
	call GetNextByte
	;Check if the current channel is active
	ld a, [C4PlayFlag]
	and %00000001
	;If not, then set period and return
	jr z, .C4SetPeriod

	;Check if the current channel is active for SFX
	ld a, [C4SFXPos+1]
	and a
	;If value is 0, then skip
	jp nz, .C4SetPeriod

	;Get instrument parameter bytes
	;Process the channel envelope from sequence
	ld hl, C4EnvSeqDelay
	ld de, C4EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR42
	call CheckEnvSeqDelay
	ld de, C4EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Now process the vibrato envelope
	call C4CheckVibSeqDelay

.C4SetPeriod
	ld hl, C4PlayFlag
	ld de, rNR43
	call SetPerLo
	ret

CheckEnvSeqDelay:
;Check if envelope sequence is enabled
	ld a, [hl]
	and a
	ret z

	;Otherwise, decrement
	dec [hl]
	;If delay has not yet finished, then return
	ret nz

	;Otherwise, check if reached end of pattern (value FF)
	ld a, [bc]
	cp $FF
	;If not, then keep going
	jr nz, ProcessEnvSeq

	;Otherwise, then disable envelope sequence
	ld a, 0
	ld [hl], a
	ret

ProcessEnvSeq:
	;Write the volume to the register
	ld [de], a
	;Get next byte
	inc bc
	ld a, [bc]
	;Set delay for next envelope value
	ld [hl], a
	;Now go to frequency...
	ld a, l
	sub 6
	ld l, a
	jr nc, .ProcessEnvSeq2

	dec h

.ProcessEnvSeq2
	;and reset the trigger
	ld a, [hl]
	or $80
	ld [hl], a
	;Then store the current duty into RAM
	ld a, l
	add 4
	ld l, a
	jr nc, .ProcessEnvSeq3

	inc h

.ProcessEnvSeq3
	ld a, [de]
	ld [hl], a
	;Go to next byte in sequence
	inc bc
	ret

CheckVibSeqDelay:
	;If value is 0, then return
	ld a, [hl]
	and a
	ret z

	;If delay is more than 1, then return (wait)
	dec [hl]
	ret nz

	;Load delay into RAM
	inc bc
	ld a, [bc]
	push hl
	ld [hl], a
	dec bc
	;Load current frequency from RAM
	ld a, [de]
	ld l, a
	dec de
	ld a, [de]
	ld h, a
	;Now get vibrato value
	ld a, [bc]
	;Is it a stop command?
	cp $7E
	jr nz, ProcessVibSeq

	pop hl
	ret

ProcessVibSeq:
	;Is it a loop command?
	cp $7D
	;If so, then keep checking
	jr z, ProcessVibLoop

	;Is it negative?
	cp $7F
	;If so, then subtract from frequency
	jr nc, .SubVibFreq

;Otherwise, add to frequency
.AddVibFreq
	add l
	ld l, a
	jr nc, .ProcessVibSeq2

	inc h

.ProcessVibSeq2
	jr .ProcessVibSeq3

.SubVibFreq
	add l
	ld l, a
	jr c, .ProcessVibSeq3

	dec h

.ProcessVibSeq3
	;Load the new frequency into RAM
	ld a, h
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	
	;Go to the next entry and return
	inc bc
	inc bc
	pop hl
	ret

ProcessVibLoop:
	;Get the next 2 bytes (pointer) and jump to position
	inc bc
	ld a, [bc]
	push af
	inc bc
	ld a, [bc]
	ld b, a
	pop af
	ld c, a
	pop hl
	;Reset the delay to 1
	ld a, 1
	ld [hl], a
	ret

GetNextByte:
	;Check to see if the current channel is 1-3
	ld a, [hl]
	and %00000010
	;Return if it is 4
	ret z

	;Otherwise, then go to channel note length
	inc hl
	dec [hl]
	;Return if still playing note
	ret nz

	;Otherwise, then get next command
	inc hl
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, [bc]
	
	;Load the current command value into RAM
	ld [CurCmd], a
	;Mask out the highest bit
	and %01111111
	
	;Is it a note?
	cp $5F
	;If not, then it must be a command
	jp nc, GetVCMD

	;Save current audio register value
	push de
	
	;Get the current transpose
	ld de, CurTrans
	ld a, [de]
	ld d, a
	;And get the current byte
	ld a, [bc]
	;Mask out the highest bit
	and %01111111
	;Add the transpose
	add d
	ld d, a
	
	;Save the current note value
	push af
	ld a, [CurChan]CheckC1:
	;Is the channel 1?
	cp 0
	;If not, then skip to channel 2
	jr nz, CheckC2

	;Otherwise, then save current Ch1 note
	ld a, d
	ld [CurNoteC1], a
CheckC2:
	;Is the channel 2?
	cp 1
	;If not, then skip to channel 3
	jr nz, CheckC3

	ld a, d
	ld [CurNoteC2], a
CheckC3:
	;Is the channel 3?
	cp 2
	;If not, then skip to the next part
	jr nz, GetFreq

	ld a, d
	ld [CurNoteC3], a

;Get the current frequencyGetFreq:
	pop af
	ld de, FreqsHi
	add e
	ld e, a
	jp nc, .GetFreq2

	inc d

.GetFreq2
	ld a, [de]
	;Load that value into RAM
	inc hl
	ld [hl], a
	;Get current transpose value
	ld de, CurTrans
	ld a, [de]
	ld d, a
	;And get current note again
	ld a, [bc]
	;Mask out the highest bit
	and %01111111
	;Add the transpose
	add d
	;Now get the low byte from table
	ld de, FreqsLo
	add e
	ld e, a
	jr nc, .GetFreq3

	inc d

.GetFreq3
	ld a, [de]
	inc hl
	ld [hl], a
	
;Now get the note length from the next byteGetLen:	
	inc bc
	ld a, [bc]
	;Mask out the upper 4 bits to get the note length index
	and %00001111
	push hl
	;Get the address of the current note length
	ld hl, NoteLens+1
	ld d, [hl]
	dec hl
	ld e, [hl]
	pop hl
	add e
	ld e, a
	jr nc, .GetLen2

	inc d

.GetLen2
	ld a, [de]
	;Store the current note length value in RAM
	ld de, -4
	add hl, de
	ld [hl], a
	
;Now get the instrument from the first bit of byte 1 and lower 4 bits of byte 2GetInst:
	;Get the first note byte again
	ld a, [CurCmd]
	;If bit is set, then add 32 to total (instrument is +16)
	and %10000000
	srl a
	srl a
	ld d, a
	;Now get the second byte again
	ld a, [bc]
	;Mask out the lower 4 bits to get the instrument number
	and %11110000
	;Shift right to calculate the instrument offset (12 x instrument number)
	srl a
	srl a
	srl a
	;Add the extra 32 bytes if present
	add d
	
	;Get the current instrument offset in table
	push hl
	ld hl, InsTab
	add l
	ld l, a
	jr nc, .GetInst2

	inc h

.GetInst2
	;Load the current instrument address into RAM
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	
	;Update the position and load it into RAM
	inc bc
	inc hl
	ld [hl], c
	inc hl
	ld [hl], b
	ld b, d
	ld c, e
	pop de
	inc hl
	;Instrument byte 1 - Period control
	ld a, [bc]
	or [hl]
	ld [hl], a
	inc hl
	inc hl
	inc hl
	;Instrument byte 2 - Duty
	inc bc
	ld a, [bc]
	ld [hl], a
	;Instrument byte 3 - Initial volume/envelope
	inc bc
	inc de
	inc hl
	ld a, [bc]
	ld [hl], a
	inc hl
	inc hl
	inc bc
	;Instrument byte 4 - Volume/envelope sequence delay
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	;Instrument byte 5-6 = Volume/envelope sequence pointer
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	;Instrument byte 7 = Vibrato sequence delay
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	;Instrument byte 8-9 = Vibrato sequence pointer
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	inc hl
	;Instrument byte 10 = Pitch modulation sequence delay
	ld a, [bc]
	ld [hl], a
	inc bc
	inc hl
	;Instrument byte 11-12 = Pitch modulation sequence pointer
	ld a, [bc]
	ld [hl], a
	inc bc
	inc hl
	ld a, [bc]
	ld [hl], a
	ret


;Set frequency/period (low)SetPerLo:
;Check if channel is active
	ld a, [hl]
	and %00000001
	;Return if not active
	ret z

	;Get second byte of frequency (period low)
	ld bc, 5
	add hl, bc
	ld a, e
	;Go to another method if channel 4
	cp LOW(rNR43)
	jp z, SetC4Freq

	;Otherwise, load the period low into register NRx3
	ld a, [hl]
	ld [de], a
CheckPerTrigger:
	;Now check the period high
	dec hl
	inc de
	;Save the period address and RAM location
	push de
	push hl
	;If trigger is set, then don't set the duty and envelope
	ld a, [hl]
	and %10000000
	jr z, SetPerHi

	;Set duty from RAM value
	ld bc, 3
	add hl, bc
	dec de
	dec de
	dec de
	ld a, [hl]
	ld [de], a
	;Set envelope from RAM value
	inc hl
	inc de
	ld a, [hl]
	ld [de], a
SetPerHi:
;Set period (high)
	;Load the period low (with trigger) value from RAM
	pop hl
	pop de
	ld a, [hl]
	ld [de], a
	
	;Clear the trigger in RAM
	and %01111111
	ld [hl], a
	ret

SetC4Freq:
	;Load the current noise frequency from RAM variable into Ch4 RAM and NR43
	ld a, [CurNoise]
	ld [C4Freq+1], a
	ld [de], a
	;Then do the rest
	jr CheckPerTrigger
C4CheckVibSeqDelay:
	;If value is 0, then return
	ld a, [C4VibSeqDelay]
	and a
	ret z

	;Otherwise, decrement
	dec a
	ld [C4VibSeqDelay], a
	and a
	ret nz

	;Load noise vibrato pointer from RAM
	ld a, [C4VibSeq]
	ld l, a
	ld a, [C4VibSeq+1]
	ld h, a
	ld a, [hl]
	;Is it a stop command?
	cp $7E
	;Then return
	ret z

	;Is it a loop command?
	cp $7D
	;If so, then keep checking
	jr z, C4ProcessVibLoop

	;Otherwise, set the current noise frequency from sequence
	ld [CurNoise], a
	inc hl
	ld a, [hl]
	ld [C4VibSeqDelay], a
	inc hl
	;Store the new delay and updated pointer in RAM
	ld a, l
	ld [C4VibSeq], a
	ld a, h
	ld [C4VibSeq+1], a
	ret

C4ProcessVibLoop:
	;Reset the delay to 1
	ld a, 1
	ld [C4VibSeqDelay], a
	;Get the next 2 bytes (pointer) and jump to position
	inc hl
	ld a, [hl]
	ld [C4VibSeq], a
	inc hl
	ld a, [hl]
	ld [C4VibSeq+1], a
	ret

VCMDTable:
	dw EventTie			;$60
	dw EventStop			;$61
	dw EventJump			;$62
	dw EventNoise		;$63
	dw EventMacro		;$64
	dw EventMacroRet		;$65
	dw EventCondFlag		;$66
	dw EventGlobalPan	;$67
	dw EventNoteLens		;$68
	dw EventTempo		;$69
	dw EventC1Pan		;$6A
	dw EventC2Pan		;$6B
	dw EventC3Pan		;$6C
	dw EventC4Pan		;$6D
GetVCMD:
;Get the current voice command (VCMD)
	sub $60
	add a
	push hl
	;Increment the channel note length/delay
	dec hl
	dec hl
	inc [hl]
	;Get the pointer to the VCMD
	ld hl, VCMDTable+1
	add l
	ld l, a
	jr nc, .GetVCMD2

	inc h

.GetVCMD2
	ld a, [hl]
	dec hl
	ld l, [hl]
	ld h, a
	jp hl
EventTie:
;Delay the next note by length, increasing note length;Parameters: -x (- = unused, x = length)
	;Get the note lengths pointer
	ld hl, NoteLens+1
	ld a, [hl]
	dec hl
	ld l, [hl]
	ld h, a
	inc bc
	ld a, [bc]
	;Mask out the upper 4 bits to get the length index
	and %00001111
	add l
	ld l, a
	jr .EventTie2

	inc h

.EventTie2
	;Get the note length from the pointer
	ld a, [hl]
	pop hl
	;Add the length to the current note length
	ld de, -2
	add hl, de
	ld [hl], a
	;Update the pointer
	inc bc
	inc hl
	jp UpdatePtr
EventStop:
	;Stop the channel
	pop hl
	;Set the channel play flag to 0
	ld bc, -3
	add hl, bc
	ld a, 0
	ld [hl], a
	ret
EventJump:
;Jump to the following pointer (used for looping);Parameters: xx xx (x = Pointer)
	;Set the channel note length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Get the pointer from the next 2 values and load into RAM
	inc bc
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	jp GotoRestart
EventNoise:
;Change the noise frequency value (NR43);Parameters: xx (X = Value)
	pop hl
	;Get next noise parameter and load it into RAM
	inc bc
	ld a, [bc]
	ld [CurNoise], a
	;Set channel note length to 1
	ld de, -2
	add hl, de
	ld a, 1
	;Update pointer
	ld [hl+], a
	inc bc
	call UpdatePtr
	jp GotoRestart
EventMacro:
;Go to a macro (subroutine) with transpose for specified number of times;Parameters: xx yy zz (X = Macro number, Y = Transpose, Z = Number of times);(Note: 1 level only)
	;Set channel length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Then get macro number from parameter byte
	inc bc
	ld a, [bc]
	sla a
	jr nc, .EventMacro2
	;Add to macro table
	ld de, SongMacroTab
	inc d
	jr .EventMacro3

.EventMacro2
	;Add to macro table
	ld de, SongMacroTab

.EventMacro3
	add e
	ld e, a
	jr nc, .EventMacro4

	inc d

.EventMacro4
	ld a, [de]
	;Load the macro position in RAM
	ld [hl+], a
	inc de
	ld a, [de]
	ld [hl+], a
	;Now get the macro transpose value and load it into RAM
	ld d, h
	ld e, l
	ld a, $10
	add e
	ld e, a
	jr nc, .EventMacro5

	inc d

.EventMacro5
	inc bc
	ld a, [bc]
	ld [de], a
	inc de
	;Now check the macro flag in RAM
	ld a, [de]
	and a
	;If 0, then get the times in macro
	jr z, .EventMacro6

	inc bc
	jr .EventMacro7

.EventMacro6
	ld a, 1
	ld [de], a
	;Now get the number of times in macro and load into RAM (times left)
	dec de
	dec de
	inc bc
	ld a, [bc]
	;Subtract 1 to get actual number
	sub 1
	ld [de], a
	inc de
	inc de

.EventMacro7
	;Now store the address to return from the macro into RAM
	inc bc
	inc de
	ld a, c
	ld [de], a
	inc de
	ld a, b
	ld [de], a
	jp GotoRestart
EventMacroRet:
;Return from the current macro
	inc bc
	;Set channel length flag to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Now check for macro times left
	ld d, h
	ld e, l
	ld a, $11
	add e
	ld e, a
	jr nc, .EventMacroRet2

	inc d

.EventMacroRet2
	ld a, [de]
	and a
	jr z, EventMacroRetEnd

	;Otherwise, subtract 1 and jump to macro start
	sub 1
	ld [de], a
	inc de
	inc de
	inc de
	;Update the position in RAM (use macro return and subtract 4 to get start position)
	ld a, [de]
	sub 4
	ld [hl+], a
	inc de
	ld a, [de]
	jr nc, .EventMacroRet3

	sub 1

.EventMacroRet3
	;Jump to the macro start position
	ld [hl], a
	jp GotoRestart

EventMacroRetEnd:
	;Reset macro transpose to 0
	inc de
	ld a, 0
	;And macro flag to 0
	ld [de], a
	inc de
	ld [de], a
	;Set position to return from macro (from RAM)
	inc de
	ld a, [de]
	ld [hl+], a
	inc de
	ld a, [de]
	ld [hl], a
	;Go to start code
	jp GotoRestart
EventCondFlag:
;Set a conditional flag (not used by the driver);Parameters: xx (X = Value)
	inc bc
	ld a, [bc]
	ld [LoopFlag], a
	;Set channel note length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Update the channel pointer
	inc bc
	call UpdatePtr
	jp GotoRestart
EventGlobalPan:
;Set global panning;Parameters: xx (X = Value, see NR51 usage)
	inc bc
	ld a, [bc]
	ldh [rNR51], a
	ld [MasterPan], a

;Reset the note by setting the channel length to 1ResetNote:
	;Set channel note length to 1
	inc bc
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Update the channel pointer
	call UpdatePtr
	jr GotoRestart
EventC1Pan:
;Set channel 1 panning;Parameters: xx (X = Value, only channel 1 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 1 bits
	ld a, [MasterPan]
	and %11101110
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote
EventC2Pan:
;Set channel 2 panning;Parameters: xx (X = Value, only channel 2 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 2 bits
	ld a, [MasterPan]
	and %11011101
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote
EventC3Pan:
;Set channel 3 panning;Parameters: xx (X = Value, only channel 3 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 3 bits
	ld a, [MasterPan]
	and %10111011
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote
EventC4Pan:
;Set channel 4 panning;Parameters: xx (X = Value, only channel 4 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 4 bits
	ld a, [MasterPan]
	and %01110111
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote
EventNoteLens:
;Set note lengths from the following pointer (for all channels);Parameters: xx xx (X = Pointer)
	inc bc
	ld a, [bc]
	ld [NoteLens], a
	inc bc
	ld a, [bc]
	ld [NoteLens+1], a
	;Set channel note length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Update the channel pointer
	inc bc
	call UpdatePtr
	jr GotoRestart
EventTempo:
;Set the tempo;Parameters: x (X = Value)
	inc bc
	ld a, [bc]
	ld [Tempo], a
	;Set channel note length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Update the channel pointer
	inc bc
	call UpdatePtr
	jr GotoRestart
UpdatePtr:
	ld [hl], c
	inc hl
	ld [hl], b
	ret

GotoRestart:
	pop hl
	ld de, CurRestartPos
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
	jp hl

FreqsLo:
	db LOW($009D), LOW($0107), LOW($016B), LOW($01CA), LOW($0223), LOW($0278), LOW($02C7), LOW($0312), LOW($0359), LOW($039C), LOW($03DB), LOW($0417)
	db LOW($044F), LOW($0484), LOW($04B6), LOW($04E5), LOW($0512), LOW($053C), LOW($0564), LOW($0589), LOW($05AD), LOW($05CE), LOW($05EE), LOW($060C)
	db LOW($0628), LOW($0642), LOW($065B), LOW($0673), LOW($0689), LOW($069E), LOW($06B2), LOW($06C5), LOW($06D7), LOW($06E7), LOW($06F7), LOW($0706)
	db LOW($0714), LOW($0721), LOW($072E), LOW($073A), LOW($0745), LOW($074F), LOW($0759), LOW($0763), LOW($076C), LOW($0774), LOW($077C), LOW($0783)
	db LOW($078A), LOW($0791), LOW($0797), LOW($079D), LOW($07A3), LOW($07A8), LOW($07AD), LOW($07B1), LOW($07B6), LOW($07BA), LOW($07BE), LOW($07C2)
	db LOW($07C5), LOW($07C9), LOW($07CC), LOW($07CF), LOW($07D2), LOW($07D4), LOW($07D7), LOW($07D9), LOW($07DB), LOW($07DD), LOW($07DF), LOW($07E1)
	db LOW($07E3), LOW($07E5), LOW($07E6), LOW($07E8), LOW($07E9), LOW($07EA), LOW($07EC), LOW($07ED), LOW($07EE), LOW($07EF), LOW($07F0), LOW($07F1)
	db LOW($07F2), LOW($07F3), LOW($07F3), LOW($07F4), LOW($07F5), LOW($07F5), LOW($07F7), LOW($07F7), LOW($07F8), LOW($07F8), LOW($07FA), LOW($07FA)
FreqsHi:
	db HIGH($009D), HIGH($0107), HIGH($016B), HIGH($01CA), HIGH($0223), HIGH($0278), HIGH($02C7), HIGH($0312), HIGH($0359), HIGH($039C), HIGH($03DB), HIGH($0417)
	db HIGH($044F), HIGH($0484), HIGH($04B6), HIGH($04E5), HIGH($0512), HIGH($053C), HIGH($0564), HIGH($0589), HIGH($05AD), HIGH($05CE), HIGH($05EE), HIGH($060C)
	db HIGH($0628), HIGH($0642), HIGH($065B), HIGH($0673), HIGH($0689), HIGH($069E), HIGH($06B2), HIGH($06C5), HIGH($06D7), HIGH($06E7), HIGH($06F7), HIGH($0706)
	db HIGH($0714), HIGH($0721), HIGH($072E), HIGH($073A), HIGH($0745), HIGH($074F), HIGH($0759), HIGH($0763), HIGH($076C), HIGH($0774), HIGH($077C), HIGH($0783)
	db HIGH($078A), HIGH($0791), HIGH($0797), HIGH($079D), HIGH($07A3), HIGH($07A8), HIGH($07AD), HIGH($07B1), HIGH($07B6), HIGH($07BA), HIGH($07BE), HIGH($07C2)
	db HIGH($07C5), HIGH($07C9), HIGH($07CC), HIGH($07CF), HIGH($07D2), HIGH($07D4), HIGH($07D7), HIGH($07D9), HIGH($07DB), HIGH($07DD), HIGH($07DF), HIGH($07E1)
	db HIGH($07E3), HIGH($07E5), HIGH($07E6), HIGH($07E8), HIGH($07E9), HIGH($07EA), HIGH($07EC), HIGH($07ED), HIGH($07EE), HIGH($07EF), HIGH($07F0), HIGH($07F1)
	db HIGH($07F2), HIGH($07F3), HIGH($07F3), HIGH($07F4), HIGH($07F5), HIGH($07F5), HIGH($07F7), HIGH($07F7), HIGH($07F8), HIGH($07F8), HIGH($07FA), HIGH($07FA)
GetSFXMacro:
	;Get SFX macro pointer from table
	ld hl, SFXMacroTab
	sla a
	add l
	ld l, a
	jr nc, InitSFX

	inc h
InitSFX:
	;Go to SFX pointer
	ld a, [hl]
	ld c, a
	inc hl
	ld a, [hl]
	ld b, a
	;Enable all channels
	ld a, %10001111
	ldh [rNR52], a
	;Check the channel number
	ld a, [bc]
	inc bc
	
	;Is it channel 2?
	cp 1
	jr z, InitSFXC2

	;Is it channel 3?
	cp 2
	jr z, InitSFXC3

	;Is it channel 4?
	cp 3
	jr z, InitSFXC4

	;Otherwise, it is channel 1InitSFXC1:
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %00010001
	or d
	ld [MasterSFXPan], a
	;Enable SFX playback with flag
	ld a, [C1PlayFlag]
	and %11111110
	ld [C1PlayFlag], a
	;Go to SFX position from RAM
	ld a, c
	ld [C1SFXPos], a
	ld a, b
	ld [C1SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C1SFXDelay], a
	jr PlaySFXC1
InitSFXC2:
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %00100010
	or d
	ld [MasterSFXPan], a
	;Enable SFX playback with flag
	ld a, [C2PlayFlag]
	and %11111110
	ld [C2PlayFlag], a
	;Enable SFX playback with flag
	ld a, c
	ld [C2SFXPos], a
	ld a, b
	ld [C2SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C2SFXDelay], a
	jr PlaySFXC1
InitSFXC3:
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %01000100
	or d
	ld [MasterSFXPan], a
	;Enable SFX playback with flag
	ld a, [C3PlayFlag]
	and %11111110
	ld [C3PlayFlag], a
	;Go to SFX position from RAM
	ld a, c
	ld [C3SFXPos], a
	ld a, b
	ld [C3SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C3SFXDelay], a
	jr PlaySFXC1
InitSFXC4:
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %10001000
	or d
	ld [MasterSFXPan], a
	;Enable SFX playback with flag
	ld a, [C4PlayFlag]
	and %11111110
	ld [C4PlayFlag], a
	;Go to SFX position from RAM
	ld a, c
	ld [C4SFXPos], a
	ld a, b
	ld [C4SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C4SFXDelay], a

;Play the current sound effect, starting with channel 1 if presentPlaySFXC1:
	ld hl, C1PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C1SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then go to next channel
	jr z, PlaySFXC2

	;Otherwise, then play SFX
	ld de, rNR11
	call CheckSFX
PlaySFXC2:
	ld hl, C2PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C2SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then go to next channel
	jr z, PlaySFXC3

	ld de, rNR21
	call CheckSFX
PlaySFXC3:
	ld hl, C3PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C3SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then go to next channel
	jr z, PlaySFXC4

	ld de, rNR31
	call CheckSFX
PlaySFXC4:
	ld hl, C4PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C4SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then return
	jr z, PlaySFXRet

	ld de, rNR41
	call CheckSFX

;Return from SFX routinePlaySFXRet:
	ret

CheckSFX:
	;Set the panning for SFX
	ld a, [MasterSFXPan]
	ldh [rNR51], a
	;Check if channel is ready
	inc hl
	dec [hl]
	;If so, then continue
	jr z, GetNextSFXCMD

	;Otherwise, return
	ret

GetNextSFXCMD:
	;Get the next SFX command
	ld a, [bc]
	;Is it a stop command (FF)?
	cp $FF
	jr z, SFXEventStop

	;Is it a jump command (FE)?
	cp $FE
	jr z, SFXEventJump

	;Otherwise...
	;Byte 1 = Delay
	ld [hl], a
	;Byte 2 = NRx1 (Channel length/duty)
	inc bc
	ld a, [bc]
	ld [de], a
	;Byte 3 = NRx2 (Volume/envelope)
	inc bc
	inc de
	ld a, [bc]
	ld [de], a
	;Byte 4 = NRx4 (Period high/control)
	inc bc
	inc de
	inc de
	ld a, [bc]
	ld [de], a
	;Byte 5 = NRx3 (Period low)
	inc bc
	dec de
	ld a, [bc]
	ld [de], a
	inc bc
SFXUpdatePtr:
;Update the pointer
	dec hl
	ld [hl], b
	dec hl
	ld [hl], c
	ret

SFXEventStop:
;Stop the macro
	;Reset the pointer
	ld a, 0
	dec hl
	ld [hl], a
	dec hl
	ld [hl], a
	;Get the current channel's play flag
	ld hl, CurSFX
	ld c, [hl]
	inc hl
	ld b, [hl]

	;Check if panning is zero
	ld a, [bc]
	and %00000010
	jp z, SFXRestorePan

	;Reset it to 3 (music)
	ld a, [bc]
	or %00000001
	ld [bc], a
SFXRestorePan:
	;Restore the original panning
	ld a, [MasterPan]
	ldh [rNR51], a
	ret

SFXEventJump:
	;Load the loop position from the following 2 bytes as the position
	inc bc
	ld a, [bc]
	ld e, a
	inc bc
	ld a, [bc]
	ld b, a
	ld c, e
	;Reset SFX channel play flag to 1
	ld a, 1
	ld [hl], a
	jr SFXUpdatePtr
Waveform:
	db $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $00, $00, $00, $00, $00, $00, $00, $00
SFXMacroTab:
	dw SFXMacro00
	dw SFXMacro01
	dw SFXMacro02
	dw SFXMacro03
	dw SFXMacro04
	
SFXTab:
.Empty
	db $00, $FF, $FF, $FF
.Collect
	db $01, $FF, $FF, $FF
.Ghost
	db $02, $FF, $FF, $FF
.Scream1
	db $03, $FF, $FF, $FF
.Scream2
	db $04, $FF, $FF, $FF

SFXMacro00:
	db 0
	db $FF
SFXMacro01:
	db 0 ; CH1(square1)
	db 2, $40, $80, $87, $83 ; C6 (m84)
	db 8, $40, $44, $87, $C1 ; C7 (m96)
	db $FF
SFXMacro02:
	db 0 ; CH1(square1)
	db 3, $80, $69, $86, $D6 ; A4 (m69)
	db 3, $80, $53, $86, $E7 ; A#4 (m70)
	db 3, $80, $49, $86, $D6 ; A4 (m69)
	db 3, $80, $53, $86, $E7 ; A#4 (m70)
	db 3, $80, $49, $86, $D6 ; A4 (m69)
	db 3, $80, $53, $86, $E7 ; A#4 (m70)
	db 3, $80, $69, $86, $F7 ; B4 (m71)
	db 3, $80, $43, $86, $E7 ; A#4 (m70)
	db 3, $80, $59, $86, $F7 ; B4 (m71)
	db 3, $80, $63, $86, $E7 ; A#4 (m70)
	db 3, $80, $49, $86, $D6 ; A4 (m69)
	db 3, $80, $53, $86, $E7 ; A#4 (m70)
	db 3, $80, $53, $86, $F7 ; B4 (m71)
	db $FF
SFXMacro03:
	db 0 ; CH1(square1)
	db 3, $00, $83, $87, $73 ; A#5 (m82)
	db 3, $00, $73, $87, $73 ; A#5 (m82)
	db 3, $00, $83, $87, $73 ; A#5 (m82)
	db 3, $00, $83, $87, $59 ; G5 (m79)
	db 3, $00, $73, $87, $59 ; G5 (m79)
	db 2, $00, $63, $87, $4F ; F#5 (m78)
	db 2, $00, $53, $87, $44 ; F5 (m77)
	db 1, $00, $43, $87, $39 ; E5 (m76)
	db $FF
SFXMacro04:
	db 0 ; CH1(square1)
	db 1, $80, $82, $86, $E7 ; A#4 (m70)
	db 1, $80, $72, $87, $06 ; C5 (m72)
	db 1, $80, $82, $87, $14 ; C#5 (m73)
	db 1, $80, $72, $87, $06 ; C5 (m72)
	db 1, $80, $82, $86, $E7 ; A#4 (m70)
	db $FF

Empty1A:
	db $67, %11111111
	db $69, 255
	db $24, $00
	db $66, 1
	db $61
Empty1B:
	db $24, $00
	db $61
Empty1C:
	db $24, $00
	db $61
Empty1D:
	db $24, $00
	db $61
	
ActionA:
	db $67, $FF
	db $69, $DC
	db $64, $00, -12, 2
	db $62
	dw ActionA	
ActionB:
	db $64, $01, -12, 2
	db $62
	dw ActionB
ActionC:
	db $64, $02, 0, 1
	db $64, $03, 0, 1
	db $64, $02, 0, 1
	db $64, $03, 0, 1
	db $62
	dw ActionC
ActionD:
	db $64, $05, 0, 4
	db $62
	dw ActionD
SongMacro00:
	db $34, $CA
	db $2F, $B4
	db $32, $B4
	db $24, $04
	db $34, $B3
	db $24, $01
	db $34, $B3
	db $24, $07
	db $60, $01
	db $34, $CA
	db $2F, $B4
	db $32, $B4
	db $24, $04
	db $34, $B3
	db $24, $01
	db $31, $B8
	db $65
SongMacro01:
	db $2F, $CA
	db $24, $0A
	db $2F, $CA
	db $2F, $C8
	db $2D, $C8
	db $2F, $CA
	db $24, $0A
	db $9C, $4B
	db $B4, $08
	db $65
SongMacro02:
	db $84, $26
	db $24, $04
	db $8B, $24
	db $24, $04
	db $8B, $24
	db $24, $04
	db $8E, $26
	db $8B, $24
	db $8E, $24
	db $24, $04
	db $65
SongMacro03:
	db $90, $26
	db $24, $06
	db $65
SongMacro04:
	db $92, $26
	db $90, $26
	db $65
SongMacro05:
	db $12, $34
	db $24, $04
	db $12, $34
	db $12, $34
	db $12, $34
	db $24, $04
	db $12, $34
	db $24, $04
	db $12, $34
	db $12, $34
	db $12, $34
	db $12, $34
	db $24, $04
	db $12, $34
	db $12, $34
	db $24, $04
	db $65
	
ShowA:
	db $67, $FF
	db $69, $FF
	db $64, $06, -12, 1
	db $62
	dw ShowA
ShowB:
	db $64, $07, -12, 2
	db $64, $08, -12, 1
	db $62
	dw ShowB
ShowC:
	db $64, $09, 0, 2
	db $64, $0A, 0, 1
	db $62
	dw ShowC
ShowD:
	db $64, $0B, 0, 2
	db $64, $0C, 0, 1
	db $64, $0B, 0, 1
	db $62
	dw ShowD
SongMacro06:
	db $31, $E9
	db $2F, $E4
	db $30, $E4
	db $31, $E9
	db $2F, $E4
	db $30, $E4
	db $31, $E6
	db $24, $06
	db $31, $E6
	db $24, $04
	db $31, $E6
	db $24, $07
	db $2F, $E6
	db $30, $E6
	db $65
SongMacro07:
	db $19, $D4
	db $19, $D4
	db $25, $D6
	db $25, $D4
	db $24, $07
	db $65
SongMacro08:
	db $1C, $D4
	db $1C, $D4
	db $28, $D6
	db $28, $D4
	db $24, $04
	db $28, $D4
	db $2A, $D4
	db $24, $04
	db $2A, $D4
	db $24, $04
	db $2A, $D4
	db $28, $D4
	db $28, $D4
	db $29, $D4
	db $24, $04
	db $65
SongMacro09:
	db $81, $24
	db $81, $24
	db $8D, $26
	db $8D, $24
	db $24, $04
	db $8D, $26
	db $65
SongMacro0A:
	db $84, $24
	db $84, $24
	db $90, $26
	db $90, $24
	db $24, $04
	db $90, $24
	db $24, $06
	db $90, $24
	db $8B, $26
	db $8B, $24
	db $24, $04
	db $8B, $26
	db $65
SongMacro0B:
	db $0C, $14
	db $12, $44
	db $12, $44
	db $24, $04
	db $0E, $24
	db $12, $44
	db $12, $44
	db $12, $44
	db $65
SongMacro0C:
	db $0C, $14
	db $12, $34
	db $12, $34
	db $24, $04
	db $0E, $24
	db $12, $44
	db $12, $44
	db $12, $44
	db $65

TitleA:
	db $67, $FF
	db $69, $B8
	db $64, $0D, -12, 3
	db $64, $0E, -12, 1
	db $62
	dw TitleA
TitleB:
	db $61
TitleC:
	db $61	
TitleD:
	db $64, $0F, 0, 4
	db $62
	dw TitleD
SongMacro0D:
	db $24, $96
	db $24, $04
	db $2B, $96
	db $2B, $94
	db $2A, $97
	db $2B, $96
	db $24, $04
	db $65
SongMacro0E:
	db $22, $96
	db $24, $04
	db $29, $96
	db $29, $94
	db $28, $97
	db $29, $96
	db $24, $04
	db $65
SongMacro0F:
	db $0C, $16
	db $12, $34
	db $12, $34
	db $24, $04
	db $12, $34
	db $12, $34
	db $24, $04
	db $12, $34
	db $12, $34
	db $24, $04
	db $12, $34
	db $65
	
FanfareA:
	db $67, $FF
	db $69, $FF
	db $64, $10, -12, 1
	db $61
FanfareB:
	db $61
FanfareC:
	db $61
FanfareD:
	db $61
SongMacro10:
	db $30, $C8
	db $2B, $C6
	db $24, $04
	db $2B, $C4
	db $30, $CE
	db $2B, $CE
	db $30, $CE
	db $37, $CA
	db $3C, $BA
	db $65
SongTab:
.Empty
	dw Empty1A, Empty1B, Empty1C, Empty1D, NoteLens1
.Action
	dw ActionA, ActionB, ActionC, ActionD, NoteLens1
.Show
	dw ShowA, ShowB, ShowC, ShowD, NoteLens1
.Title
	dw TitleA, TitleB, TitleC, TitleD, NoteLens1
.Fanfare
	dw FanfareA, FanfareB, FanfareC, FanfareD, NoteLens1
	NoteLens1:
	db 1, 2, 3, 4, 6, 9, 12, 18, 24, 36, 48, 72, 96, 4, 8, 16
	
NoteLens2:
	db 3, 4, 6, 9, 12, 18, 24, 36, 48, 72, 96, 144, 192, 8, 16, 32
	InsTab:
	dw InsRest
	dw InsBassDrum
	dw InsSnareDrum
	dw InsHiHatC
	dw InsHiHatP
	dw InsHiHatO
	dw InsBuzz
	dw InsTomTom
	dw InsClink
	dw InsBoing
	dw InsPlink
	dw InsBell1
	dw InsBell2
	dw InsPiano
	dw InsBell3
	dw InsBrass
	dw InsBassShort
	dw InsBassMed
	dw InsBassLong
	dw InsArp7
	dw InsArp12
	dw InsArp16
	dw InsDoNotUse16
	dw InsDoNotUse17
	dw InsDoNotUse18
	dw InsBassVShort
	dw InsPing
	dw InsDull
	dw InsSlideUp
	dw InsBlip
	dw InsBlipQuiet

InsRest:
	;Period ctrl
	db $80
	;Duty
	db $00
	;Initial vol/env
	db $02
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsBassDrum:
	;Period ctrl
	db $C0
	;Duty
	db $BD
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq00
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq00
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsSnareDrum:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq01
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq01
	;Pitch mod seq delay
	db 0
	;Pitch mod ptr
	dw 0
InsHiHatC:
	;Period ctrl
	db $C0
	;Duty
	db $BB
	;Initial vol/env
	db $41
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq02
	;Pitch mod seq delay
	db 0
	;Pitch mod ptr
	dw 0
InsHiHatP:
	;Period ctrl
	db $C0
	;Duty
	db $B2
	;Initial vol/env
	db $61
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq02
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsHiHatO:
	;Period ctrl
	db $80
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq02
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq03
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBuzz:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq03
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq04
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsTomTom:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq04
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq00
InsClink:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq05
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBoing:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq06
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq01
InsPlink:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $A1
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq06
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBell1:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $A5
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db $01
	;Vib seq ptr
	dw VibSeq06
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBell2:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq07
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq06
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsPiano:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $62
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq06
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBell3:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $66
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq06
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsBrass:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db $01
	;Env seq ptr
	dw EnvSeq08
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq07
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsBassShort:
	;Period ctrl
	db $C0
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq09
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBassMed:
	;Period ctrl
	db $C0
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0A
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBassLong:
	;Period ctrl
	db $80
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0B
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsArp7:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $64
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq02
InsArp12:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $64
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq03
InsArp16:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $64
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db $01
	;Pitch mod seq ptr
	dw ModSeq04
InsDoNotUse16:
InsDoNotUse17:
InsDoNotUse18:
InsBassVShort:
	;Period ctrl
	db $C0
	;Duty
	db $3C
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0C
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsPing:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0D
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq07
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq05
InsDull:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0E
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq08
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsSlideUp:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0F
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod seq delay
	db 1
	;Pitch mod seq ptr
	dw ModSeq06
InsBlip:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq10
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq09
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
InsBlipQuiet:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq11
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq09
	;Pitch mod seq delay
	db 0
	;Pitch mod seq ptr
	dw 0
	
EnvSeq00:
	db $F0, 1
	db $00, 1
	db $80, 1
	db $00, 1
	db $FF
EnvSeq01:
	db $60, 3
	db $20, 2
	db $10, 2
	db $00, 1
	db $FF
EnvSeq02:
	db $60, 1
	db $50, 1
	db $30, 3
	db $20, 4
	db $10, 4
	db $00, 1
	db $FF
EnvSeq03:
	db $A0, 1
	db $50, 1
	db $A0, 1
	db $50, 1
	db $A0, 1
	db $50, 1
	db $A0, 1
	db $50, 1
	db $00, 1
	db $FF
EnvSeq04:
	db $F0, 2
	db $80, 2
	db $60, 2
	db $30, 1
	db $20, 2
	db $10, 2
	db $00, 1
	db $FF
EnvSeq05:
	db $80, 1
	db $40, 1
	db $00, 2
	db $10, 1
	db $00, 1
	db $FF
EnvSeq06:
	db $A0, 1
	db $50, 1
	db $40, 1
	db $30, 1
	db $20, 1
	db $00, 1
	db $FF
EnvSeq07:
	db $A0, 1
	db $90, 1
	db $80, 2
	db $70, 4
	db $60, 8
	db $50, 16
	db $40, 20
	db $30, 30
	db $20, 40
	db $10, 40
	db $00, 1
	db $FF
EnvSeq08:
	db $60, 1
	db $50, 1
	db $40, 4
	db $30, 24
	db $20, 50
	db $10, 80
	db $00, 1
	db $FF
EnvSeq09:
	db $20, 4
	db $40, 6
	db $60, 8
	db $00, 1
	db $FF
EnvSeq0A:
	db $20, 3
	db $40, 5
	db $60, 50
	db $00, 1
	db $FF
EnvSeq0B:
	db $20, 5
	db $40, 200
	db $60, 160
	db $00, 1
	db $FF
EnvSeq0C:
	db $20, 1
	db $60, 1
	db $00, 1
	db $FF
EnvSeq0D:
	db $60, 2
	db $40, 1
	db $20, 200
	db $20, 200
	db $10, 200
	db $00, 1
	db $FF
EnvSeq0E:
	db $40, 1
	db $30, 2
	db $20, 2
	db $10, 2
	db $00, 1
	db $FF
EnvSeq0F:
	db $70, 200
	db $60, 200
	db $50, 200
	db $00, 1
	db $FF
EnvSeq10:
	db $90, 1
	db $40, 2
	db $20, 2
	db $00, 1
	db $FF
EnvSeq11:
	db $50, 1
	db $20, 1
	db $10, 1
	db $00, 1
	db $FF
	
VibSeq00:
	db $60, 200
	db $7E
VibSeq01:
	db 34, 1
	db 100, 2
	db 34, 2
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 16
	db $7E
VibSeq02:	
	db 18, 200
	db $7E
VibSeq03:
	db 34, 1
	db 16, 200
	db $7E
VibSeq04:
	db 2, 1
	db -2, 1
	db 2, 1
	db -2, 1
	db 2, 1
	db -2, 1
	db 2, 1
	db -2, 1
	db $7D
	dw VibSeq04
VibSeq05:
	db 0, 2
	db -1, 1
	db -2, 1
	db -3, 1
	db -4, 1
	db -5, 1
	db -6, 1
	db -7, 1
	db -8, 1
	db -9, 1
	db -10, 1
	db -11, 1
	db -12, 1
	db -13, 1
	db -14, 1
	db -15, 1
	db -16, 1
	db -17, 1
	db -20, 1
	db -25, 1
	db $7E
VibSeq06:
	db 2, 3
	db -2, 3
	db -2, 3
	db 2, 3
	db 2, 3
	db -2, 3
	db -2, 3
	db 2, 3
	db $7D
	dw VibSeq06
VibSeq07:
	db 0, 4
	db 2, 1
	db -2, 1
	db -2, 1
	db 2, 1
	db 2, 1
	db -2, 1
	db -2, 1
	db 2, 1
	db $7E
VibSeq08:
	db -3, 253
	db $7E
VibSeq09:
	db 34, 1
	db 34, 2
	db 55, 100
	db $7E
	
ModSeq00:
	db 1, -1
	db 1, -2
	db 1, -3
	db 1, -4
	db 1, -5
	db 1, -6
	db 1, -7
	db 1, -8
	db 1, -9
	db 1, -10
	db 1, -11
	db 1, -12
	db 1, -13
	db 200, -13
	db $FF
	dw ModSeq00
ModSeq01:
	db 2, 0
	db 1, 1
	db 1, 2
	db 1, 3
	db 200, 3
	db $FF
	dw ModSeq01
ModSeq02:
	db 1, 0
	db 1, 4
	db 1, 7
	db 1, 0
	db 1, 4
	db 1, 7
	db $FF
	dw ModSeq02
ModSeq03:
	db 1, 4
	db 1, 7
	db 1, 12
	db 1, 4
	db 1, 7
	db 1, 12
	db $FF
	dw ModSeq03
ModSeq04:
	db 1, 7
	db 1, 12
	db 1, 16
	db 1, 7
	db 1, 12
	db 1, 16
	db $FF
	dw ModSeq04
ModSeq05:
	db 1, 12
	db 200, 0
	db 200, 0
	db 200, 0
	db $FF
	dw ModSeq05
ModSeq06:
	db 1, 0
	db 1, 1
	db 1, 2
	db 1, 3
	db 1, 4
	db 1, 5
	db 1, 6
	db 1, 7
	db 1, 8
	db 1, 9
	db 1, 10
	db 1, 11
	db 1, 12
	db 1, 13
	db 1, 14
	db 1, 15
	db 1, 16
	db 1, 17
	db 1, 18
	db 1, 19
	db 1, 20
	db 1, 21
	db 1, 22
	db 1, 23
	db 1, 24
	db 1, 25
	db 1, 26
	db 1, 27
	db 1, 28
	db 1, 29
	db 1, 30
	db 1, 31
	db 1, 32
	db 1, 33
	db 1, 34
	db 1, 35
	db 1, 36
	db 1, 37
	db 1, 38
	db 1, 39
	db 1, 40
	db 1, 41
	db 1, 42
	db 1, 43
	db 1, 44
	db 1, 45
	db 1, 46
	db 1, 47
	db 1, 48
	db $FF
	dw ModSeq06
SongMacroTab:
	dw SongMacro00
	dw SongMacro01
	dw SongMacro02
	dw SongMacro03
	dw SongMacro04
	dw SongMacro05
	dw SongMacro06
	dw SongMacro07
	dw SongMacro08
	dw SongMacro09
	dw SongMacro0A
	dw SongMacro0B
	dw SongMacro0C
	dw SongMacro0D
	dw SongMacro0E
	dw SongMacro0F
	dw SongMacro10


SECTION "Audio RAM", WRAMX[AudioRAM]

C1PlayFlag: ds 1
C1Len: ds 1
C1Pos: ds 2
C1Freq: ds 2
Unk06: ds 1
C1Duty: ds 1
C1Env: ds 1
Unk09: ds 1
C1EnvSeqDelay: ds 1
C1EnvSeq: ds 2
C1VibSeqDelay: ds 1
C1VibSeq: ds 2
C1ModSeqDelay: ds 1
C1ModSeq: ds 2
C1MacroTimesLeft: ds 1
C1MacroTrans: ds 1
C1InMacro: ds 1
C1MacroRet: ds 2
C2PlayFlag: ds 1
C2Len: ds 1
C2Pos: ds 2
C2Freq: ds 2
Unk1E: ds 1
C2Duty: ds 1
C2Env: ds 1
Unk21: ds 1
C2EnvSeqDelay: ds 1
C2EnvSeq: ds 2
C2VibSeqDelay: ds 1
C2VibSeq: ds 2
C2ModSeqDelay: ds 1
C2ModSeq: ds 2
C2MacroTimesLeft: ds 1
C2MacroTrans: ds 1
C2InMacro: ds 1
C2MacroRet: ds 2
C3PlayFlag: ds 1
C3Len: ds 1
C3Pos: ds 2
C3Freq: ds 2
Unk36: ds 1
C3Duty: ds 1
C3Env: ds 1
Unk39: ds 1
C3EnvSeqDelay: ds 1
C3EnvSeq: ds 2
C3VibSeqDelay: ds 1
C3VibSeq: ds 2
C3ModSeqDelay: ds 1
C3ModSeq: ds 2
C3MacroTimesLeft: ds 1
C3MacroTrans: ds 1
C3InMacro: ds 1
C3MacroRet: ds 2
C4PlayFlag: ds 1
C4Len: ds 1
C4Pos: ds 2
C4Freq: ds 2
Unk4E: ds 1
C4Duty: ds 1
C4Env: ds 1
Unk51: ds 1
C4EnvSeqDelay: ds 1
C4EnvSeq: ds 2
C4VibSeqDelay: ds 1
C4VibSeq: ds 2
C4ModSeqDelay: ds 1
C4ModSeq: ds 2
C4MacroTimesLeft: ds 1
C4MacroTrans: ds 1
C4InMacro: ds 1
C4MacroRet: ds 2
NoteLens: ds 2
CurRestartPos: ds 2
CurNoise: ds 1
CurTrans: ds 1
CurCmd: ds 1
LoopFlag: ds 1
C1SFXPos: ds 2
C1SFXDelay: ds 1
C2SFXPos: ds 2
C2SFXDelay: ds 1
C3SFXPos: ds 2
C3SFXDelay: ds 1
C4SFXPos: ds 2
C4SFXDelay: ds 1
CurSFX: ds 2
PlayFlag: ds 1
BeatCounter: ds 1
Tempo: ds 1
MasterPan: ds 1
MasterSFXPan: ds 1
CurChan: ds 1
CurNoteC1: ds 1
CurNoteC2: ds 1
CurNoteC3: ds 1
CurNoteC4: ds 1