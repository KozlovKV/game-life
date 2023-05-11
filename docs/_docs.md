- [Documentation](#documentation)
- [Assembler](#assembler)
	- [Short description](#short-description)
	- [RAM distribution](#ram-distribution)
		- [Cells referring to I/O regs.](#cells-referring-to-io-regs)
	- [Code description](#code-description)
- [Logisim](#logisim)
	- [Main concept](#main-concept)
	- [Controls](#controls)
		- [Main signals](#main-signals)
		- [Keyboard](#keyboard)
			- [Keys definitions](#keys-definitions)
	- [I/O registers](#io-registers)
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

# Documentation
# Assembler
## Short description
*Soon*

## RAM distribution
- `0xd0` - game state (`0` - wait, `1` - simulate)
- `0xe0` - birth's conditions first byte
- `0xe8` - death's conditions first byte

**Stack initial position - `0xd0`**

### Cells referring to I/O regs.
Cells from `0xf0` to `0xff` are allocated for I/O registers. 

See detailed description in [Logisim topic](#io-registers)

## Code description
*Will be soon*

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

#### Keys definitions
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

Registers have trivial types of data direction: `READ ONLY` and `WRITE ONLY`.

Besides these types two specific types were added: `PSEUDO READ`, `PSEUDO WRITE`. From these registers CPU reads meaningless value and cannot write data into them. Main goal of these types is handling `read`/`write` signals that are used for comfortable communication between CPU and circuits in some specific cases (*see read/write rows topic*)

**All types' names are regarding the CPU directions**

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