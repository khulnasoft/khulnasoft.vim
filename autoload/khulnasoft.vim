let s:hlgroup = 'KhulnasoftSuggestion'
let s:request_nonce = 0
let s:using_khulnasoft_status = 0

if !has('nvim')
  if empty(prop_type_get(s:hlgroup))
    call prop_type_add(s:hlgroup, {'highlight': s:hlgroup})
  endif
endif

let s:default_khulnasoft_enabled = {
      \ 'help': 0,
      \ 'gitcommit': 0,
      \ 'gitrebase': 0,
      \ '.': 0}

function! khulnasoft#Enabled() abort
  if !get(g:, 'khulnasoft_enabled', v:true) || !get(b:, 'khulnasoft_enabled', v:true)
    return v:false
  endif

  let khulnasoft_filetypes = s:default_khulnasoft_enabled
  call extend(khulnasoft_filetypes, get(g:, 'khulnasoft_filetypes', {}))

  let khulnasoft_filetypes_disabled_by_default = get(g:, 'khulnasoft_filetypes_disabled_by_default') || get(b:, 'khulnasoft_filetypes_disabled_by_default')

  if !get(khulnasoft_filetypes, &filetype, !khulnasoft_filetypes_disabled_by_default)
    return v:false
  endif

  return v:true
endfunction

function! khulnasoft#CompletionText() abort
  try
    return remove(s:, 'completion_text')
  catch
    return ''
  endtry
endfunction

function! s:CompletionInserter(current_completion, insert_text) abort
  let default = get(g:, 'khulnasoft_tab_fallback', pumvisible() ? "\<C-N>" : "\t")

  if mode() !~# '^[iR]' || !exists('b:_khulnasoft_completions')
    return default
  endif

  let current_completion = a:current_completion
  if current_completion is v:null
    return default
  endif

  let range = current_completion.range
  let suffix = get(current_completion, 'suffix', {})
  let suffix_text = get(suffix, 'text', '')
  let delta = get(suffix, 'deltaCursorOffset', 0)
  let start_offset = get(range, 'startOffset', 0)
  let end_offset = get(range, 'endOffset', 0)

  let text = a:insert_text . suffix_text
  if empty(text)
    return default
  endif

  let delete_range = ''
  if end_offset - start_offset > 0
    let delete_bytes = end_offset - start_offset
    let delete_chars = strchars(strpart(getline('.'), 0, delete_bytes))
    " We insert a space, escape to normal mode, then delete the inserted space.
    " This lets us "accept" any auto-inserted indentation which is otherwise
    " removed when we switch to normal mode.
    " \"_ sequence makes sure to delete to the void register.
    " This way our current yank is not overridden.
    let delete_range = " \<Esc>\"_x0\"_d" . delete_chars . 'li'
  endif

  let insert_text = "\<C-R>\<C-O>=khulnasoft#CompletionText()\<CR>"
  let s:completion_text = text

  if delta == 0
    let cursor_text = ''
  else
    let cursor_text = "\<C-O>:exe 'go' line2byte(line('.'))+col('.')+(" . delta . ")\<CR>"
  endif
  call khulnasoft#server#Request('AcceptCompletion', {'metadata': khulnasoft#server#RequestMetadata(), 'completion_id': current_completion.completion.completionId})
  return delete_range . insert_text . cursor_text
endfunction

function! khulnasoft#Accept() abort
  let current_completion = s:GetCurrentCompletionItem()
  return s:CompletionInserter(current_completion, current_completion is v:null ? '' : current_completion.completion.text)
endfunction

function! khulnasoft#AcceptNextWord() abort
  let current_completion = s:GetCurrentCompletionItem()
  let completion_parts = current_completion is v:null ? [] : get(current_completion, 'completionParts', [])
  if len(completion_parts) == 0
    return ''
  endif
  let prefix_text = get(completion_parts[0], 'prefix', '')
  let completion_text = get(completion_parts[0], 'text', '')
  let next_word = matchstr(completion_text, '\v^\W*\k*')
  return s:CompletionInserter(current_completion, prefix_text . next_word)
endfunction

function! khulnasoft#AcceptNextLine() abort
  let current_completion = s:GetCurrentCompletionItem()
  let text = current_completion is v:null ? '' : substitute(current_completion.completion.text, '\v\n.*$', '', '')
  return s:CompletionInserter(current_completion, text)
endfunction

function! s:HandleCompletionsResult(out, err, status) abort
  if exists('b:_khulnasoft_completions')
    let response_text = join(a:out, '')
    try
      let response = json_decode(response_text)
      if get(response, 'code', v:null) isnot# v:null
        call khulnasoft#log#Error('Invalid response from language server')
        call khulnasoft#log#Error(response_text)
        call khulnasoft#log#Error('stderr: ' . join(a:err, ''))
        call khulnasoft#log#Exception()
        return
      endif
      let completionItems = get(response, 'completionItems', [])

      let b:_khulnasoft_completions.items = completionItems
      let b:_khulnasoft_completions.index = 0

      let b:_khulnasoft_status = 2
      call s:RenderCurrentCompletion()
    catch
      call khulnasoft#log#Error('Invalid response from language server')
      call khulnasoft#log#Error(response_text)
      call khulnasoft#log#Error('stderr: ' . join(a:err, ''))
      call khulnasoft#log#Exception()
    endtry
  endif
endfunction

function! s:GetCurrentCompletionItem() abort
  if exists('b:_khulnasoft_completions') &&
        \ has_key(b:_khulnasoft_completions, 'items') &&
        \ has_key(b:_khulnasoft_completions, 'index') &&
        \ b:_khulnasoft_completions.index < len(b:_khulnasoft_completions.items)
    return get(b:_khulnasoft_completions.items, b:_khulnasoft_completions.index)
  endif

  return v:null
endfunction

let s:nvim_extmark_ids = []

function! s:ClearCompletion() abort
  if has('nvim')
    let namespace = nvim_create_namespace('khulnasoft')
    for id in s:nvim_extmark_ids
      call nvim_buf_del_extmark(0, namespace, id)
    endfor
    let s:nvim_extmark_ids = []
  else
    call prop_remove({'type': s:hlgroup, 'all': v:true})
  endif
endfunction

function! s:RenderCurrentCompletion() abort
  call s:ClearCompletion()
  call khulnasoft#RedrawStatusLine()

  if mode() !~# '^[iR]'
    return ''
  endif
  if !get(g:, 'khulnasoft_render', v:true)
    return
  endif

  let current_completion = s:GetCurrentCompletionItem()
  if current_completion is v:null
    return ''
  endif

  let parts = get(current_completion, 'completionParts', [])

  let idx = 0
  let inline_cumulative_cols = 0
  let diff = 0
  for part in parts
    let row = get(part, 'line', 0) + 1
    if row != line('.')
      call khulnasoft#log#Warn('Ignoring completion, line number is not the current line.')
      continue
    endif
    if part.type ==# 'COMPLETION_PART_TYPE_INLINE'
      let _col = inline_cumulative_cols + len(get(part, 'prefix', '')) + 1
      let inline_cumulative_cols = _col - 1
    else
      let _col = len(get(part, 'prefix', '')) + 1
    endif
    let text = part.text

    if (part.type ==# 'COMPLETION_PART_TYPE_INLINE' && idx == 0) || part.type ==# 'COMPLETION_PART_TYPE_INLINE_MASK'
      let completion_prefix = get(part, 'prefix', '')
      let completion_line = completion_prefix . text
      let full_line = getline(row)
      let cursor_prefix = strpart(full_line, 0, col('.')-1)
      let matching_prefix = 0
      for i in range(len(completion_line))
        if i < len(full_line) && completion_line[i] ==# full_line[i]
          let matching_prefix += 1
        else
          break
        endif
      endfor
      if len(cursor_prefix) > len(completion_prefix)
        " Case where the cursor is beyond the completion (as if it added text).
        " We should always consume text regardless of matching or not.
        let diff = len(cursor_prefix) - len(completion_prefix)
      elseif len(cursor_prefix) < len(completion_prefix)
        " Case where the cursor is before the completion.
        " It could just be a cursor move, in which case the matching prefix goes
        " all the way to the completion prefix or beyond. Then we shouldn't do
        " anything.
        if matching_prefix >= len(completion_prefix)
          let diff = matching_prefix - len(completion_prefix)
        else
          let diff = len(cursor_prefix) - len(completion_prefix)
        endif
      endif
      if has('nvim') && diff > 0
        let diff = 0
      endif
      " Adjust completion. diff needs to be applied to all inline parts and is
      " done below.
      if diff < 0
        let text = completion_prefix[diff :] . text
      elseif diff > 0
        let text = text[diff :]
      endif
    endif

    if has('nvim')
      " Set priority high so that completions appear above LSP inlay hints
      let priority = get(b:, 'khulnasoft_virtual_text_priority',
                  \ get(g:, 'khulnasoft_virtual_text_priority', 65535))
      let _virtcol = virtcol([row, _col+diff])
      let data = {'id': idx + 1, 'hl_mode': 'combine', 'virt_text_win_col': _virtcol - 1, 'priority': priority }
      if part.type ==# 'COMPLETION_PART_TYPE_INLINE_MASK'
        let data.virt_text = [[text, s:hlgroup]]
      elseif part.type ==# 'COMPLETION_PART_TYPE_BLOCK'
        let lines = split(text, "\n", 1)
        if empty(lines[-1])
          call remove(lines, -1)
        endif
        let data.virt_lines = map(lines, { _, l -> [[l, s:hlgroup]] })
      else
        continue
      endif

      call add(s:nvim_extmark_ids, data.id)
      call nvim_buf_set_extmark(0, nvim_create_namespace('khulnasoft'), row - 1, 0, data)
    else
      if part.type ==# 'COMPLETION_PART_TYPE_INLINE'
        call prop_add(row, _col + diff, {'type': s:hlgroup, 'text': text})
      elseif part.type ==# 'COMPLETION_PART_TYPE_BLOCK'
        let text = split(part.text, "\n", 1)
        if empty(text[-1])
          call remove(text, -1)
        endif

        for line in text
          let num_leading_tabs = 0
          for c in split(line, '\zs')
            if c ==# "\t"
              let num_leading_tabs += 1
            else
              break
            endif
          endfor
          let line = repeat(' ', num_leading_tabs * shiftwidth()) . strpart(line, num_leading_tabs)
          call prop_add(row, 0, {'type': s:hlgroup, 'text_align': 'below', 'text': line})
        endfor
      endif
    endif

    let idx = idx + 1
  endfor
endfunction

function! khulnasoft#Clear(...) abort
  let b:_khulnasoft_status = 0
  call khulnasoft#RedrawStatusLine()
  if exists('g:_khulnasoft_timer')
    call timer_stop(remove(g:, '_khulnasoft_timer'))
  endif

  " Cancel any existing request.
  if exists('b:_khulnasoft_completions')
    let request_id = get(b:_khulnasoft_completions, 'request_id', 0)
    if request_id > 0
      try
        call khulnasoft#server#Request('CancelRequest', {'request_id': request_id})
      catch
        call khulnasoft#log#Exception()
      endtry
    endif
    call s:RenderCurrentCompletion()
    unlet! b:_khulnasoft_completions

  endif

  if a:0 == 0
    call s:RenderCurrentCompletion()
  endif
  return ''
endfunction

function! khulnasoft#CycleCompletions(n) abort
  if s:GetCurrentCompletionItem() is v:null
    return
  endif

  let b:_khulnasoft_completions.index += a:n
  let n_items = len(b:_khulnasoft_completions.items)

  if b:_khulnasoft_completions.index < 0
    let b:_khulnasoft_completions.index += n_items
  endif

  let b:_khulnasoft_completions.index %= n_items

  call s:RenderCurrentCompletion()
endfunction

function! khulnasoft#Complete(...) abort
  if a:0 == 2
    let bufnr = a:1
    let timer = a:2

    if timer isnot# get(g:, '_khulnasoft_timer', -1)
      return
    endif

    call remove(g:, '_khulnasoft_timer')

    if mode() !=# 'i' || bufnr !=# bufnr('')
      return
    endif
  endif

  if exists('g:_khulnasoft_timer')
    call timer_stop(remove(g:, '_khulnasoft_timer'))
  endif

  if !khulnasoft#Enabled()
    return
  endif

  if &encoding !=# 'latin1' && &encoding !=# 'utf-8'
    echoerr 'Only latin1 and utf-8 are supported'
    return
  endif

  let other_documents = []
  let current_bufnr = bufnr('%')
  let loaded_buffers = getbufinfo({'bufloaded':1})
  for buf in loaded_buffers
    if buf.bufnr != current_bufnr && getbufvar(buf.bufnr, '&filetype') !=# ''
      call add(other_documents, khulnasoft#doc#GetDocument(buf.bufnr, 1, 1))
    endif
  endfor

  let data = {
        \ 'metadata': khulnasoft#server#RequestMetadata(),
        \ 'document': khulnasoft#doc#GetDocument(bufnr(), line('.'), col('.')),
        \ 'editor_options': khulnasoft#doc#GetEditorOptions(),
        \ 'other_documents': other_documents
        \ }

  if exists('b:_khulnasoft_completions.request_data') && b:_khulnasoft_completions.request_data ==# data
    return
  endif

  " Add request id after we check for identical data.
  let request_data = deepcopy(data)

  let s:request_nonce += 1
  let request_id = s:request_nonce
  let data.metadata.request_id = request_id

  try
    let b:_khulnasoft_status = 1
    let request_job = khulnasoft#server#Request('GetCompletions', data, function('s:HandleCompletionsResult', []))

    let b:_khulnasoft_completions = {
          \ 'request_data': request_data,
          \ 'request_id': request_id,
          \ 'job': request_job
          \ }
  catch
    call khulnasoft#log#Exception()
  endtry
endfunction

function! khulnasoft#DebouncedComplete(...) abort
  call khulnasoft#Clear()
  if get(g:, 'khulnasoft_manual', v:false)
    return
  endif
  let current_buf = bufnr('')
  let delay = get(g:, 'khulnasoft_idle_delay', 75)
  let g:_khulnasoft_timer = timer_start(delay, function('khulnasoft#Complete', [current_buf]))
endfunction

function! khulnasoft#CycleOrComplete() abort
  if s:GetCurrentCompletionItem() is v:null
    call khulnasoft#Complete()
  else
    call khulnasoft#CycleCompletions(1)
  endif
endfunction

function BuildChatUrl(metadata, chat_port, ws_port) abort
  let config = get(g:, 'khulnasoft_server_config', {})
  let l:has_enterprise_extension = 'false'
  if has_key(config, 'api_url') && !empty(config.api_url)
    let l:has_enterprise_extension = 'true'
  endif

  " Hard-coded to English locale and allowed telemetry.
  let l:url = 'http://127.0.0.1:' . a:chat_port . '/?' . 'api_key=' . a:metadata.api_key . '&ide_name=' . a:metadata.ide_name . '&ide_version=' . a:metadata.ide_version . '&extension_name=' . a:metadata.extension_name . '&extension_version=' . a:metadata.extension_version . '&web_server_url=ws://127.0.0.1:' . a:ws_port . '&has_enterprise_extension=' . l:has_enterprise_extension . '&app_name=Vim&locale=en&ide_telemetry_enabled=true&has_index_service=true'
  return l:url
endfunction

function! s:LaunchChat(out, err, status) abort
  let l:metadata = khulnasoft#server#RequestMetadata()
  let l:processes = json_decode(join(a:out, ''))
  let l:chat_port = l:processes['chatClientPort']
  let l:ws_port = l:processes['chatWebServerPort']

  let l:url = BuildChatUrl(l:metadata, l:chat_port, l:ws_port)
  let l:browser = khulnasoft#command#BrowserCommand()
  let opened_browser = v:false
  if !empty(browser)
    echomsg 'Navigating to ' . l:url
    try
      call system(l:browser . ' ' . '"' . l:url . '"')
      if v:shell_error is# 0
        let l:opened_browser = v:true
      endif
    catch
    endtry

    if !l:opened_browser
      echomsg 'Failed to open browser. Please go to the link above.'
    endif
  else
    echomsg 'No available browser found. Please go to ' . l:url
  endif
endfunction

let g:khulnasoft_workspace_root_hints = ['.bzr','.git','.hg','.svn','_FOSSIL_','package.json']
function! s:GetProjectRoot() abort
  let l:last_dir = ''
  let l:dir = getcwd()
  while l:dir != l:last_dir
    for l:root_hint in g:khulnasoft_workspace_root_hints
      let l:hint = l:dir . '/' . l:root_hint
      if isdirectory(l:hint) || filereadable(l:hint)
        return l:dir
      endif
    endfor
    let l:last_dir = l:dir
    let l:dir = fnamemodify(l:dir, ':h')
  endwhile
  return getcwd()
endfunction

function! khulnasoft#RefreshContext() abort
  " current buffer is 1
  try
    call khulnasoft#server#Request('RefreshContextForIdeAction', {'active_document': khulnasoft#doc#GetDocument(1, line('.'), col('.'))})
  catch
    call khulnasoft#log#Exception()
  endtry
endfunction

" This assumes a single workspace is involved per Vim session, for now.
let s:khulnasoft_workspace_indexed = v:false
function! khulnasoft#AddTrackedWorkspace() abort
  if (!khulnasoft#Enabled() || s:khulnasoft_workspace_indexed)
    return
  endif
  let s:khulnasoft_workspace_indexed = v:true
  try
    call khulnasoft#server#Request('AddTrackedWorkspace', {'workspace': s:GetProjectRoot()})
  catch
    call khulnasoft#log#Exception()
  endtry
endfunction

function! khulnasoft#Chat() abort
  if (!khulnasoft#Enabled())
    return
  endif
  try
    call khulnasoft#RefreshContext()
    call khulnasoft#server#Request('GetProcesses', khulnasoft#server#RequestMetadata(), function('s:LaunchChat', []))
    call khulnasoft#AddTrackedWorkspace()
    " If user has chat_ports set, they are probably using vim remotely and trying to use chat via port forwarding.
    " In that case display the url here so that it is easier to copy, as the browser will fail to open automatically. 
    let chat_ports = get(g:, 'khulnasoft_port_config', {})
    if has_key(chat_ports, 'chat_client') && !empty(chat_ports.chat_client) && has_key(chat_ports, 'web_server') && !empty(chat_ports.web_server)
      let l:metadata = khulnasoft#server#RequestMetadata()
      let l:url = BuildChatUrl(l:metadata, chat_ports.chat_client, chat_ports.web_server)
      echomsg l:url
    endif
  catch
    call khulnasoft#log#Exception()
  endtry
endfunction

function! khulnasoft#GetStatusString(...) abort
  let s:using_khulnasoft_status = 1
  if (!khulnasoft#Enabled())
    return 'OFF'
  endif
  if mode() !~# '^[iR]'
    return ' ON'
  endif
  if exists('b:_khulnasoft_status') && b:_khulnasoft_status > 0
    if b:_khulnasoft_status == 2
      if exists('b:_khulnasoft_completions') &&
            \ has_key(b:_khulnasoft_completions, 'items') &&
            \ has_key(b:_khulnasoft_completions, 'index')
        if len(b:_khulnasoft_completions.items) > 0
          return printf('%d/%d', b:_khulnasoft_completions.index + 1, len(b:_khulnasoft_completions.items))
        else
          return ' 0 '
        endif
      endif
    endif
    if b:_khulnasoft_status == 1
      return ' * '
    endif
    return ' 0 '
  endif
  return '   '
endfunction

function! khulnasoft#RedrawStatusLine() abort
  if s:using_khulnasoft_status
    redrawstatus
  endif
endfunction

function! khulnasoft#ServerLeave() abort
  if !exists('g:khulnasoft_server_job') || g:khulnasoft_server_job is v:null
    return
  endif

  if has('nvim')
    call jobstop(g:khulnasoft_server_job)
  else
    call job_stop(g:khulnasoft_server_job)
  endif
endfunction
