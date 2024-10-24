if exists('g:loaded_khulnasoft')
  finish
endif
let g:loaded_khulnasoft = 1

command! -nargs=? -complete=customlist,khulnasoft#command#Complete Khulnasoft exe khulnasoft#command#Command(<q-args>)

if !khulnasoft#util#HasSupportedVersion()
    finish
endif

function! s:SetStyle() abort
  if &t_Co == 256
    hi def KhulnasoftSuggestion guifg=#808080 ctermfg=244
  else
    hi def KhulnasoftSuggestion guifg=#808080 ctermfg=8
  endif
  hi def link KhulnasoftAnnotation Normal
endfunction

function! s:MapTab() abort
  if !get(g:, 'khulnasoft_no_map_tab', v:false) && !get(g:, 'khulnasoft_disable_bindings')
    imap <script><silent><nowait><expr> <Tab> khulnasoft#Accept()
  endif
endfunction

augroup khulnasoft
  autocmd!
  autocmd InsertEnter,CursorMovedI,CompleteChanged * call khulnasoft#DebouncedComplete()
  autocmd BufEnter     * if khulnasoft#Enabled()|call khulnasoft#command#StartLanguageServer()|endif
  autocmd BufEnter     * if mode() =~# '^[iR]'|call khulnasoft#DebouncedComplete()|endif
  autocmd InsertLeave  * call khulnasoft#Clear()
  autocmd BufLeave     * if mode() =~# '^[iR]'|call khulnasoft#Clear()|endif

  autocmd ColorScheme,VimEnter * call s:SetStyle()
  " Map tab using vim enter so it occurs after all other sourcing.
  autocmd VimEnter             * call s:MapTab()
  autocmd VimLeave             * call khulnasoft#ServerLeave()
augroup END


imap <Plug>(khulnasoft-dismiss)     <Cmd>call khulnasoft#Clear()<CR>
imap <Plug>(khulnasoft-next)     <Cmd>call khulnasoft#CycleCompletions(1)<CR>
imap <Plug>(khulnasoft-next-or-complete)     <Cmd>call khulnasoft#CycleOrComplete()<CR>
imap <Plug>(khulnasoft-previous) <Cmd>call khulnasoft#CycleCompletions(-1)<CR>
imap <Plug>(khulnasoft-complete)  <Cmd>call khulnasoft#Complete()<CR>

if !get(g:, 'khulnasoft_disable_bindings')
  if empty(mapcheck('<C-]>', 'i'))
    imap <silent><script><nowait><expr> <C-]> khulnasoft#Clear() . "\<C-]>"
  endif
  if empty(mapcheck('<M-]>', 'i'))
    imap <M-]> <Plug>(khulnasoft-next-or-complete)
  endif
  if empty(mapcheck('<M-[>', 'i'))
    imap <M-[> <Plug>(khulnasoft-previous)
  endif
  if empty(mapcheck('<M-Bslash>', 'i'))
    imap <M-Bslash> <Plug>(khulnasoft-complete)
  endif
  if empty(mapcheck('<C-k>', 'i'))
    imap <script><silent><nowait><expr> <C-k> khulnasoft#AcceptNextWord()
  endif
  if empty(mapcheck('<C-l>', 'i'))
    imap <script><silent><nowait><expr> <C-l> khulnasoft#AcceptNextLine()
  endif
endif

call s:SetStyle()

let s:dir = expand('<sfile>:h:h')
if getftime(s:dir . '/doc/khulnasoft.txt') > getftime(s:dir . '/doc/tags')
  silent! execute 'helptags' fnameescape(s:dir . '/doc')
endif

function! KhulnasoftEnable()  " Enable Khulnasoft if it is disabled
  let g:khulnasoft_enabled = v:true
  call khulnasoft#command#StartLanguageServer()
endfun

command! KhulnasoftEnable :silent! call KhulnasoftEnable()

function! KhulnasoftDisable() " Disable Khulnasoft altogether
  let g:khulnasoft_enabled = v:false
endfun

command! KhulnasoftDisable :silent! call KhulnasoftDisable()

function! KhulnasoftToggle()
  if exists('g:khulnasoft_enabled') && g:khulnasoft_enabled == v:false
      call KhulnasoftEnable()
  else
      call KhulnasoftDisable()
  endif
endfunction

command! KhulnasoftToggle :silent! call KhulnasoftToggle()

function! KhulnasoftManual() " Disable the automatic triggering of completions
  let g:khulnasoft_manual = v:true
endfun

command! KhulnasoftManual :silent! call KhulnasoftManual()

function! KhulnasoftAuto()  " Enable the automatic triggering of completions
  let g:khulnasoft_manual = v:false
endfun

command! KhulnasoftAuto :silent! call KhulnasoftAuto()

function! KhulnasoftChat()
  call khulnasoft#Chat()
endfun

command! KhulnasoftChat :silent! call KhulnasoftChat()

:amenu Plugin.Khulnasoft.Enable\ \Khulnasoft\ \(\:KhulnasoftEnable\) :call KhulnasoftEnable() <Esc>
:amenu Plugin.Khulnasoft.Disable\ \Khulnasoft\ \(\:KhulnasoftDisable\) :call KhulnasoftDisable() <Esc>
:amenu Plugin.Khulnasoft.Manual\ \Khulnasoft\ \AI\ \Autocompletion\ \(\:KhulnasoftManual\) :call KhulnasoftManual() <Esc>
:amenu Plugin.Khulnasoft.Automatic\ \Khulnasoft\ \AI\ \Completion\ \(\:KhulnasoftAuto\) :call KhulnasoftAuto() <Esc>
:amenu Plugin.Khulnasoft.Toggle\ \Khulnasoft\ \(\:KhulnasoftToggle\) :call KhulnasoftToggle() <Esc>
:amenu Plugin.Khulnasoft.Chat\ \Khulnasoft\ \(\:KhulnasoftChat\) :call KhulnasoftChat() <Esc>
