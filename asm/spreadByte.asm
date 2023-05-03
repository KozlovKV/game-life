spreadByte:
	ldi r3, 0b00001000
	while
		tst r3
	is nz
		ldi r2, 0b00000001
		and r0, r2
		st r1, r2
		inc r1
		shra r0
		dec r3
	wend
rts		
		
		
		