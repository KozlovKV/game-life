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

macro getRowBeginAddr/2
# Gets row index and returns addr of begin of its row
# 1st reg - result
# 2nd reg - helping
	ldi $2, 0x70
	shla $1
	shla $1
	add $2, $1
mend

asect 0
addsp 0x40
br start

# ==============================
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
# ==============================

macro debugSt/2
  ldi r0, $1
  ldi r1, $2
  st r1, r0
mend

start:

  debugSt 0x0f, 0xef
  debugSt 0b11111100, 0xec
  debugSt 0b10101010, 0xed
  debugSt 0xff, 0x73
  debugSt 0b00111100, 0x70
  debugSt 0b10101010, 0x71
  debugSt 0, 0x77
  debugSt 0b00111111, 0x74
  debugSt 0b10101010, 0x75

	ldi r0, 31 # Y of first surrounding byte (top-left)
	ldi r2, topLeftY
	st r2, r0
	ldi r1, 3 # X of first surrounding byte
	ldi r2, topLeftX
	st r2, r1
	
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
			ldi r2, 0xf0
			and r2, r3
			ldi r2, 0x10
			add r2, r3

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

halt
end