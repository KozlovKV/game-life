asect 0
jmp start

# Internal data addresses
asect 0x6a
gameMode:

asect 0x6b
birthConditions:

asect 0x6c
deathConditions:

asect 0x5a
topLeftY:

asect 0x5b
topLeftX:

asect 0x5c
isNotNullEnv:

asect 0x4a
newByteAddr:

asect 0x40
envTopRowBegin:
asect 0x49
envTopRowEnd:

asect 0x50
envMidRowBegin:
asect 0x51
envCentreByteBegin:
asect 0x59
envMidRowEnd:

asect 0x60
envBottomRowBegin:
asect 0x69
envBottomRowEnd:

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

asect 0xfa
IOBit:

asect 0xfb
IOEnvSum:

asect 0xff
IOCPUStatus:

# CPU statuses
asect 0x40
WAIT:
asect 0x41
READ_FIELD:
asect 0x42
PROCESS_FIELD:

#==============================#
#      Place for macroses      #
#==============================#
macro getRowBeginAddr/2
# Gets row index and returns addr of begin of its row
# 1st reg - result
# 2nd reg - helping
	ldi $2, 0x70
	shla $1
	shla $1
	add $2, $1
mend

macro fieldInc/2
# Cycle increment in range [0x70, 0xef]
	ldi $2, 0x90  # Negatated 0x70
	add $2, $1
	inc $1
	shl $1
	shra $1
	neg $2
	add $2, $1
mend

macro cycledInc/2
	inc $1
	ldi $2, 0b00000111
	and $2, $1
mend

macro cycledDec/2
	dec $1
	ldi $2, 0b00000111
	and $2, $1
mend

macro changeCPUStatus/3
# change debugging CPU process status
# args 1, 2 - free regs
# arg 3 - new status
	ldi $1, IOCPUStatus
	ldi $2, $3
	st $1, $2
mend
#===============================

asect 0x100
#==============================#
#     Place for subroutines    #
#==============================#
getBit:
	while
		dec r1
	stays pl
		shr r0
		if
		is z
			break
		fi
	wend
	ldi r1, 1
	and r1, r0
rts

invertBit:
	ldi r2, 1
	while
		dec r1
	stays pl
		shla r2
	wend
	xor r2, r0
rts
		
processBit:
	# r0 - bit
	# r1 - sum
	# returns to r0 new bit state
	push r0
	if
		tst r0
	is z
		if
			tst r1
		is z
			# For zero sum we cell cannot birth
			ldi r0, 0
			br inverting
		fi
		ldi r0, birthConditions
	else
		if
			tst r1
		is z
			# For zero sum we kill alive cell
			ldi r0, 1
			br inverting
		fi
		ldi r0, deathConditions
	fi
	ld r0, r0
	dec r1
	jsr getBit
	inverting:
	if
		tst r0
	is nz
		pop r0
		inc r0
		ldi r1, 1
		and r1, r0
	else 
		pop r0
	fi
rts

#===============================

start:
	# Move SP before I/O and field addresses
	setsp 0x40

	changeCPUStatus r0, r1, WAIT

	# Waiting for IOGameMode I/O reg. != 0
	ldi r1, IOGameMode
	do 
		ld r1, r0
		tst r0
	until nz

	ldi r1, gameMode
	st r1, r0

	# Read birth and death conditions from I/O regs.
	ldi r1, IOBirthConditions
	ld r1, r0
	ldi r1, birthConditions
	st r1, r0
	ldi r1, IODeathConditions
	ld r1, r0
	ldi r1, deathConditions
	st r1, r0

main:
	
	changeCPUStatus r0, r1, PROCESS_FIELD
	
	# Count new bytes states
	ldi r3, 31 # row iterator
	ldi r2, lastFieldByte
	do
		push r3 # Save row iterator
		ldi r1, topLeftY
		st r1, r3

		ldi r1, 31 # Bit index
		ldi r3, 4 # byte in row iterator
		do 
			push r3 # Save byte in row iterator
			push r2 # Save byte addr.

			ldi r2, 0 # Set initial value for byte

			ldi r3, 8
			do
				push r3
				push r1

				ldi r3, topLeftY
				ld r3, r3 

				# Send to logisim coords of current cell
				ldi r0, IOY
				st r0, r3
				ldi r0, IOX
				st r0, r1

				# Read data for this cell
				ldi r0, IOBit
				ld r0, r0
				ldi r1, IOEnvSum
				ld r1, r1

				# Check birth or death conditions and save bit depends on conditions
				jsr processBit
				shla r2
				add r0, r2

				# Decrement X (bit index)
				pop r1
				dec r1

				pop r3
				dec r3
			until z

			move r2, r0
			pop r2
			# Save byte of new field and decrement addr.
			st r2, r0
			dec r2
			
			pop r3
			dec r3
		until z

		pop r3 # Get row iterator
		dec r3
	until mi

	changeCPUStatus r0, r1, READ_FIELD
	# Save field to videobuffer
	ldi r0, lastFieldByte
	ldi r3, 0x1f # row Y index (will goes from last to first)
	do
		# Tell logisim with which row we will interact
		ldi r1, IOY
		st r1, r3
		# Save data to row regs and from field
		ldi r1, IORowLastByte # Begin from last byte
		do
			ld r0, r2
			st r1, r2
			dec r0
			dec r1
			ldi r2, IORowFirstByte
			cmp r1, r2
		until lt
		# Send write signal for row registers
		ldi r1, IORowController
		st r1, r1  # second arg. is a blank

		# Decrement row iterator
		dec r3
	until lt
# Go to infinite cycle
jmp main

halt
end
