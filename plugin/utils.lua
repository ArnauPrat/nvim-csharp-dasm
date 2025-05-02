



----------------------------------------------------------
-----------------  System Utils --------------------------
----------------------------------------------------------

-- Gets the os name
local function get_os()
  local osname
  -- ask LuaJIT first
  if jit then
    return jit.os
  end

  -- Unix, Linux variants
  local fh, err = assert(io.popen("uname -o 2>/dev/null", "r"))
  if fh then
    osname = fh:read()
  end
  return osname or "Windows"
end

local function get_current_dir()
    local info = debug.getinfo(1)
    local script_path = info.source:sub(2)
    return script_path:match("(.*[\\|/])")
end

local function list_files(path)
  local os = get_os()
  local list = {}
  if os == 'Windows' then
    for dir in io.popen("dir " .. path .. " /B /S"):lines() do table.insert(list, dir) end
  else -- Linux
    for dir in io.popen("ls -pa " .. path .. "| grep -v /"):lines() do table.insert(list, dir) end
  end
  return list
end

----------------------------------------------------------
------------------  Print Utils --------------------------
----------------------------------------------------------

-- Converts a table to a string 
local function table_tostring(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. table_tostring(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end


----------------------------------------------------------
------------------ String Utils --------------------------
----------------------------------------------------------

-- Gets the last index of a character in a str. 
-- Returns -1 if the character is not found
local function last_index_of(str, char)
  for i = 1, #str do
    local reversed_idx = #str - i + 1
    local c = string.sub(str, reversed_idx, reversed_idx)
    if c == char then
      return reversed_idx 
    end
 end
 return -1
end


-- Trims the last element from a path, after the last path separator
local function path_parent(path)
  local path_separator = '/'
  if get_os() == "Windows" then
    path_separator = '\\'
  end
  local last = last_index_of(path, path_separator)
  if last ~= -1 then
    local found = false;
    return string.sub(current_file_path, 0, last - 1);
  end
  return nil 
end

local function ends_with(str, suffix)
  return str:sub(-#suffix) == suffix
end

local utils = 
{
  sys = {
    get_os = get_os,
    get_current_dir = get_current_dir,
  },
  table = {
    tostring = table_tostring, 
  },
  str = {
    ends_with = ends_with
  },
  path = {
    parent = path_parent,
    list_files = list_files,
  }
}

return utils 
