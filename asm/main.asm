asect 0
goto eq, start

# Internal data addresses
asect 0x40
gameMode:
WAIT:

asect 0x41
birthConditions:
READ_FIELD:

asect 0x42
deathConditions:
PROCESS_FIELD:

asect 0x60
envFirstByte:

asect 0x68
envLastByte:

asect 0x50
topLeftY:

asect 0x51
topLeftX:

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
IOCPUStatus:


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
		tst r1
	stays nz
		shr r0
		dec r1
	wend
	ldi r1, 1
	and r1, r0
rts

invertBit:
	ldi r2, 1
	while
		tst r1
	stays nz
		shl r2
		dec r1
	wend
	xor r2, r0
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
	
	changeCPUStatus r0, r1, READ_FIELD
	
	# Load field from videobuffer
	ldi r0, lastFieldByte
	ldi r3, 0x1f # Y position (row) (will goes from last to first)
	do
		# Tell logisim with which row we will interact
		ldi r1, IOY
		st r1, r3
		# Send read signal for row registers
		ldi r1, IORowController
		ld r1, r1  # second arg. is a blank
		# Read data from row regs and save to field
		ldi r1, IORowLastByte # Begin from last byte
		do
			ld r1, r2
			st r0, r2
			dec r0
			dec r1
			ldi r2, IORowFirstByte
			cmp r1, r2
		until lt
		dec r3
	until lt
	
	
	changeCPUStatus r0, r1, PROCESS_FIELD
	
	# Count new bytes states
	ldi r0, 31 # Y of first surrounding byte (top-left)
	ldi r2, topLeftY
	st r2, r0
	ldi r1, 3 # X of first surrounding byte
	ldi r2, topLeftX
	st r2, r1
	ldi r2, 128 # iterator
	ldi r3, 4 # sub iterator for changing topLeftY value
	do
		# Save iterators
		push r2
		push r3

		# Get top-left byte coords
		ldi r0, topLeftY
		ld r0, r0
		ldi r1, topLeftX
		ld r1, r1

		# Initital data for writing surrounding bytes
		ldi r3, envFirstByte
		ldi r2, 3 # Iterator for changing surrounding Y
		push r2 # Save iterator
		do 
			push r0 # Save surrounding cell's Y

			# Get cell addr. for byte
			getRowBeginAddr r0, r2
			add r1, r0
			# Load byte value and save to environment cell
			ld r0, r0
			st r3, r0
			
			pop r0 # Get surrounding cell's Y
			pop r2 # Get iterator for changing surrounding cell's Y
			dec r2
			if
			is z
				# Weather iterator == 0
				# Cycled inc for Y
				inc r0 
				ldi r2, 0b00011111
				and r2, r0
				# Reset X value to beggining
				ldi r1, topLeftX
				ld r1, r1
				# Update and save iterator for changing surrounding cell's Y
				ldi r2, 3
				push r2
			else
				# Weather iterator != 0 simply save its and cycle increment X
				push r2
				inc r1
				ldi r2, 0b00000011
				and r2, r1
			fi
			
			# Increment addr. for evnironment array and check weather we finished surrounding bytes saving 
			inc r3
			ldi r2, envLastByte
			cmp r3, r2
		until gt
		
		pushall # Save all values before processing new byte
		
		#########################################################
		# HERE WILL BE MAIN CODE FOR COUNTING STATE OF NEW BYTE #
		#########################################################
		
		
		#########################################################
		
		popall
		
		# Set next X for top-left cell
		ldi r3, topLeftX
		ld r3, r1
		inc r1
		ldi r2, 0b00000011
		and r2, r1
		st r3, r1
		
		# Set next row value if subiterator == 0
		pop r2
		pop r3 # Get row subiterator
		dec r3 # DON'T CHANGED AFTER IT IN THIS CYCLE
		if 
		is z
			dec r0
			dec r0
			ldi r2, 0b00011111
			and r2, r0
			ldi r2, topLeftY
			st r2, r0
			ldi r3, 4 # Update row subiterator

			# Save new row to buffer
			ldi r2, IOY
			st r2, r0
			ldi r2, IORowController
			st r2, r0

		fi
				
		
		pop r2 # Get global iterator [128, 1]
		dec r2 # DON'T CHANGED AFTER IT IN THIS CYCLE
	until z
goto eq, main

halt
end
