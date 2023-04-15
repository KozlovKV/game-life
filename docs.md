- [Documentation](#documentation)
  - [Assembler](#assembler)
  - [Logisim](#logisim)
    - [Data-load cycle](#data-load-cycle)
    - [Controls](#controls)
    - [Keyboard handler](#keyboard-handler)
    - [Video buffer](#video-buffer)
    - [Blinker (bit changer)](#blinker-bit-changer)
    - [32-bit row destructor](#32-bit-row-destructor)

# Documentation
## Assembler

## Logisim
Harvard architecture on `CdM-8-mark8-full`.

### Data-load cycle
```asm
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
		ldi r1, lastFieldByte
		cmp r0, r1
	until hi
```

### Controls
*Describe what key what do*

### Keyboard handler
This circuit considers 8-bit ASCII input as ASCII code and compares it with constants related to some keys and make list of actions:
- increment/decrement X/Y of cursor
- switch state of selected cell
- start life simulation

For more information about keys see [controls topic](#controls)

*Picture*

### Video buffer
Multifunctional circuit that:
- lets us save selected matrix row (32 bits) (west)
- sends all 32 rows to the matrix (east)
- gives separated chosen row (south)

*Full inputs/outputs description*

*Picture*

### Blinker (bit changer)
Переключатель бита в матрице. Должен будет переключать значение заданного бита на противоположное, если поднимается вход switch. Важно, что данный элемент не должен хранить в себе новые значения, а должен просто направлять их наружу

Входы:
- clock (при необходимости)
- строки матрицы, 32 входа по 32 бита
- координата Y (номер строки), 5 бит
- координата X (номер бита в строке), 5 бит
- switch - при его поднятии выбранный бит должен будет измениться на обратный

Выходы:
- 32 выхода по 32 бита, в одном из которых один бит был изменён
- строка с изменённым битом длиной 32 бита

### 32-bit row destructor
Selects needed bit and byte containing its from 32-bit string

Inputs:
- `row` - 32 bit
- `sel` - 5 bit 

Outputs:
- `byte` - 8 bit - byte containing selected bit
- `bit` - 1 bit