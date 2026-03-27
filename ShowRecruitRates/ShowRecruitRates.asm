; For use with the US version of Explorers of Sky

; Patched files:
; overlay_0031.bin
; overlay_0036.bin

.nds

; ----------------------------
; patch overlay 31
; base = 0x2382820
; hook site = 0x2388DD0
; offset = 0x2388DD0 - 0x2382820 = 0x65B0
; ----------------------------
.open "overlay_0031.bin", 0x2382820

.org 0x2388DD0
    b Hook_RowAppendRate

.close

; ----------------------------
; patch overlay 36
; base = 0x23A7080
; hook site = 0x23A7080 + 0x32B00 = 0x23D9B80
; offset = 0x23D9B80 - 0x23A7080 = 0x32B00
; ----------------------------
.open "overlay_0036.bin", 0x23A7080

.org 0x23D9B80
Hook_RowAppendRate:
    stmdb sp!, {r0-r3,r5-r8,lr}

    ; current row's monster id
    ldr   r0, [r4, #0]
    add   r0, r0, r7, lsl #1
    ldrsh r0, [r0, #4]

    ; choose table based on "played old game" answer
    mov   r8, r0              ; r8 = monster id
    bl    0x204CA70           ; returns 0 = no, nonzero = yes
    cmp   r0, #0
    mov   r0, r8              ; restore monster id as arg
    beq   UseRate1
    bl    0x2052A44           ; GetRecruitRate2
    b     RateChosen

UseRate1:
    bl    0x2052A60           ; GetRecruitRate1

RateChosen:
    mov   r5, r0              ; signed rate in tenths

    ; if positive and already on team, halve it
    cmp   r5, #0
    ble   ApplyLeaderBonuses

    mov   r0, r8              ; monster id
    mov   r1, #1              ; recruit_strategy = 1
    bl    0x2055148           ; IsMonsterOnTeam
    cmp   r0, #0
    beq   ApplyLeaderBonuses

    mov   r5, r5, lsr #1

ApplyLeaderBonuses:
    ; leader level bonus
    bl    0x22E9618           ; GetLeaderMonster
    cmp   r0, #0
    beq   CheckHeldItems

    ldrb  r0, [r0, #0x0A]     ; leader level

    cmp   r0, #30
    blt   CheckHeldItems      ; 1-29: +0.0

    cmp   r0, #40
    blt   AddLevel50          ; 30-39: +5.0

    cmp   r0, #50
    blt   AddLevel75          ; 40-49: +7.5

    cmp   r0, #99
    blt   AddLevel125         ; 50-98: +12.5

    add   r5, r5, #245        ; 99-100: +24.5
    b     CheckHeldItems

AddLevel50:
    add   r5, r5, #50
    b     CheckHeldItems

AddLevel75:
    add   r5, r5, #75
    b     CheckHeldItems

AddLevel125:
    add   r5, r5, #125

CheckHeldItems:
    ; get current leader entity pointer for held-item checks
    bl    0x22E9580           ; GetLeader
    cmp   r0, #0
    beq   CheckFastFriend
    mov   r6, r0              ; r6 = leader entity pointer

    ; Friend Bow (item 53) = +5.0 = +50
    mov   r0, r6
    mov   r1, #53
    bl    0x23467E4           ; HasHeldItem(leader, Friend Bow)
    cmp   r0, #0
    beq   CheckAmberTear
    add   r5, r5, #50

CheckAmberTear:
    ; Amber Tear (item 58) = +15.0 = +150
    mov   r0, r6
    mov   r1, #58
    bl    0x23467E4           ; HasHeldItem(leader, Amber Tear)
    cmp   r0, #0
    beq   CheckGoldenMask
    add   r5, r5, #150

CheckGoldenMask:
    ; Golden Mask (item 57) = +20.1 = +201
    mov   r0, r6
    mov   r1, #57
    bl    0x23467E4           ; HasHeldItem(leader, Golden Mask)
    cmp   r0, #0
    beq   CheckIcyFlute
    add   r5, r5, #201

CheckIcyFlute:
    ; Icy Flute (item 59) => +20.0 for ICE (type 6)
    mov   r0, r6
    mov   r1, #59
    bl    0x23467E4
    cmp   r0, #0
    beq   CheckFieryDrum

    mov   r0, r8
    mov   r1, #0
    bl    0x2052A04           ; GetType(monster_id, primary)
    cmp   r0, #6
    beq   AddTreasureBonus
    mov   r0, r8
    mov   r1, #1
    bl    0x2052A04           ; GetType(monster_id, secondary)
    cmp   r0, #6
    beq   AddTreasureBonus

CheckFieryDrum:
    ; Fiery Drum (item 60) => +20.0 for FIRE (type 2)
    mov   r0, r6
    mov   r1, #60
    bl    0x23467E4
    cmp   r0, #0
    beq   CheckTerraCymbal

    mov   r0, r8
    mov   r1, #0
    bl    0x2052A04
    cmp   r0, #2
    beq   AddTreasureBonus
    mov   r0, r8
    mov   r1, #1
    bl    0x2052A04
    cmp   r0, #2
    beq   AddTreasureBonus

CheckTerraCymbal:
    ; Terra Cymbal (item 61) => +20.0 for GROUND (type 9)
    mov   r0, r6
    mov   r1, #61
    bl    0x23467E4
    cmp   r0, #0
    beq   CheckAquaMonica

    mov   r0, r8
    mov   r1, #0
    bl    0x2052A04
    cmp   r0, #9
    beq   AddTreasureBonus
    mov   r0, r8
    mov   r1, #1
    bl    0x2052A04
    cmp   r0, #9
    beq   AddTreasureBonus

CheckAquaMonica:
    ; Aqua-Monica (item 62) => +20.0 for WATER (type 3)
    mov   r0, r6
    mov   r1, #62
    bl    0x23467E4
    cmp   r0, #0
    beq   CheckRockHorn

    mov   r0, r8
    mov   r1, #0
    bl    0x2052A04
    cmp   r0, #3
    beq   AddTreasureBonus
    mov   r0, r8
    mov   r1, #1
    bl    0x2052A04
    cmp   r0, #3
    beq   AddTreasureBonus

CheckRockHorn:
    ; Rock Horn (item 63) => +20.0 for ROCK (type 13)
    mov   r0, r6
    mov   r1, #63
    bl    0x23467E4
    cmp   r0, #0
    beq   CheckGrassCornet

    mov   r0, r8
    mov   r1, #0
    bl    0x2052A04
    cmp   r0, #13
    beq   AddTreasureBonus
    mov   r0, r8
    mov   r1, #1
    bl    0x2052A04
    cmp   r0, #13
    beq   AddTreasureBonus

CheckGrassCornet:
    ; Grass Cornet (item 64) => +20.0 for GRASS (type 4)
    mov   r0, r6
    mov   r1, #64
    bl    0x23467E4
    cmp   r0, #0
    beq   CheckSkyMelodica

    mov   r0, r8
    mov   r1, #0
    bl    0x2052A04
    cmp   r0, #4
    beq   AddTreasureBonus
    mov   r0, r8
    mov   r1, #1
    bl    0x2052A04
    cmp   r0, #4
    beq   AddTreasureBonus

CheckSkyMelodica:
    ; Sky Melodica (item 65) => +20.0 for FLYING (type 10)
    mov   r0, r6
    mov   r1, #65
    bl    0x23467E4
    cmp   r0, #0
    beq   CheckFastFriend

    mov   r0, r8
    mov   r1, #0
    bl    0x2052A04
    cmp   r0, #10
    beq   AddTreasureBonus
    mov   r0, r8
    mov   r1, #1
    bl    0x2052A04
    cmp   r0, #10
    beq   AddTreasureBonus
    b     CheckFastFriend

AddTreasureBonus:
    add   r5, r5, #200        ; +20.0
    b     CheckFastFriend

CheckFastFriend:
    ; Fast Friend IQ skill (id 0x1E) = +5.0 = +50
    mov   r0, #0x1E
    bl    0x22FB080           ; TeamLeaderIqSkillIsEnabled
    cmp   r0, #0
    beq   RateReady
    add   r5, r5, #50

RateReady:
    ; find end of built row string in R11
    mov   r0, r11

FindEnd:
    ldrb  r1, [r0]
    cmp   r1, #0
    beq   FoundEnd
    add   r0, r0, #1
    b     FindEnd

FoundEnd:
    ; back up to the '[' in "[CR]"
    sub   r0, r0, #4

    ; leading space
    mov   r1, #' '
    strb  r1, [r0], #1

    ; sign
    cmp   r5, #0
    bge   RateAbsReady
    mov   r1, #'-'
    strb  r1, [r0], #1
    rsb   r5, r5, #0          ; r5 = abs(r5)

RateAbsReady:
    ; split tenths: whole = r5 / 10, frac = r5 % 10
    mov   r6, #0              ; whole part

Div10Loop:
    cmp   r5, #10
    blt   Div10Done
    sub   r5, r5, #10
    add   r6, r6, #1
    b     Div10Loop

Div10Done:
    ; r6 = whole
    ; r5 = frac (0..9)

    ; print whole part
    cmp   r6, #0
    bne   WholeNonZero
    mov   r1, #'0'
    strb  r1, [r0], #1
    b     WriteDotMaybe

WholeNonZero:
    ; support up to 3 digits for whole part
    mov   r7, #0              ; hundreds

HundredsLoop:
    cmp   r6, #100
    blt   HundredsDone
    sub   r6, r6, #100
    add   r7, r7, #1
    b     HundredsLoop

HundredsDone:
    mov   r8, #0              ; tens

TensLoop:
    cmp   r6, #10
    blt   TensDone
    sub   r6, r6, #10
    add   r8, r8, #1
    b     TensLoop

TensDone:
    ; r7 = hundreds, r8 = tens, r6 = ones

    cmp   r7, #0
    beq   MaybeTens
    add   r1, r7, #'0'
    strb  r1, [r0], #1
    add   r1, r8, #'0'
    strb  r1, [r0], #1
    add   r1, r6, #'0'
    strb  r1, [r0], #1
    b     WriteDotMaybe

MaybeTens:
    cmp   r8, #0
    beq   OnesOnly
    add   r1, r8, #'0'
    strb  r1, [r0], #1
    add   r1, r6, #'0'
    strb  r1, [r0], #1
    b     WriteDotMaybe

OnesOnly:
    add   r1, r6, #'0'
    strb  r1, [r0], #1

WriteDotMaybe:
    ; omit trailing .0
    cmp   r5, #0
    beq   WriteCR

    mov   r1, #'.'
    strb  r1, [r0], #1

    add   r1, r5, #'0'
    strb  r1, [r0], #1

WriteCR:
    mov   r1, #'['
    strb  r1, [r0], #1
    mov   r1, #'C'
    strb  r1, [r0], #1
    mov   r1, #'R'
    strb  r1, [r0], #1
    mov   r1, #']'
    strb  r1, [r0], #1
    mov   r1, #0
    strb  r1, [r0]

    ldmia sp!, {r0-r3,r5-r8,lr}

    ; original overwritten instruction
    mov   r0, r6
    b     0x2388DD4

.close
