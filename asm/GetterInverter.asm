getBit:
	while
		tst r1
	stays nz
		shr r0
		dec r1
	wend
	ldi r1, 1
	and r1, r0
rts

invertBit:
	ldi r2, 1
	while
		tst r1
	stays nz
		shl r2
		dec r1
	wend
	xor r2, r0
rts
		