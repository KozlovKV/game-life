asect 0
goto z, start


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

asect 0x60
envFirstByte:
envTopLeftByte:

asect 0x61
envTopByte:

asect 0x62
envTopRightByte:

asect 0x63
envLeftByte:

asect 0x64
envCentreByte:

asect 0x65
envRightByte:

asect 0x66
envBottomLeftByte:

asect 0x67
envBottomByte:

asect 0x68
envLastByte:
envBottomRightByte:

asect 0x69
newByteAddr:

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
		
processBitInByte:
	push r0
	push r1
	jsr getBit
	if
		tst r0
	is eq
		if
			tst r2
		is z
			# For zero sum we cell cannot birth
			ldi r2, 0
			br inverting
		fi
		ldi r0, birthConditions
	else
		if
			tst r2
		is z
			# For zero sum we kill alive cell
			ldi r2, 1
			br inverting
		fi
		ldi r0, deathConditions
	fi
	ld r0, r0
	move r2, r1
	dec r1
	jsr getBit
	move r0, r2
	inverting:
	pop r1
	pop r0
	if
		tst r2
	is nz
		jsr invertBit
	fi
rts

bitCheckWithSum:
	# Check bit with index from r1 in byte from r0 and increments r2 if there is one
	# check bit in surrounding byte
	jsr getBit
	if 
		tst r0
	is nz
		inc r2 # sum++
	fi
rts

getNewByteState:
	# Doesn't need any args - all data saved in RAM
	# Returns new byte in r0

	# Save current byte initial state
	ldi r0, envCentreByte
	ld r0, r0
	ldi r1, newByteAddr
	st r1, r0

	# =============
	# Process 7 bit

	ldi r2, 0 # Initial sum value

	# Count bits 6,7 in top byte
	ldi r3, envTopByte
	ld r3, r0
	ldi r1, 6 # top-left bit
	jsr bitCheckWithSum

	ld r3, r0
	ldi r1, 7 # top bit
	jsr bitCheckWithSum

	# Count bit 6 in centre byte
	ldi r0, envCentreByte
	ld r0, r0
	ldi r1, 6 # left bit
	jsr bitCheckWithSum

	# Count bits 6,7 in bottom byte
	ldi r3, envBottomByte
	ld r3, r0
	ldi r1, 6 # bottom-left bit
	jsr bitCheckWithSum

	ld r3, r0
	ldi r1, 7 # bottom bit
	jsr bitCheckWithSum

	# Check bit 7 in top-right byte
	ldi r0, envTopRightByte
	ld r0, r0
	ldi r1, 0 # top-right bit
	jsr bitCheckWithSum

	# check bit 7 bit in right byte
	ldi r0, envRightByte
	ld r0, r0
	dec r1 # After getBit subroutine r1 already has been 1 and we need 0 - right bit
	jsr bitCheckWithSum

	# check bit 7 in bottom-right byte
	ldi r0, envBottomRightByte
	ld r0, r0
	dec r1 # After getBit subroutine r1 already has been 1 and we need 0 - bottom-right bit
	jsr bitCheckWithSum

	# Load processed (initial) byte state
	ldi r0, newByteAddr
	ld r0, r0
	ldi r1, 7 # Set processing bit
	jsr processBitInByte
	ldi r1, newByteAddr
	st r1, r0
	# =============

	# =============
	# Process bits 6-1

	ldi r1, 6 # Processing bit index and iterator
	do
		push r1 # Save bit index
		push r1 # Duplicate for fast working at the end of cycle
		ldi r0, envTopByte # First needed surrounding byte
		dec r1 # Get leftTopX

		# Save index to stack for working in internal cycle below
		push r1
		push r1
		ldi r2, 0 # Initial sum value
		ldi r3, 8 # iterator for decrementing
		do
			# save byte addr and bit index before getting bit
			push r0 
			push r1
			ld r0, r0
			jsr bitCheckWithSum

			# increment bitIndex in surrounding bytes
			pop r1
			inc r1

			# Weather r3 == 5 we will be in centre bit in centre byte => increment r1 again
			ldi r0, 5
			cmp r0, r3
			bz additionalSurroundingBitInc

			# Wheather r3 == 4 or r3 == 6 we need change reading byte addrs in range [0x41 (envTopByte), 0x44, 0x47]
			ldi r0, 4
			cmp r0, r3
			bz changeSurroundingByteAddr
			# goto z, changeSurroundingByteAddr
			ldi r0, 6
			cmp r0, r3
			bz changeSurroundingByteAddr
			# goto z, changeSurroundingByteAddr
			bnz popByteAddr
			# goto nz, popLeftIndex

			changeSurroundingByteAddr:
				pop r0 # get saved byte addr
				ldi r1, 3
				add r1, r0 # byteAddr += 3
				pop r1 # get topLeftX
				br sumCycleEnd
			additionalSurroundingBitInc:
				inc r1
			popByteAddr:
				pop r0
			sumCycleEnd:
				dec r3
		until z

		# Load processed (initial) byte state
		ldi r0, newByteAddr
		ld r0, r0
		pop r1
		jsr processBitInByte
		ldi r1, newByteAddr
		st r1, r0
		pop r1
		dec r1
	until z
	# ================		

	# =============
	# Process 0 bit
	ldi r2, 0 # Initial sum value
	
	# Check bit 7 in top-left byte
	ldi r0, envTopLeftByte
	ld r0, r0
	ldi r1, 7 # top-left bit
	jsr bitCheckWithSum

	# check bit 7 in left byte
	ldi r0, envLeftByte
	ld r0, r0
	ldi r1, 7 # left bit
	jsr bitCheckWithSum

	# check bit 7 in bottom-left byte
	ldi r0, envBottomLeftByte
	ld r0, r0
	ldi r1, 7 # bottom-left bit
	jsr bitCheckWithSum

	# Count bits 0,1 in top byte
	ldi r3, envTopByte
	ld r3, r0
	ldi r1, 0 # top bit
	jsr bitCheckWithSum

	ld r3, r0
	# After getBit subroutine r1 already has been 1 - top-right bit
	jsr bitCheckWithSum

	# Count bit 1 in centre byte
	ldi r0, envCentreByte
	ld r0, r0
	ldi r1, 1 # right bit
	jsr bitCheckWithSum

	# Count bits 0,1 in bottom byte
	ldi r3, envBottomByte
	ld r3, r0
	ldi r1, 0 # bottom bit
	jsr bitCheckWithSum

	ld r3, r0
	# After getBit subroutine r1 already has been 1 - bottom-right bit
	jsr bitCheckWithSum

	# Load processed (initial) byte state
	ldi r0, newByteAddr
	ld r0, r0
	ldi r1, 0 # Set processing bit
	jsr processBitInByte
	ldi r1, newByteAddr
	st r1, r0
	# =============
	
	# get return value
	ldi r0, newByteAddr
	ld r0, r0
rts

checkByteForNull:
	# set byte isNotNullEnv to not-null value if r0 != 0
	# r2 will be rewrited
	if
		tst r0
	is nz
		ldi r2, isNotNullEnv
		st r2, r0
	fi
rts

environmentRowBitSpreading:
	# r0 - row index
	# r1 - row's byte index
	# r3 - beginnig cell memory cell

	push r0
	push r1
	# Get cell addr. for left byte
	getRowBeginAddr r0, r2
	add r1, r0

	# Get 7th bit for left byte and save it to left cell in env. row
	ldi r1, 7
	ld r0, r0
	jsr getBit
	jsr checkByteForNull
	st r3, r0

	# Move to the 0th bit addr in env. cycled increment for row's byte index
	inc r3
	pop r1
	pop r0
	inc r1
	ldi r2, 0b00000011
	and r2, r1

	push r0
	push r1
	# Get cell addr. for mid byte
	getRowBeginAddr r0, r2
	add r1, r0
	ld r0, r1 # get mid byte for env. row
	ldi r2, 8 # iterator
	do
		# get 0th bit in shifted byte and save it to byte in env. row
		ldi r0, 1 
		and r1, r0
		st r3, r0
		
		# Check for null value
		push r2
		jsr checkByteForNull
		pop r2

		# byte >>= 1
		shr r1
		# addr. in env. byte++
		inc r3
		# iterator--
		dec r2
	until z

	pop r1
	pop r0
	inc r1
	ldi r2, 0b00000011
	and r2, r1
	# Get cell addr. for right byte
	getRowBeginAddr r0, r2
	add r1, r0
	# Get 0th bit for right byte and save it to right cell in env. row
	ldi r1, 0
	ld r0, r0
	jsr getBit
	jsr checkByteForNull
	st r3, r0
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
	ldi r3, 0x1f # row Y index (will goes from last to first)
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

		# ===================
		# Environment getting
		# ===================

		# Get top-left byte coords
		ldi r0, topLeftY
		ld r0, r0
		ldi r1, topLeftX
		ld r1, r1

		# Initital data for writing surrounding bytes
		ldi r3, isNotNullEnv
		ldi r2, 0
		st r3, r2
		ldi r3, envTopRowBegin
		ldi r2, 3 # Iterator
		do 
			push r2
			push r0 # Save surrounding cell's Y

			jsr environmentRowBitSpreading
			
			# move env. row addr to the next line
			ldi r0, 0xf0
			and r0, r3
			ldi r0, 0x10
			add r0, r3

			pop r0 # Get surrounding cell's Y
			inc r0 
			ldi r2, 0b00011111
			and r2, r0
			# Reset X value to beggining
			ldi r1, topLeftX
			ld r1, r1
			
			pop r2
			dec r2
		until z
		# ===================
		
		push r0 # Save bottom row Y

		# If environment isn't null we work with it, otherwise r0 will be 0
		ldi r0, isNotNullEnv
		ld r0, r0
		if
			tst r0
		is nz
			# jsr getNewByteState
			ldi r0, 0xff
		fi

		# Save new byte in I/O reg.
		pop r2 # Get bottom row Y
		pop r3 # Get row subiterator
		push r3
		ldi r1, IORowLastByte
		inc r1
		neg r3
		add r3, r1 # Get current IO reg. for row byte = IORowLastByte + 1 - subiterator
		st r1, r0
		move r2, r0 # Move row Y to released r0
		
		# Set next X for top-left cell
		ldi r3, topLeftX
		ld r3, r1
		inc r1
		ldi r2, 0b00000011
		and r2, r1
		st r3, r1
		
		# Set next row value if subiterator == 0
		pop r3
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
			ldi r2, IOY # Previous centre row Y is new topLeftY
			st r2, r0
			ldi r2, IORowController
			st r2, r0

		fi
		
		pop r2 # Get global iterator [128, 1]
		dec r2 # DON'T CHANGED AFTER IT IN THIS CYCLE
	until z
goto z, main

halt
end
