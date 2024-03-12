
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
p_csv_f = "c:\\Users\\Public\\Documents\\Zeiss\\probes.csv"
```
With **`DEBUG = 1`** it will export in human readable Format
```lua
p_cache = "c:\\Users\\Public\\Documents\\Zeiss\\probes.txt"
```
## Usage/Examples
```lua
lua5.1.exe probe2csv.lua
```

## Examples of export
`CSV`
```txt
13580i00_vyk	***	Konfig_51	vpredu_Y-#0#0	4	0	0	c:\Users\Public\Documents\Zeiss\CALYPSO 6.6\workarea\inspections\13580i00_vyk
13580i00_vyk	***	Konfig_51	vzadu#0#0	2	0	0	c:\Users\Public\Documents\Zeiss\CALYPSO 6.6\workarea\inspections\13580i00_vyk
13580i00_vyk	***	Konfig_3	dolu#0#0	1	0	0	c:\Users\Public\Documents\Zeiss\CALYPSO 6.6\workarea\inspections\13580i00_vyk
13580i00_vyk	***	konfig 51 long	vzadu#0#0	2	0	0	c:\Users\Public\Documents\Zeiss\CALYPSO 6.6\workarea\inspections\13580i00_vyk
13580i00_vyk	***	konfig 51 long	dolu#0#0	1	0	0	c:\Users\Public\Documents\Zeiss\CALYPSO 6.6\workarea\inspections\13580i00_vyk
```
`DEBUG = 1`
```txt
Probe configs in program: 13580i00_vyk
Path of program: c:\Users\Public\Documents\Zeiss\CALYPSO 6.6\workarea\inspections\13580i00_vyk
Version: 6.6.1200
Base config for program: konfig 51 long
Configs for strategy: ***
 Config: Konfig_51
   vpredu_Y-#0#0   ID: 4   Angle A: 0   Angle B: 0
   vzadu#0#0   ID: 2   Angle A: 0   Angle B: 0
 Config: Konfig_3
   dolu#0#0   ID: 1   Angle A: 0   Angle B: 0
 Config: konfig 51 long
   vzadu#0#0   ID: 2   Angle A: 0   Angle B: 0
   dolu#0#0   ID: 1   Angle A: 0   Angle B: 0
-----------------------------------------
```
