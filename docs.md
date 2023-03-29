- [Documentation](#documentation)
  - [Assembler](#assembler)
  - [Logisim](#logisim)
    - [Controls](#controls)
    - [Keyboard handler](#keyboard-handler)
    - [Video buffer](#video-buffer)

# Documentation
## Assembler

## Logisim
Harvard architecture on `CdM-8-mark8-full`.

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
- lets us save selected matrix row (32 bits)
- sends all 32 rows to the matrix
- gives value of row, byte and bit by X, Y values

*Full inputs/outputs description*

*Picture*