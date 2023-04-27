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

asect 0b00000100
baseBirthConditions:

asect 0b11111001
baseDeathConditions:

asect 0
br getNewByteState

#===============================
getBit:
	while
		dec r1
	stays pl
		shr r0
		# if
		# is z
		# 	break
		# fi
	wend
	ldi r1, 1
	and r1, r0
rts

invertBit:
	ldi r2, 1
	while
		dec r1
	stays pl
		shl r2
	wend
	xor r2, r0
rts
		
processBitInByte:
	# Половинчатая проработка случая, когда вокруг бита нет байтов
	if
		tst r2
	is z
		rts
	fi

	push r0
	push r1
	jsr getBit
	if
		tst r0
	is eq
		# ldi r0, birthConditions
		ldi r0, baseBirthConditions
	else
		# ldi r0, deathConditions
		ldi r0, baseDeathConditions
	fi
	# ld r0, r0
	move r2, r1
	dec r1
	jsr getBit
	move r0, r2
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
		until le

		# Load processed (initial) byte state
		ldi r0, newByteAddr
		ld r0, r0
		pop r1
		jsr processBitInByte
		ldi r1, newByteAddr
		st r1, r0
		pop r1
		dec r1
	until le
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
#===============================

halt
end