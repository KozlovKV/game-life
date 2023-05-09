# Internal data addresses
asect 0x50
gameMode:

asect 0x60
birthConditionsRowStart:

asect 0x68
deathConditionsRowStart:

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
IOBit:

asect 0xf6
IOEnvSum:

asect 0xf7
IONullRowsEnv:

asect 0xf8
IONullByteEnv:

asect 0xf9
IOInvertBitSignal:

asect 0xfa
IOUpdateGeneration:

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
	# Send save signal to PSEUDO reg. IOInvertBitSignal if bit should be inverted (we count that IOX and IOY regs. contain correct coords.)
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
		ldi r0, IOInvertBitSignal
		st r0, r0
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
	
	ldi r0, IOUpdateGeneration
	st r0, r0

	changeCPUStatus r0, r1, PROCESS_FIELD
	
	# Count new bytes states
	ldi r3, 31 # row iterator
	do
		push r3 # Save row iterator
		ldi r0, IOY
		st r0, r3

		# If all rows in env. are null => skip this row
		ldi r3, IONullRowsEnv
		ld r3, r3
		tst r3
		bnz rowProcessed

		ldi r1, 31 # Bit index
		ldi r3, 4 # byte in row iterator
		do 
			push r3 # Save byte in row iterator

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
				ldi r1, IOBit
				ld r1, r1

				# Check birth or death conditions and save bit depends on conditions
				if
					tst r0
				is nz
					jsr processBit
				else
					if 
						tst r1
					is nz
						ldi r0, IOInvertBitSignal
						st r0, r0
					fi
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
			pop r3
			dec r3
		until z
		rowProcessed:

		pop r3 # Get row iterator
		dec r3
	until mi
# Go to infinite cycle
br main

halt
end
