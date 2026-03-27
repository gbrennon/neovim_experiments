#!/usr/bin/env lua
-- Coverage report generator for Lua tests
-- Generates a table-like coverage report

local function exec(cmd)
  local handle = io.popen(cmd)
  local result = handle:read("*all")
  handle:close()
  return result
end

local function get_lua_files(dir)
  local output = exec("find " .. dir .. " -name '*.lua' -type f 2>/dev/null | sort")
  local files = {}
  for line in output:gmatch("[^\n]+") do
    if line ~= "" then
      table.insert(files, line)
    end
  end
  return files
end

local function count_lines(filepath)
  local f = io.open(filepath, "r")
  if not f then return 0 end
  local count = 0
  for _ in f:lines() do count = count + 1 end
  f:close()
  return count
end

local function parse_tests_for_modules()
  local modules = {}
  local spec_dir = "spec"

  -- Find all spec files
  local spec_files = get_lua_files(spec_dir)
  
  for _, spec_file in ipairs(spec_files) do
    local f = io.open(spec_file, "r")
    if f then
      local content = f:read("*all")
      f:close()
      
      -- Extract require statements
      for module in content:gmatch('require[%s%(%["]+([^"%)%]]+)') do
        -- Skip helpers and spec_helper
        if not module:match("^helpers%.") and module ~= "spec_helper" then
          modules[module] = true
        end
      end
    end
  end
  
  return modules
end

local function generate_report()
  local modules = parse_tests_for_modules()
  local lua_dir = "lua"
  
  local all_files = get_lua_files(lua_dir)
  local total_lines = 0
  local tested_lines = 0
  
  local results = {}
  
  for _, filepath in ipairs(all_files) do
    local rel_path = filepath:gsub("^" .. lua_dir .. "/", "")
    local module_name = rel_path:gsub("%.lua$", ""):gsub("/", ".")
    local lines = count_lines(filepath)
    total_lines = total_lines + lines
    
    local is_tested = modules[module_name] or modules[module_name:gsub("^plugins%.", "")]
    local status = is_tested and "TESTED" or "NOT TESTED"
    local coverage = is_tested and 100 or 0
    
    tested_lines = tested_lines + (is_tested and lines or 0)
    
    table.insert(results, {
      file = rel_path,
      module = module_name,
      lines = lines,
      coverage = coverage,
      status = status
    })
  end
  
  -- Sort by coverage descending
  table.sort(results, function(a, b)
    if a.status ~= b.status then return a.status < b.status end
    return a.file < b.file
  end)
  
  -- Print table
  print("\n" .. string.rep("=", 80))
  print(string.format("%-45s | %8s | %6s | %s", "File", "Lines", "Cover", "Status"))
  print(string.rep("-", 80))
  
  local tested_files = 0
  local untested_files = 0
  
  for _, r in ipairs(results) do
    print(string.format("%-45s | %8d | %5d%% | %s", 
      r.file, r.lines, r.coverage, r.status))
    if r.status == "TESTED" then
      tested_files = tested_files + 1
    else
      untested_files = untested_files + 1
    end
  end
  
  print(string.rep("-", 80))
  
  local total_files = #results
  local overall_coverage = total_lines > 0 and math.floor((tested_lines / total_lines) * 100) or 0
  
  print(string.format("%-45s | %8d | %5d%% | %d/%d files tested", 
    "TOTAL", total_lines, overall_coverage, tested_files, total_files))
  print(string.rep("=", 80))
  
  if untested_files > 0 then
    print("\n⚠ " .. untested_files .. " untested modules:")
    for _, r in ipairs(results) do
      if r.status == "NOT TESTED" then
        print("  - " .. r.module)
      end
    end
  end
end

generate_report()