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
	move r2, r1
	dec r1
	jsr getBit
	move r0, r2
	pop r1
	pop r0
	ldi r1, 1
	if
		cmp r1, r2
	is eq
		jsr invertBit
	fi
rts