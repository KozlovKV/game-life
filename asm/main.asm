# Internal data addresses
asect 0xe0
birthConditionsRowStart:

asect 0xe8
deathConditionsRowStart:

asect 0xd0
isNonStaticGeneration:

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
IONextSignificantX:

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
	# Iterator
	ldi r3, 0b00001000 # 8
	while
		tst r3
	stays nz
		# The process of spreading byte
		# Get lower bit and save to current cell
		ldi r2, 0b00000001
		and r0, r2
		st r1, r2

		# Increment cell address, shift data byte and decrement iterator
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
		
		# Set flag for non-static generation to its address (!= 0)
		ldi r0, isNonStaticGeneration
		st r0, r0
	fi
rts

#===============================

start:
	# Move SP before destributed cells
	setsp 0xd0

	# Waiting for IOGameMode I/O reg. != 0
	ldi r1, IOGameMode
	do 
		ld r1, r0
		tst r0
	until nz

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
	
	# Reset flag for non-static
	ldi r0, isNonStaticGeneration
	ldi r1, 0
	st r0, r1

	# Update stable generation's buffer to get new data from env. data constructor
	ldi r0, IOUpdateGeneration
	st r0, r0
	
	# Count new cells' states
	ldi r3, 31 # row iterator
	do
		# If game mode = 0 we interrupt cycle and go to start code part
		# NEW GENERATION CAN BE COUNTED PARTITIONALLY 
		ldi r0, IOGameMode
		ld r0, r0
		tst r0
		bz start

		push r3 # Save row iterator

		# Send Y to logisim
		ldi r0, IOY
		st r0, r3

		# If all rows in env. are null => skip this row
		ldi r3, IONullRowsEnv
		ld r3, r3
		tst r3
		bnz rowProcessed

		ldi r1, 0 # Value for searching first significant X

		# Send X to Logisim
		ldi r0, IOX
		st r0, r1

		# Get the first X with significant env.
		ldi r3, IONextSignificantX
		ld r3, r2

		do 
			# Save currnt X
			move r2, r1
			push r1

			# Send X to Logisim
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

					# Set flag for non-static generation to its address (!= 0)
					ldi r0, isNonStaticGeneration
					st r0, r0
				fi
			fi

			# Get the next X with significant env. lower than current
			pop r1
			ld r3, r2

			# If new X greater of equal => cycle ends
			cmp r2, r1 
		until ge
		rowProcessed:

		# Get and decrement row iterator
		pop r3
		dec r3
	until mi
# Go to main cycle begin if generation isn't static
ldi r0, isNonStaticGeneration
ld r0, r0
tst r0
bnz main
# Otherwise reset game mode and go to start
ldi r0, IOGameMode
st r0, r0
br start

halt
end
