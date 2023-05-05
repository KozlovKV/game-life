# Internal data addresses
asect 0x50
gameMode:

asect 0x60
birthConditionsRowStart:

asect 0x68
deathConditionsRowStart:

asect 0x51
currentY:

asect 0x52
currentX:

asect 0x53
isNotNullEnv:

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

asect 0xf6
IORowFirstByte:

asect 0xf9
IORowLastByte:

asect 0xfa
IOBit:

asect 0xfb
IOEnvSum:

asect 0xfc
IONullRowsEnv:

asect 0xfd
IONullByteEnv:

asect 0xfe
CPUIndex:

asect 0xff
IOCPUStatus:

# CPU statuses
asect 0x40
WAIT:
asect 0x41
READ_FIELD:
asect 0x42
PROCESS_FIELD:

# Interanal constants
asect 30
firstRowIndex:

asect 0b11111110 # -2
rowDelta:

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

asect 0
br start

#==============================#
#     Place for subroutines    #
#==============================#
reduceByte:
	ldi r2, 0b00001000
	ldi r1, 0b00000000
	add r2, r0
	while
		tst r2
	stays nz
		dec r0
		ld r0, r3
		shla r1
		add r3, r1
		dec r2
	wend
	move r1, r0
rts

spreadByte:
	ldi r3, 0b00001000
	while
		tst r3
	stays nz
		ldi r2, 0b00000001
		and r0, r2
		st r1, r2
		inc r1
		shra r0
		dec r3
	wend
rts		


processBit:
	# r0 - sum
	# r1 - bit
	# returns to r1 new bit state
	# Choose conditions row addr.
	if
		tst r1
	is z
		ldi r2, birthConditionsRowStart
	else
		ldi r2, deathConditionsRowStart
	fi
	# Check bit in spreaded space
	dec r0
	add r0, r2
	ld r2, r2
	# If there is 1 than we switch bit
	if
		tst r2
	is nz
		inc r1
		ldi r0, 1
		and r0, r1
	fi
rts

#===============================

start:
	# Move SP before I/O and field addresses
	setsp 0x50

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
	ldi r1, birthConditionsRowStart
	jsr spreadByte
	ldi r1, IODeathConditions
	ld r1, r0
	ldi r1, deathConditionsRowStart
	jsr spreadByte

main:
	
	changeCPUStatus r0, r1, PROCESS_FIELD
	
	# Count new bytes states
	ldi r3, firstRowIndex # row iterator
	ldi r2, lastFieldByte
	do
		push r3 # Save row iterator
		ldi r0, IOY
		st r0, r3

		# If all rows in env. are null => skip this row
		ldi r3, IONullRowsEnv
		ld r3, r3
		tst r3
		bnz rowSkip

		ldi r1, 31 # Bit index
		ldi r3, 4 # byte in row iterator
		do 
			push r3 # Save byte in row iterator
			push r2 # Save byte addr.

			ldi r2, 0 # Set initial value for byte

			# byte env. (from x-7 to x) is null => byte will be 0
			ldi r0, IOX
			st r0, r1
			ldi r0, IONullByteEnv
			ld r0, r0
			tst r0
			bnz skipByte

			ldi r3, 8
			do
				push r1

				# Send to logisim coords of current cell
				
				ldi r0, IOX
				st r0, r1

				# Read data for this cell
				ldi r0, IOEnvSum
				ld r0, r0

				# Check birth or death conditions and save bit depends on conditions
				if
					tst r0
				is nz
					ldi r1, IOBit
					ld r1, r1
					push r2
					jsr processBit
					pop r2
					shla r2
					add r1, r2
				else 
					shla r2
				fi

				# Decrement X (bit index)
				pop r1
				dec r1

				dec r3
			until z
			br byteProcessed
			skipByte:
				ldi r0, -8
				add r0, r1
			byteProcessed:
			move r2, r0
			pop r2
			# Save byte of new field and decrement addr.
			st r2, r0
			dec r2
			
			pop r3
			dec r3
		until z
		br rowProcessed
		rowSkip:
			dec r2
			dec r2
			dec r2
			dec r2
		rowProcessed:

		pop r3 # Get row iterator
		ldi r0, rowDelta
		add r0, r3
	until mi

	halt

	changeCPUStatus r0, r1, READ_FIELD
	# Save field to videobuffer
	ldi r0, lastFieldByte
	ldi r3, firstRowIndex # row Y index (will goes from last to first)
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
		ldi r1, rowDelta
		add r1, r3
	until mi
# Go to infinite cycle
br main

halt
end
