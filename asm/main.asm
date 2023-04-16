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

asect 0x30
leftCurrentY:

asect 0x31
leftCurrentX:

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
asect 0
WAIT:

asect 1
READ_FIELD:

asect 2
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
	ldi $2, 0x90  # Negatated 0x70
	add $2, $1
	inc $1
	shl $1
	shra $1
	neg $2
	add $2, $1
mend

macro changeCPUStatus/3
# args 1, 2 - free regs
# arg 3 - new status
	ldi $1, IOCPUStatus
	ldi $2, $3
	st $1, $2
mend

asect 0x00
run start

#==============================#
#     Place for subroutines    #
#==============================#

#===============================

start:
	# Move SP before I/O and field addresses
	addsp 0x70

	changeCPUStatus r0, r1, WAIT

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
	
	changeCPUStatus r0, r1, READ_FIELD
	
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
		ldi r1, 0x20
		cmp r3, r1
	until ge
	
	
	changeCPUStatus r0, r1, PROCESS_FIELD
	
	# Count new bytes states
	ldi r0, 31 # Y of first surrounding byte
	ldi r2, leftCurrentY
	st r2, r0
	ldi r1, 3 # X of first surrounding byte
	ldi r2, leftCurrentX
	st r2, r1
	ldi r2, 128 # iterator
	ldi r3, 4
	do
		push r2
		push r3
		ldi r0, leftCurrentY
		ld r0, r0
		ldi r1, leftCurrentX
		ld r1, r1
		ldi r3, envFirstByte
		ldi r2, 3
		push r2 
		do 
			push r0
			getRowBeginAddr r0, r2
			add r1, r0
			ld r0, r0
			st r3, r0
			
			pop r0
			pop r2
			dec r2
			if
				tst r2
			is z
				inc r0
				ldi r2, 0b00011111
				and r2, r0
				ldi r1, leftCurrentX
				ld r1, r1
				ldi r2, 3
				push r2
			else
				push r2
				inc r1
				ldi r2, 0b00000011
				and r2, r1
			fi
			
			
			inc r3
			ldi r2, envLastByte
			cmp r3, r2
		until gt
		
		push r0
		
		#########################################################
		# HERE WILL BE MAIN CODE FOR COUNTING STATE OF NEW BYTE #
		#########################################################
		
		
		#########################################################
		
		
		pop r0
		
		# Set next begin X
		ldi r3, leftCurrentX
		ld r3, r1
		inc r1
		ldi r2, 0b00000011
		and r2, r1
		st r3, r1
		
		# Set next row value
		pop r2
		pop r3
		dec r3 # DON'T CHANGED AFTER IT IN THIS CYCLE
		if 
			tst r3
		is z
			dec r0
			dec r0
			ldi r2, leftCurrentY
			st r2, r0
		fi
				
		
		pop r2
		dec r2 # DON'T CHANGED AFTER IT IN THIS CYCLE
		tst r2
	until z
br main

halt
end
