- [Documentation](#documentation)
  - [Assembler](#assembler)
  - [Logisim](#logisim)
    - [Controls](#controls)
    - [Keyboard handler](#keyboard-handler)
    - [Video buffer](#video-buffer)
    - [Blinker (bit changer)](#blinker-bit-changer)

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