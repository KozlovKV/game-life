# Internal data addresses
asect 0x00
gameMode:

asect 0x01
birthConditions:

asect 0x02
deathConditions:

asect 0x10
envFirstByte:

asect 0x18
envLastByte:

asect 0x20
envFirstByteFieldAddr:

asect 0x28
envLastByteFieldAddr:

asect 0x70
firstFieldByte:

asect 0xef
lastFieldByte:


# Asects for I/O registers
asect 0xf0
IOGameMode:

asect 0xf1
IOBirthConditions:

asect 0xf2
IODeathConditions:

asect 0xf3
IOY:

asect 0xf4
IOX:

asect 0xf5
IORowController:

asect 32
rowsCount:

asect 0xf6
IORowFirstByte:

asect 0xf9
IORowLastByte:

#===============================
  ### Place for subroutines ###
#===============================

macro fieldInc/2
	ldi $2, 0x90  # Negatated 0x70
	add $2, $1
	inc $1
	shl $1
	shra $1
	neg $2
	add $2, $1
mend

#===============================

asect 0x00
start: 
	# Move SP before I/O and field addresses
	addsp 0x70

	ldi r1, IOGameMode
	do
		ld r1, r0
		tst r0
	until nz

main:

	
	
	# Save addresses of firstEnv
	ldi r0, envFirstByteFieldAddr
	ldi r1, 0xef
	st r0, r1
	inc r0
	ldi r1, 0xec
	st r0, r1
	inc r0
	inc r1
	st r0, r1
	inc r0
	ldi r1, 0x73
	st r0, r1
	inc r0
	ldi r1, 0x70
	st r0, r1
	inc r0
	inc r1
	st r0, r1
	inc r0
	ldi r1, 0x83
	st r0, r1
	inc r0
	ldi r1, 0x80
	st r0, r1
	inc r0
	inc r1
	st r0, r1
	inc r0
	
	ldi r1, 0
	do
		ldi r0, envFirstByteFieldAddr
		do 
			ld r0, r2
			fieldInc r2, r3
			st r0, r2
			inc r0
			ldi r3, envLastByteFieldAddr
			cmp r0, r3
		until gt
		inc r1
		tst r1
	until z
br main

halt
end
