
# zeiss_probe2csv

Extract probe configurations, strategies and probe buttons from ZEISS Calypso programs into CSV file

Using LUA interpreter
## Configuration

Edit file **probe2csv_settings.lua**

Usage with shortcut and working dir
```lua
p_path = lfs.currentdir()
```
Usage with defined root directory
```lua
p_path = "c:\\Users\\Public\\Documents\\Zeiss\\CALYPSO 6.6\\workarea\\inspections"
```
Format of CSV <sub>( divided by comma )</sub>
```lua
-- plan    = name of program
-- path    = path of program
-- strat   = strategy
-- conf    = name of probe configuration
-- probe   = name of probe button
-- probno  = number of probe button
-- aA      = probe button angle A
-- aB      = probe button angle B

csv_format = "plan,strat,conf,probe,probno,aA,aB,path"
```

CSV divider
```lua
-- "\t" = tabulator
-- "x"  = any char/string enclosed in quotes

csv_div = "\t"

```

Output filenames
```lua
p_csv_f = "i:\\prac\\lua_snimace\\vypis.csv"
```
With **`DEBUG = 1`** it will export in human readable Format
```lua
p_cache = "i:\\prac\\lua_snimace\\vypis.txt"
```
## Usage/Examples
```lua
lua5.1.exe probe2csv.lua
```
