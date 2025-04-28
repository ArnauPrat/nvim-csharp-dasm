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
-- Helper Methods 

-- Prints a log message
local log = function(msg)
  print('INFO gotoerror: ' .. msg)
end


----------------------------------------------------------
-----------------------------------------------------------
----------------------------------------------------------
-- csharp-dasm nvim command handler
local exec_command = function(data)
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
