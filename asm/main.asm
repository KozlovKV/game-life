asect -16
stackOffset:

asect 0xf0
gameMode:

asect 0xf1
birthConditions:

asect 0xf2
survivalConditions:

asect 0xf3
IOY:

asect 0xf4
IOX:

asect 0xf5
rowController:

asect 0xf6
fristByte:

asect 4
bytesInRow:

#===============================
  ### Place for subroutines ###
#===============================


#===============================

asect 0x00
start:
	addsp stackOffset

	# place your main code here

	halt
end

