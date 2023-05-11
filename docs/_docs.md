- [How to play](#how-to-play)
- [Documentation](#documentation)
- [Assembler](#assembler)
	- [Short description](#short-description)
	- [RAM distribution](#ram-distribution)
		- [Cells referring to I/O regs.](#cells-referring-to-io-regs)
	- [Code description](#code-description)
		- [Start part](#start-part)
		- [Main part](#main-part)
		- [Subroutines](#subroutines)
			- [`spreadByte`](#spreadbyte)
			- [`processBit`](#processbit)
- [Logisim](#logisim)
	- [Main concept](#main-concept)
	- [Controls](#controls)
		- [Main signals](#main-signals)
		- [Keyboard](#keyboard)
			- [Keyboard layouts](#keyboard-layouts)
	- [I/O registers](#io-registers)
		- [I/O registers' types](#io-registers-types)
			- [`PSEUDO WRITE`](#pseudo-write)
		- [Short description table](#short-description-table)
		- [List](#list)
	- [Elements description](#elements-description)
		- [Engine](#engine)
		- [Keyboard controller](#keyboard-controller)
		- [Random write buffer](#random-write-buffer)
		- [Stable generation's buffer](#stable-generations-buffer)
		- [Environment data constructor](#environment-data-constructor)
		- [Row's bit invertor](#rows-bit-invertor)
		- [Binary selector](#binary-selector)
		- [Blinker (bit changer)](#blinker-bit-changer)

<style>
	body {
		font-size: 14px;
	}
	h1 {
		text-align: center;
		font-size: 2rem;
		margin-top: 7%;
	}
	h2, h3, h4 {
		margin-top: 3%;
	}
	h2 {
		font-size: 1.75rem;
	}
	h3 {
		font-size: 1.5rem;
	}
	h4 {
		font-size: 1.25rem;
	}
</style>

# How to play
Our version of "Conway game of life" works with universal sets of conditions for birth and survival. To set conditions switch bits in birth/survival 8-bit inputs where value 1 on position `N` means that birth/survival will be fulfilled when cell has `N` neighbors.

After this click on keyboard element and use one of two [keyboard layouts](#keyboard-layouts) to move blinking cursor and change cells' states.

When you set initial field state press button start and observe evolution!

# Documentation
# Assembler
## Short description
Due to optimization reasons CdM-8 has only one main task - iteration by Y,X positions and determination whether cell should be changed. After the all cells' processing CdM-8 send signal to [update generation]

**In ASM code we use `asect` constants like this:**
```
asect 8
constSample:

# ...

ldi r0, constSample  # r0 sets to 8 
```

**Often we save address value to its address:**
```
ldi r0, IOAddr
st r0, r0
```
**The reason for this action is [`PSEUDO WRITE`](#pseudo-write) mode for some I/O registers**

## RAM distribution
- `0xd0` - game state (`0` - wait, `1` - simulate)
- `0xe0` - birth's conditions first byte
- `0xe8` - death's conditions first byte

**Stack initial position - `0xd0`**

<details>
<summary>Constants for this cells</summary>

```
# Internal data addresses
asect 0xd0
gameMode:

asect 0xe0
birthConditionsRowStart:

asect 0xe8
deathConditionsRowStart:
```
</details>

### Cells referring to I/O regs.
Cells from `0xf0` to `0xff` are allocated for I/O registers. 

**See detailed description in [Logisim topic](#io-registers)**

<details>
<summary>Constants for I/O cells</summary>
<br>

```
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
```

</details>

## Code description
### Start part
This part just waits whilst user presses start button and after it loads game conditions to RAM using [spreadByte subroutine](#spreadbyte)

**For optimized conditions checking survival conditions inverts to death's conditions. [See more here](#list)**

<details>
<summary>Code</summary>
<br>

```
asect 0
br start

#==============================#
#     Place for subroutines    #
#==============================#
...
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
```
</details>

### Main part
*Add after minor editing*

### Subroutines
#### `spreadByte`
*Add spread byte description*

#### `processBit`
- This subroutine gets neighbors' sum in `r0` and centre bit value in `r1`.
- Depending on bit value it chooses birth or death conditions
- Thanks to [spreaded conditions](#spreadbyte) we can simply add to conditions' begin address value `r0 - 1` and check data by new address
- If there is 1 we should change value in selected cell so [we send this signal to Logisim](#list)

<details>
<summary>Code</summary>
<br>

```
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
```
</details>


*What to do if there is no neighbors?*

We decided that alive cell should die and death cell cannot birth. Due to specific work with `sum = 0` this case for `bit = 1` is processed in [main part](#main-part):
```
...
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
...
```

---

# Logisim
Harvard architecture on `CdM-8-mark8-reduced`.

## Main concept
*Describe how works main circuit and make links to subtopics*

## Controls
### Main signals
*Write about conditions bit arrays*

### Keyboard
Logisim circuits keyboard handles keys' presses and send 7-bit ASCII codes to [Keyboard controller](#keyboard-controller)

**All keys are working only while we are in the `setting` game mode**

#### Keyboard layouts
Cursor moving:
KEY           | DIRECTION    | X DELTA | Y DELTA
:-:           | :-:          | :-:     | :-:
`NUM 1` / `Z` | bottom-left  | `-1`    | `+1`
`NUM 2` / `S` | bottom       | `0`     | `+1`
`NUM 3` / `C` | bottom-right | `+1`    | `+1`
`NUM 4` / `A` | left         | `-1`    | `0`
`NUM 6` / `D` | right        | `+1`    | `0`
`NUM 7` / `Q` | top-left     | `-1`    | `-1`
`NUM 8` / `W` | top          | `0`     | `-1`
`NUM 9` / `E` | top-right    | `+1`    | `-1`

`NUM 5` / `Space` - change state of selected cell.

## I/O registers
I/O bus have minor changes: selection of I/O addresses from CPU `addr` is detected by `less than` comparator's output with the second input `0xf0` (the first I/O cell address)

![I/O bus](./IO-bus.png)

### I/O registers' types
**All types' names are regarding the CPU directions**

Registers have trivial types of data direction: `READ ONLY` and `WRITE ONLY`.

#### `PSEUDO WRITE`
Besides these types we use one specific type - `PSEUDO WRITE`. CPU cannot write data to this "registers". Main goal for this type is handle `write` signal by CdM-8's `st` instruction.

### Short description table
CELL ADDR.    | "NAME"                 | DATA DIRECTION TYPES 
:--           | :--                    | :--                  
`0xf0`        | GAME STATE             | `READ ONLY`          
`0xf1`        | BIRTH CONDITIONS       | `READ ONLY`          
`0xf2`        | DEATH CONDITIONS       | `READ ONLY`          
`0xf3`        | Y                      | `WRITE ONLY`         
`0xf4`        | X                      | `WRITE ONLY`        
`0xf5`        | SELECTED BIT           | `READ ONLY`          
`0xf6`        | ENVIRONMENT SUM        | `READ ONLY`          
`0xf7`        | NULL ROWS ENVIRONMENT  | `READ ONLY`          
`0xf8`        | NULL BYTES ENVIRONMENT | `READ ONLY`         
`0xf9`        | INVERSION SIGNAL       | `PSEUDO WRITE`
`0xfa`        | UPDATE GENERATION      | `PSEUDO WRITE`

*separate list below into divided topics*
### List
- `0xf0` - READ ONLY - состояние игры. `0` - настройка. `1` - симуляция
- `0xf1` - READ ONLY - количество клеток для оживления (битовый массив, где `i`-й бит говорит о `i+1` количестве клеток для выполнения условия)
- `0xf2` - READ ONLY - количество клеток, при которых клетка умрёт (битовый массив, где `i`-й бит говорит о `i+1` количестве клеток для выполнения условия)
- `0xf3` - WRITE ONLY - координата Y строки, с которой сейчас работаем
- `0xf4` - WRITE ONLY - координата X (*скорее всего не будет нужен*)
- `0xf5` - PSEUDO READ / PSEUDO WRITE - бит бит направления строки из следующих четырёх регистров. 
  - Когда сюда отправляется запрос на запись, значение строки из последующих 4 байтов отправляется записывается в строку `Y` видеобуфера. 
  - Когда отправляется запрос на чтение, выгружает в следующие 4 регистра строку по индексу `Y`
- `0xf6`-`0xf9` - READ / WRITE - 4 регистра для выбранной строки в порядке little-endian (при запросе на чтение будет загружаться из буфера, при запросе на запись будет отправлять значение во временное хранилище)
- `0xfa` - WRITE ONLY - отображает номер процесса, которым сейчас занят процессор. Используется для отладки

## Elements description
### Engine
*soon*

### Keyboard controller
This circuit considers 7-bit ASCII input as ASCII code and compares it with constants related to some keys and make list of actions:
- Cycled increment/decrement X/Y of cursor
- Send switch signal for switching the cell's state

For more information about keys see [controls topic](#controls)

*Picture*

### Random write buffer

Multifunctional circuit that:
- lets us save selected matrix row (32 bits) (west)
- sends all 32 rows to the matrix (east)

*Full inputs/outputs description*

**WORKS ASYNCHRONOUSLY (value from `Input row` saves when `Write row` rises)**

### Stable generation's buffer
*soon*

### Environment data constructor
*soon*

### Row's bit invertor
*soon*

### Binary selector
*soon*

### Blinker (bit changer)
Переключатель бита в матрице. Должен будет переключать значение заданного бита на противоположное, если поднимается вход switch. Важно, что данный элемент не должен хранить в себе новые значения, а должен просто направлять их наружу

Входы:
- строки матрицы, 32 входа по 32 бита
- координата Y (номер строки), 5 бит
- координата X (номер бита в строке), 5 бит
- switch - при его поднятии выбранный бит должен будет измениться на обратный

Выходы:
- 32 выхода по 32 бита, в одном из которых один бит был изменён
- строка с изменённым битом длиной 32 бита