macro cycledInc/2:
	inc $1
	ldi $2, 0b00000111
	and $2, $1
mend

macro cycledDec/2:
	dec $1
	ldi $2, 0b00000111
	and $2, $1
mend