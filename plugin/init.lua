-- Author: Arnau Prat <arnau.prat@gmail.com>
-- 
-- Nvim plugin to show the disassembly of a csharp symbol. The plugin relies on 
-- a LSP server supporting csharp with the documentSymbol capabilities. To retrieve
-- the symbol name under cursor. 
-- It will then rely on `dotnet msbuild` to obtain the path to the assembly where that 
-- symbol is contained into, and use ildasm.exe to dump the il and extract then
-- corresponding part
-- 
-- 
--
-- Commands


----------------------------------------------------------
-----------------------------------------------------------
----------------------------------------------------------

-- add current dir to package.path
local function get_current_dir()
    local info = debug.getinfo(1)
    local script_path = info.source:sub(2)
    return script_path:match("(.*[\\|/])")
end

local current_dir = get_current_dir() 
print(current_dir)
package.path = current_dir .. "?.lua;" .. package.path

local utils = require('utils')

-- Prints a log message
local log = function(msg)
  print('INFO csharp-dasm: ' .. msg)
end


-- Finds the symbol wihtin a range
local function find_symbol(symbol, row, column) 
  if symbol['children'] ~= nil then
    for _, child in ipairs(symbol['children']) do 
      symbol_name = find_symbol(child, row, column)
      if symbol_name ~= nil
        then
          return symbol_name
        end
      end
   end

  local range = symbol.range
  local range_start = range['start'].line
  local range_end = range['end'].line

  if row - 1 >=  range_start and row - 1 <= range_end then
    return symbol.name
  end

  return nil
end

-- Finds csproj or sln file from current file 
local function find_csproj() 
  current_file_path = vim.api.nvim_buf_get_name(0)
  local path = utils.path.parent(current_file_path)
  while path ~= nil do 
    local files = utils.path.list_files(path)
    for _, file in ipairs(files) do
      if utils.str.ends_with(file, ".csproj") or utils.str.ends_with(file, ".sln") then  
        return file 
      end
    end
    path = utils.path.parent(path)
  end
  return nil
end


-- builds artifact
local function dotnet_build(csproj)
  io.popen('dotnet msbuild /p:Configuration=Release' .. csproj)
end

local function dotnet_property(csproj,property)
  local csproj_folder = utils.path.parent(csproj)
  local file = io.popen('dotnet msbuild /p:Configuration=Release -getProperty:' .. property .. " " .. csproj)
  local lines = file:lines()
  for property in lines do
    return property 
  end
end

local function dotnet_binary_path(csproj)
  local csproj_folder = utils.path.parent(csproj)
  local output_path = dotnet_property(csproj, 'OutputPath')
  return csproj_folder .. "\\" .. output_path 
end

local function dotnet_assembly(csproj)
  return dotnet_property(csproj,'AssemblyName')
end


----------------------------------------------------------
-----------------------------------------------------------
----------------------------------------------------------
-- csharp-dasm nvim command handler
local exec_command = function(data)
  local params = { textDocument = vim.lsp.util.make_text_document_params() }
  local result = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params)

  if result then
    for _, server_response in pairs(result) do
      if server_response.result then
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        for _, symbol in ipairs(server_response.result) do
          symbol_name = find_symbol(symbol, row, col)
          if symbol_name ~= nil
            then
              local csproj_file = find_csproj()
              log(csproj_file)
              log(symbol_name)
              dotnet_build(csproj_file)
              local binary_path = dotnet_binary_path(csproj_file)
              local assembly_name = dotnet_assembly(csproj_file)
              local output_type = dotnet_property(csproj_file, 'OutputType') 
              local assembly_extension = nil
              if output_type == 'Exe' or output_type == 'WinExe' then
                assembly_extension = 'exe'
              elseif output_type == 'Library' then
                assembly_extension = 'dll'
              else
                error("Unknown OutputType " .. output_type)
              end
              local assembly = binary_path .. assembly_name .. '.' .. assembly_extension
              print(assembly)
            end
        end
      end
    end
  end
end


-----------------------------------------------------------
-----------------------------------------------------------
-----------------------------------------------------------
-- Script Start Here

-- Global object
csharpdasm = {
  command     = exec_command,
}

-- Registering commands
vim.api.nvim_create_user_command('CSharpDasm', csharpdasm.command, { nargs = '*' })
