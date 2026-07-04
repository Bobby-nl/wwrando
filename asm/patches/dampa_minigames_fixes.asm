; This patch changes both of Dampa's Pig minigames so they can only be completed once,
; allowing them to be safely randomized without duplicating certain progression items.
; It also removes unnecessary restrictions from Minigame 1.
;
; Fixes a bug where, in either of Dampa's Pig minigames, the player can lock themselves
; out of completing the game by taking damage at the same moment a pig is "seen" by Dampa.
; In that situation, the pig is marked as counted, but Dampa's dialogue (and several
; related flags required for progression) are not updated correctly.

.open "files/rels/d_a_npc_people.rel"

; Bypasses the intro dialogue to allow immediate access to both minigames, skips setting of flag 2440 so it can be repurposed later
.org 0x7128
  b 0x7144

; MG1: Block replay if flag 0x2A04 is set instead of checking flag 2680; also removes the day lock.
.org 0x71C8
  li r4, 0x2A04

; MG1: Replace the "come back tomorrow" dialogue to intro dialogue
; to avoid confusing players into thinking it can be replayed.
.org 0x71D8
  addi r0, r30, 0x1B64

; MG1: Bypass the 80 Rupee limit to start the minigame.
.org 0x71F4
  b 0x7204

; MG2: Repurposed flag 2440 to trigger upon completing MG2 instead of the intro dialogue.
.org 0x70FC
  b 0x7134

; MG2: Block replay if flag 2440 is set (inverted behavior).
.org 0x8AB0
  bne 0x8AD8

; If Dampa already has a pending pig-count dialogue (mEtcFlag & 0x80),
; do not allow any additional pigs to be counted.
; Instead, reorder Dampa's speak event so the pending dialogue can be
; displayed, then return immediately.
; Once the dialogue is shown, the game clears mEtcFlag bit 0x80 and
; pig-counting can resume normally.

.org 0x9544 ; in daNpcPeople_c::checkPig
  b dampa_check_for_pending_pigs
.org @NextFreeSpace
.global dampa_check_for_pending_pigs
dampa_check_for_pending_pigs:
  ; Pointer to Dampa's actor is in r30
  lwz r11, 0x758(r30) ; Load mEtcFlag
  andi. r11, r11, 0x80 ; mEtcFlag & 0x80
  bne try_reorder_speak_event ; A pig is currently waiting for text to be shown
  lbz r0, 0x789(r30) ; Replace the line we overwrote to jump here
  b 0x9548 ; Continue to see if this pig meets the requirements to be counted
try_reorder_speak_event:
  mr r3, r30
  bl fopAcM_orderSpeakEvent__FP10fopAc_ac_c
  b 0x96a0 ; Return without counting any new pigs
.close