reduceByte:
	ldi r2, 0b00001000
	ldi r1, 0b00000000
	add r2, r0
	while
		tst r2
	is nz
		dec r0
		ld r0, r3
		add r3, r1
		shla r1
		dec r2
	wend	
rts
		