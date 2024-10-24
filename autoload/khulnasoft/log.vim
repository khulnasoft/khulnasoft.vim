if exists('g:loaded_khulnasoft_log')
  finish
endif
let g:loaded_khulnasoft_log = 1

if !exists('s:logfile')
  let s:logfile = expand(get(g:, 'khulnasoft_log_file', tempname() . '-khulnasoft.log'))
  try
    call writefile([], s:logfile)
  catch
  endtry
endif

function! khulnasoft#log#Logfile() abort
  return s:logfile
endfunction

function! khulnasoft#log#Log(level, msg) abort
  let min_level = toupper(get(g:, 'khulnasoft_log_level', 'WARN'))
  " echo "logging to: " . s:logfile . "," . min_level . "," . a:level . "," a:msg
  for level in ['ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE']
    if level == toupper(a:level)
      try
        if filewritable(s:logfile)
          call writefile(split(a:msg, "\n", 1), s:logfile, 'a')
        endif
      catch
      endtry
    endif
    if level == min_level
      break
    endif
  endfor
endfunction

function! khulnasoft#log#Error(msg) abort
  call khulnasoft#log#Log('ERROR', a:msg)
endfunction

function! khulnasoft#log#Warn(msg) abort
  call khulnasoft#log#Log('WARN', a:msg)
endfunction

function! khulnasoft#log#Info(msg) abort
  call khulnasoft#log#Log('INFO', a:msg)
endfunction

function! khulnasoft#log#Debug(msg) abort
  call khulnasoft#log#Log('DEBUG', a:msg)
endfunction

function! khulnasoft#log#Trace(msg) abort
  call khulnasoft#log#Log('TRACE', a:msg)
endfunction

function! khulnasoft#log#Exception() abort
  if !empty(v:exception)
    call khulnasoft#log#Error('Exception: ' . v:exception . ' [' . v:throwpoint . ']')
  endif
endfunction
