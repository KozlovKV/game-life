asect 0xf0
gameMode:

asect 0xf1
birthConditions:

asect 0xf2
survivalConditions:

asect 0xf3
IOY:

asect 0xf4
IOX:

asect 0xf5
rowController:

asect 0xf6
fristByte:

asect 0xf9
lastByte:

#===============================
  ### Place for subroutines ###
#===============================


#===============================

asect 0x00
start:
	addsp -16  # Move SP before I/O addresses

	# ====
	# Test code for row I/O system
	ldi r0, rowController
	ld r0, r1
	ldi r0, fristByte
	ldi r1, 0
	ldi r2, lastByte
	while
		cmp r0, r2
	stays le
		ld r0, r3
		st r1, r3
		inc r1
		inc r0		
	wend
	# ====

	halt
end

