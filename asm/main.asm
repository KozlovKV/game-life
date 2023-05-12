# Internal data addresses
asect 0xd0
gameMode:

asect 0xe0
birthConditionsRowStart:

asect 0xe8
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
IONullHalfByteEnv:

asect 0xf9
IOInvertBitSignal:

asect 0xfa
IOUpdateGeneration:

asect 0
br start

#==============================#
#     Place for subroutines    #
#==============================#
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
	setsp 0xd0


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
	
	# Count new bytes states
	ldi r3, 31 # row iterator
	do
		# If game mode stays = 0 we go to start code part 
		ldi r0, IOGameMode
		ld r0, r0
		tst r0
		bz start

		push r3 # Save row iterator
		ldi r0, IOY
		st r0, r3

		# If all rows in env. are null => skip this row
		ldi r3, IONullRowsEnv
		ld r3, r3
		tst r3
		bnz rowProcessed

		ldi r1, 31 # Bit index
		ldi r3, 8 # byte in row iterator
		do 
			push r3 # Save byte in row iterator

			# byte env. (from x-7 to x) is null => byte will be 0
			ldi r0, IOX
			st r0, r1
			ldi r0, IONullHalfByteEnv
			ld r0, r0
			tst r0
			bnz skipHalfByte

			ldi r3, 4
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
					# If sum = 0 alive cell must die
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
			skipHalfByte:
				ldi r0, -4
				add r0, r1
			byteProcessed:
			pop r3
			dec r3
		until z
		rowProcessed:

		pop r3 # Get row iterator
		dec r3
	until mi
# Infinite simulation cycle
br main

halt
end
