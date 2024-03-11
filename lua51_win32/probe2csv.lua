--------------------------------------------------------------------------------------------
-- probe2csv.lua - Export probes data from programs
--
-- Author:
--   Jansky Martin [justyand@gmail.com]
--
-- Logs:
-- 24.01.2024 v01a - start of project
-- 11.03.2024 v01f - first git upload
--
-- Logic explained --
  -- --------------- --
  -- 1. Find inspection plan name by #OMInspection followed by #identitifer
  -- 2. Find #OMMGeometry - ended by #defaultTechnology - this is our measured feature
  -- 3. Find within Step#2 #technology -> ('***') ended by #viewAccord .. )) 
  -- 4. Find within Step#2 #probeConfiguration - not ommited when Default config for plan is used ( inside "inspset" file)
  -- 5. Find #probeName, #probe - basic info
  --         #angleA, #angleB - for swivel heads - possibly need rounding of decimal number
-- --------------- --
-- array structure --
      -- insp_files -> [inspection_name "13500_vyk"]
      --  |-> [version "version"] -> "6.6.08"
      --  |-> [inspection path "path"] -> "c:\Users\Public\Documents\Zeiss\Calypso( X.X )\workarea\inspections\..."
      --  |-> [default probe config "def_config"] -> probe config "Konfig 3"
      --  |-> [strategy "strategy"]
      --   |-> [strategy name "***"]
      --    |-> [probe config "Konfig 3"]
      --     |-> [probe button name "1 dolu"] -> probe no. "1"
-- --------------- --
--------------------------------------------------------------------------------------------
-- LUA requirements
--------------------------------------------------------------------------------------------
-- IUPLUA - https://sourceforge.net/projects/iup/files/
require("iuplua")                                                               
-- LFS    - must be compiled from source https://lunarmodules.github.io/luafilesystem/index.html#download
--          or find compiled lfs.dll for your LUA version
require("lfs")                                                                  
-- Open files as ANSI
iup.SetGlobal("UTF8MODE", "No")
require("probe2csv_settings")
--------------------------------------------------------------------------------------------
-- Configuration help
--------------------------------------------------------------------------------------------
-- Search path --
  -- real path
    --p_path = "c:\\Users\\Public\\Documents\\Zeiss\\CALYPSO 6.6\\workarea\\inspections"
  -- current working dir ( from Windows shortcut - "Start in" )
    --p_path = lfs.currentdir() --

------------------------------------------------------
-- Format of CSV
--
-- plan    = name of program
-- path    = path of program
-- strat   = strategy
-- conf    = name of probe configuration
-- probe   = name of probe button
-- probno  = number of probe button
-- aA      = probe button angle A
-- aB      = probe button angle B
------------------------------------------------------
-- CSV divider
--
-- "\t" = tabulator
-- "x"  = any char enclosed in quotes
------------------------------------------------------
-- DEBUG option
  -- 0 = DEBUG OFF - no PRINT on DOS window
  -- 1 = PRINT human readable data
  -- 3 = detailed report used for debuging
------------------------------------------------------
-- Array data
  insp_files = {}
  
-- NOT_DEFINED text
  ndef = "NOT_DEFINED"
  
-- Temps
  version    = ndef
  def_config = ndef
  plan_name  = ndef
  act_path   = ndef
--------------------------------------------------------------------------------------------
-- FUNCS
--------------------------------------------------------------------------------------------
function resetTemps(dir)
  version    = ndef
  def_config = ndef
  plan_name  = ndef
  act_path   = dir
end

-- VERSION file --
function processVersion(ver, dir)
  
  if DEBUG == 3 then 
    print("Processing VERSION file", ver)
  end
  
  local _version = ""
  f_ver = io.open(ver, "r")
  
  if not f_ver then
    version = ndef
    
    if DEBUG == 3 then
      print("NOT found VERSION! Using:", version)
    end
    
    return
  end
  for line in io.lines(ver) do
    _version = line
    break
  end
  f_ver:close()

  if DEBUG == 3 then
    print("Saving VERSION:", _version)
  end
  
  version = _version
end

-- INSPSET file --
function processInspset(insp, dir)

  if DEBUG == 3 then 
    print("Processing INSPSET file", insp)
  end
  
  local _def_config = ""
  f_inspset = io.open(insp, "r")
  
  if not f_inspset then
    def_config = ndef
    
    if DEBUG == 3 then
      print("NOT found INSPSET! Using:", def_config)
    end
    
    return
  end
  for line in io.lines(insp) do
    _def_config = string.match(line, "#probeConfiguration ' %->' '(.*)'%)")
    if _def_config ~= nil then break end
  end
  f_inspset:close()
  
  if _def_config == nil then
    _def_config = ndef
    
    if DEBUG == 3 then
      print("NOT found default config! Using:", _def_config)
    end
    
  end
    
  def_config = _def_config
  
  if DEBUG == 3 then
    print("Saving DEFAULT CONFIG:", def_config)
  end
end
  
-- INSPECTION file --
function processInspection(insp, dir)

  if DEBUG == 3 then 
    print("Processing INSPECTION file", insp)
  end

  f_insp = io.open(insp, "r")
  
  line_no    = -1      -- line number
  line_stp1  = -1      -- line number Step1
  line_tec   = -1      -- line number technology
  status_geo = 0       -- status of OMMGeometry ( 1- started, 0- ended)
  status_tec = 0       -- status of technology  ( 1- started, 0- ended)
  status_tec_mini = -1 -- status of mini-technology  ( 1- started, 0- ended) 
  
  inspection_name = 0
  insp_name = ""
  tech_name = ndef
  pc_name   = ""
  btn_id    = ""
  
  line_prev  = "" -- previous line ( 1st line )
  line_prev2 = "" -- previous line ( 2nd line )
  
  
  for line in io.lines(insp) do
    line_no = line_no+1 -- line numbering
    --v-- search for inspection identifier aka program name --v--
    -- Step #1
    if string.match(line, "#identifier" )
    and string.match(line_prev, "#OMInspection" ) then
      insp_name = string.match(line, "#identifier: '(.*)'")
      
      -- searching for INSPECTION NAME duplicate
      -- ( adding "#X"number into it's name )
      if insp_files[insp_name] ~= nil then
        local insp_ver = 0
        local done = false
        repeat
          insp_ver = insp_ver + 1
          if insp_files[insp_name.."#"..insp_ver] == nil then
            insp_name = insp_name.."#"..insp_ver
            break
          end
        until insp_ver == 99
      end 
      plan_name = insp_name
      
      insp_files[insp_name] = {["version"] = version, ["def_config"] = def_config, ["path"] = act_path }
           
    end
    
    --v-- search for measured features --v--
    -- Step #2
    if string.match(line, "#OMMGeometry") ~= nil and status_geo == 0 then
      status_geo = 1
      if DEBUG == 3 then print("Found GEO:",line_no) end      
    end
    if string.match(line_prev2, "#technology:")
    and string.match(line,"#Dictionary") == nil then
      status_geo = 0 status_tec = 0 end
    -- Step #2 - find #technology
    
    if string.match(line_prev2, "#technology:")
    and string.match(line,"#Dictionary")
    and status_geo == 1 then status_tec = 1 end
    
    if string.match(line,"#%('(.*)' ' %->'") and status_tec == 1 then
      omm_name = string.match(line,"#%('(.*)' ' %->'")
      status_tec_mini = 0
      
      tech_name = omm_name
      
      local temp_insp = {}
      local temp_tec  = {}
      
      temp_insp = insp_files[insp_name]                                         -- get already saved plan_name
      if temp_insp["strategy"] ~= nil then
        temp_tec = temp_insp["strategy"] end                                    -- load strategies
      if temp_tec[tech_name] == nil then temp_tec[tech_name] = {} end      

      temp_insp["strategy"] = temp_tec
      insp_files[insp_name] = temp_insp      
      
      if DEBUG == 3 then print("Found technology:",tech_name, line_no) end
    end
        
    --v-- search for probe configuration --v--
    if string.match(line, "#probeConfiguration")
    and status_tec == 1 and status_tec_mini == 0 then
      pc_name = string.match(line, "#probeConfiguration ' %->' '(.*)'%)")
      
      if DEBUG == 3 then print(pc_name,line) end
      
      local temp_insp  = {}
      local temp_tec   = {}
      local temp_confs = {}
      local temp_conf  = {}
      
      temp_insp = insp_files[insp_name]                                         -- get already saved plan_name
      if temp_insp["strategy"] ~= nil then
        temp_tec   = temp_insp["strategy"] end                                  -- load strategies
      if temp_tec[tech_name]   ~= nil then
        temp_confs = temp_tec[tech_name]   end                                  -- load configurations
      if temp_confs[pc_name]   ~= nil then
        temp_conf  = temp_confs[pc_name]   end                                  -- load configuration
      
      temp_confs[pc_name]   = temp_conf
      temp_tec[tech_name]   = temp_confs
      temp_insp["strategy"] = temp_tec
      insp_files[insp_name] = temp_insp
      
      if DEBUG == 3 then print("Found probeConfiguration:",pc_name, line_no) end
    end
    
    --v-- search for probe buttons --v--
    if string.match(line, "#probeName") and status_tec_mini == 0 then
      btn_name = string.match(line, "#probeName: '(.*)'")
      btn_id = nil      
      
      if DEBUG == 3 then print("Found #probeName:",btn_name, line_no) end
    end
    --v-- search if probe button have an ID --v--
    
    if string.match(line, "#probe:") and status_tec_mini == 0 then
      btn_id = string.match(line, "#probe: (.*) ")
      
      if btn_id  == nil then
        if DEBUG == 3 then print("Found BAD #probe:","", line_no) end
        btn_name = ""
        pc_name = ""
        return
      end
      if pc_name == nil then
        if DEBUG == 3 then print("Found BAD #probe:",pc_name, line_no) end
        btn_name = ""
        pc_name = ""
        return
      end
      
      if DEBUG == 3 then print("Found #probe:",btn_id, line_no) end
    end
    --v-- search for probe angles --v--
    if ( string.match(line_prev, "#angleA") and string.match(line, "#angleB") )
    and status_tec_mini == 0 then
      _angleA = string.match(line_prev, "#angleA: ([%d+%-.]*)")
      
      if _angleA ~= nil then angleA = string.format("%.3f", _angleA ) end
      _angleB = string.match(line, "#angleB: ([%d+%-.]*)")
      if _angleB ~= nil then angleB = string.format("%.3f", _angleB ) end
      
      local temp_insp  = {}
      local temp_tec   = {}
      local temp_confs = {}
      local temp_conf  = {}

      if pc_name == ndef or pc_name == nil or pc_name == "" then
        pc_name = def_config end
      
      temp_insp = insp_files[insp_name]                                         -- get already saved plan_name
      if temp_insp["strategy"] ~= nil then
        temp_tec   = temp_insp["strategy"] end                                  -- load strategies
      if temp_tec[tech_name]   ~= nil then
        temp_confs = temp_tec[tech_name]   end                                  -- load configurations
      if temp_confs[pc_name]   ~= nil then
        temp_conf  = temp_confs[pc_name]   end                                  -- load configuration
  
      if angleA ~= nil and angleA % 1 == 0 then
        angleA = string.format("%.0f", angleA) end
      if angleB ~= nil and angleB % 1 == 0 then
        angleB = string.format("%.0f", angleB) end
            
      if angleB ~= nil then     
        btn_name = btn_name.."#"..angleA.."#"..angleB
                    
        temp_conf[btn_name]   = {["id"] = btn_id, ["angleA"] = angleA, ["angleB"] = angleB }
        temp_confs[pc_name]   = temp_conf
        temp_tec[tech_name]   = temp_confs
        temp_insp["strategy"] = temp_tec
        insp_files[insp_name] = temp_insp
        
        if DEBUG == 3 then print("Found probe angles:",btn_name, line_no) end
      
        btn_name = ""
        pc_name = ""
        
        angleA = nil
        angleB = nil
      end
           
    end
    --v-- search for ending of GEO --v--
    local omm_geo = string.match(line,"#defaultTechnology: '(.*)'%)")
    if omm_geo ~= nil and status_geo == 1 and status_tec == 1 and status_tec_mini == 0 then
      status_geo = 0
      status_tec = 0
      status_tec_mini = -1
      if DEBUG == 3 then 
        print("Found defaultTechnology:",omm_geo)
        print("Found end of GEO:",tech_name, line_no)
      end
    end
    -- saving previous lines
    line_prev2 = line_prev
    line_prev = line
  end
  f_insp:close()
end

function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

-- printout into CSV ( optional DEBUG - printout human-readable data )
function reportPlan()
  -- report INSPECTION named from "insp_name"
  if DEBUG > 0 then cache = io.open(p_cache, "a+") end
  csv_f = io.open(p_csv_f, "a+")
  if insp_files ~= nil and insp_name ~= nil and insp_name ~= ndef then
    if DEBUG > 0 then cache:write("Probe configs in program: "..insp_name.."\n") end
    if DEBUG > 0 then print("Probe configs in program: ",insp_name) end
    --
    local inspection = insp_files[insp_name]
    if DEBUG > 0 then cache:write("Path of program: "..inspection["path"].."\n") end
    if DEBUG > 0 then print("Path of program:", inspection["path"]) end
    --
    if DEBUG > 0 then cache:write("Version: "..inspection["version"].."\n") end
    if DEBUG > 0 then print("Version:", inspection["version"]) end
    --
    if DEBUG > 0 then cache:write("Base config for program: "..inspection["def_config"].."\n") end
    if DEBUG > 0 then print("Base config for program:", inspection["def_config"]) end
    --
    if inspection["strategy"] == nil then
      if DEBUG > 0 then cache:write("--  No features defined in program --\n") end
      if DEBUG > 0 then print("No features defined in program") end
      if DEBUG > 0 then cache:write("-----------------------------------------\n") end
      if DEBUG > 0 then print("------------------------------") end
      return
    end
    for strategy_name, probes in pairs(inspection["strategy"]) do
      if DEBUG > 0 then cache:write("Configs for strategy: "..strategy_name.."\n") end
      if DEBUG > 0 then print("Configs for strategy:", strategy_name) end
      for m, proben in pairs(probes) do
        if DEBUG > 0 then cache:write(" Config: "..m.."\n") end
        if DEBUG > 0 then print("Config:",m) end
        for n, name in pairs(proben) do
          if DEBUG > 0 then cache:write("   "..n.."   ID: "..name["id"].."   Angle A: "..name["angleA"].."   Angle B: "..name["angleB"].."\n") end
          if DEBUG > 0 then print("",n,"ID:",name["id"],"Angle A:", name["angleA"], "Angle B:", name["angleB"]) end
          -- csv export
          csvTable = csv_format:split(",")
          for w = 1, #csvTable do
            if w > 1 then
              csv_f:write(csv_div)
            end
            if csvTable[w] == "plan" then
              csv_f:write(insp_name)
            end
            if csvTable[w] == "strat" then
              csv_f:write(strategy_name)
            end
            if csvTable[w] == "conf" then
              if m == ndef then
                csv_f:write(inspection["def_config"])
              else
                csv_f:write(m)
              end
            end
            if csvTable[w] == "probe" then
              csv_f:write(n)
            end
            if csvTable[w] == "probno" then
              csv_f:write(name["id"])
            end
            if csvTable[w] == "aA" then
              csv_f:write(name["angleA"])
            end
            if csvTable[w] == "aB" then
              csv_f:write(name["angleB"])
            end
            if csvTable[w] == "path" then
              csv_f:write(inspection["path"])
            end
          end
          csv_f:write("\n")
        end
      end
    end
    if DEBUG > 0 then cache:write("-----------------------------------------\n") end
    if DEBUG > 0 then print("------------------------------") end
  end
  if DEBUG > 0 then cache:close() end
  csv_f:close()
end

-- stored paths to be analyzed
table_paths = {}

-- scan directory recursively to obtain all inspections
function _scandir(dir, root)
  -- check root directory for "inspection" file
  if root then
    local ff = io.open(dir.."\\inspection", "r")
    if not ff then else
      table.insert(table_paths,dir)
      ff:close()
    end
  end
  -- check directory tree
  for file in lfs.dir(dir) do
    if lfs.attributes(file,"mode")== "directory" then
      if file ~= ".." then do 
        for l in lfs.dir(dir.."\\"..file) do
          n_path = dir.."\\"..l
          if lfs.attributes(n_path, "mode") == "directory" and l ~= "." and l ~= ".." then
            -- test if directory contains "inspection" file
            local ff = io.open(n_path.."\\inspection", "r")
            if not ff then else
              -- "inspection" file exists here -> store this path
              table.insert(table_paths,n_path)
              ff:close()
            end
          end
          if not((l == ".") or (l == "..") or (lfs.attributes(n_path, "mode") == "file")) then
              _scandir(n_path, false)
end end end end end end end

--------------------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------------------


-- find directories
_scandir(p_path, true)

-- process found directories
for _,path in ipairs(table_paths) do
  resetTemps(path)
  
  processVersion(path.."\\version", path)
  processInspset(path.."\\inspset", path)
  processInspection(path.."\\inspection", path)
  
  reportPlan()
end

if DEBUG > 0 then print("End of SCAN ...") end