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

asect 32
rowsCount:

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
	ldi r0, 0
	ldi r1, rowsCount
	while
		cmp r0, r1
	stays lt
		ldi r2, IOY
		st r2, r0
		push r0
		push r1
		
		ldi r2, fristByte
		ldi r3, lastByte
		while
			cmp r2, r3
		stays le
			st r2, r0
			inc r2			
			inc r0		
		wend
		ldi r2, rowController
		st r2, r3
		
		pop r1
		pop r0
		inc r0
	wend
	
	ldi r0, 4
	ldi r2, IOY
	st r2, r0
	ldi r2, rowController
	ld r2, r3	
	# ====

	halt
end

