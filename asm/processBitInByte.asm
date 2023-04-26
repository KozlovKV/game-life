processBitInByte:
	push r0
	push r1
	jsr getBit
	if
		tst r0
	is eq
		ldi r0, birthConditions
	else
		ldi r0, deathConditions
	fi
	ld r0, r0
	move r2, r1
	dec r1
	jsr getBit
	move r0, r2
	pop r1
	pop r0
	if
		tst r2
	is nz
		jsr invertBit
	fi
rts