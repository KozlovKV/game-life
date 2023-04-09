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
	
	# This part can be excluded because we can read conditions directly from I/O regs.
	ldi r1, IOBirthConditions
	ld r1, r0
	ldi r1, birthConditions
	st r1, r0
	ldi r1, IODeathConditions
	ld r1, r0
	ldi r1, deathConditions
	st r1, r0
	# end of easy excluded part

main:

	# Load field from videobuffer
	ldi r0, firstFieldByte
	ldi r3, 0 # Y position (row)
	do
		# Tell logisim with which row we will interact
		ldi r1, IOY
		st r1, r3
		
		# Send read signal for row registers
		ldi r1, IORowController
		ld r1, r1  # second arg. is a blank
		
		# Read data from row regs and save to field
		ldi r1, IORowFirstByte
		do
			ld r1, r2
			st r0, r2
			inc r0
			inc r1
			ldi r2, IORowLastByte
			cmp r1, r2
		until gt
		inc r3
		ldi r1, lastFieldByte
		cmp r0, r1
	until hi
	
	# Placeholder for env cycle
br main

halt
end