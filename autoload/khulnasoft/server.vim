let s:language_server_version = '1.20.8'
let s:language_server_sha = '37f12b83df389802b7d4e293b3e1a986aca289c0'
let s:root = expand('<sfile>:h:h:h')
let s:bin = v:null

if has('nvim')
  let s:ide = 'neovim'
else
  let s:ide = 'vim'
endif

if !exists('s:editor_version')
  if has('nvim')
    let s:ide_version = matchstr(execute('version'), 'NVIM v\zs[^[:space:]]\+')
  else
    let major = v:version / 100
    let minor = v:version % 100
    if exists('v:versionlong')
      let patch = printf('%04d', v:versionlong % 1000)
      let s:ide_version = major . '.' . minor . '.' . patch
    else
      let s:ide_version = major . '.' . minor
    endif
  endif
endif

let s:server_port = v:null
if khulnasoft#util#IsUsingRemoteChat()
  let s:server_port = 42100
endif

let g:khulnasoft_server_job = v:null

function! s:OnExit(result, status, on_complete_cb) abort
  if has_key(a:result, 'closed')
    call remove(a:result, 'closed')
    call a:on_complete_cb(a:result.out, a:result.err, a:status)
  else
    let a:result.exit_status = a:status
  endif
endfunction

function! s:OnClose(result, on_complete_cb) abort
  if has_key(a:result, 'exit_status')
    call a:on_complete_cb(a:result.out, a:result.err, a:result.exit_status)
  else
    let a:result.closed = v:true
  endif
endfunction

function! s:NoopCallback(...) abort
endfunction

function! khulnasoft#server#RequestMetadata() abort
  return {
        \ 'api_key': khulnasoft#command#ApiKey(),
        \ 'ide_name': s:ide,
        \ 'ide_version': s:ide_version,
        \ 'extension_name': 'vim',
        \ 'extension_version': s:language_server_version,
        \ }
endfunction

function! khulnasoft#server#Request(type, data, ...) abort
  if s:server_port is# v:null
    throw 'Server port has not been properly initialized.'
  endif
  let uri = 'http://127.0.0.1:' . s:server_port . '/exa.language_server_pb.LanguageServerService/' . a:type
  let data = json_encode(a:data)
  let args = ['curl', uri, '--header', 'Content-Type: application/json', '-d@-']
  let result = {'out': [], 'err': []}
  let ExitCallback = a:0 && !empty(a:1) ? a:1 : function('s:NoopCallback')

  if has('nvim')
    let jobid = jobstart(args, {
                \ 'on_stdout': { channel, data, t -> add(result.out, join(data, "\n")) },
                \ 'on_stderr': { channel, data, t -> add(result.err, join(data, "\n")) },
                \ 'on_exit': { job, status, t -> ExitCallback(result.out, result.err, status) },
                \ })
    call chansend(jobid, data)
    call chanclose(jobid, 'stdin')
    return jobid
  else
    let job = job_start(args, {
                \ 'in_mode': 'raw',
                \ 'out_mode': 'raw',
                \ 'out_cb': { channel, data -> add(result.out, data) },
                \ 'err_cb': { channel, data -> add(result.err, data) },
                \ 'exit_cb': { job, status -> s:OnExit(result, status, ExitCallback) },
                \ 'close_cb': { channel -> s:OnClose(result, ExitCallback) }
                \ })
    let channel = job_getchannel(job)
    call ch_sendraw(channel, data)
    call ch_close_in(channel)
    return job
  endif
endfunction

function! s:FindPort(dir, timer) abort
  let time = localtime()
  for name in readdir(a:dir)
    let path = a:dir . '/' . name
    if time - getftime(path) <= 5 && getftype(path) ==# 'file'
      call khulnasoft#log#Info('Found port: ' . name)
      let s:server_port = name
      call s:RequestServerStatus()
      call timer_stop(a:timer)
      break
    endif
  endfor
endfunction

function! s:RequestServerStatus() abort
  call khulnasoft#server#Request('GetStatus', {'metadata': khulnasoft#server#RequestMetadata()}, function('s:HandleGetStatusResponse'))
endfunction

function! s:HandleGetStatusResponse(out, err, status) abort
  if a:status == 0
    let response = json_decode(join(a:out, "\n"))
    let status = get(response, 'status', {})
    if has_key(status, 'message') && !empty(status.message)
      echom status.message
    endif
  else
    call khulnasoft#log#Error(join(a:err, "\n"))
  endif
endfunction

function! s:SendHeartbeat(timer) abort
  try
    call khulnasoft#server#Request('Heartbeat', {'metadata': khulnasoft#server#RequestMetadata()})
  catch
    call khulnasoft#log#Exception()
  endtry
endfunction

function! khulnasoft#server#Start(...) abort
  let user_defined_khulnasoft_bin = get(g:, 'khulnasoft_bin', '')

  if user_defined_khulnasoft_bin != '' && filereadable(user_defined_khulnasoft_bin)
    let s:bin = user_defined_khulnasoft_bin
    call s:ActuallyStart()
    return
  endif

  let user_defined_os = get(g:, 'khulnasoft_os', '')
  let user_defined_arch = get(g:, 'khulnasoft_arch', '')

  if user_defined_os != '' && user_defined_arch != ''
    let os = user_defined_os
    let arch = user_defined_arch
  else
    silent let os = substitute(system('uname'), '\n', '', '')
    silent let arch = substitute(system('uname -m'), '\n', '', '')
  endif

  let is_arm = stridx(arch, 'arm') == 0 || stridx(arch, 'aarch64') == 0

  if empty(os)
    if has("linux")
      let os = "Linux"
    elseif has("mac")
      let os = "Darwin"
    endif
  endif

  if os ==# 'Linux' && is_arm
    let bin_suffix = 'linux_arm'
  elseif os ==# 'Linux'
    let bin_suffix = 'linux_x64'
  elseif os ==# 'Darwin' && is_arm
    let bin_suffix = 'macos_arm'
  elseif os ==# 'Darwin'
    let bin_suffix = 'macos_x64'
  else
    let bin_suffix = 'windows_x64.exe'
  endif

  let config = get(g:, 'khulnasoft_server_config', {})
  if has_key(config, 'portal_url') && !empty(config.portal_url)
    let response = system('curl -s ' . config.portal_url . '/api/version')
    if v:shell_error == '0'
      let s:language_server_version = response
      let s:language_server_sha = 'enterprise-' . s:language_server_version
    else
      call khulnasoft#log#Error('Failed to fetch version from ' . config.portal_url)
      call khulnasoft#log#Error(v:shell_error)
    endif
  endif

  let sha = get(khulnasoft#command#LoadConfig(khulnasoft#command#XdgConfigDir()), 'sha', s:language_server_sha)
  let bin_dir = khulnasoft#command#HomeDir() . '/bin/' . sha
  let s:bin = bin_dir . '/language_server_' . bin_suffix
  call mkdir(bin_dir, 'p')

  if !filereadable(s:bin)
    call delete(s:bin)
    if sha ==# s:language_server_sha
      let config = get(g:, 'khulnasoft_server_config', {})
      if has_key(config, 'portal_url') && !empty(config.portal_url)
        let base_url = config.portal_url
      else
        let base_url = 'https://github.com/KhulnaSoft/khulnasoft-release/releases/download'
      endif
      let base_url = substitute(base_url, '/\+$', '', '')
      let url = base_url . '/language-server-v' . s:language_server_version . '/language_server_' . bin_suffix . '.gz'
    else
      let url = 'https://storage.googleapis.com/khulnasoft-dist/khulnasoft/' . sha . '/language_server_' . bin_suffix . '.gz'
    endif
    let args = ['curl', '-Lo', s:bin . '.gz', url]
    if has('nvim')
      let s:download_job = jobstart(args, {'on_exit': { job, status, t -> s:UnzipAndStart(status) }})
    else
      let s:download_job = job_start(args, {'exit_cb': { job, status -> s:UnzipAndStart(status) }})
    endif
  else
    call s:ActuallyStart()
  endif
endfunction

function! s:UnzipAndStart(status) abort
  if has('win32')
    " Save old settings.
    let old_shell = &shell
    let old_shellquote = &shellquote
    let old_shellpipe = &shellpipe
    let old_shellxquote = &shellxquote
    let old_shellcmdflag = &shellcmdflag
    let old_shellredir = &shellredir
    " Switch to powershell.
    let &shell = 'powershell'
    set shellquote=\"
    set shellpipe=\|
    set shellcmdflag=-NoLogo\ -NoProfile\ -ExecutionPolicy\ RemoteSigned\ -Command
    set shellredir=\|\ Out-File\ -Encoding\ UTF8
    call system('& { . ' . shellescape(s:root . '/powershell/gzip.ps1') . '; Expand-File ' . shellescape(s:bin . '.gz') . ' }')
    " Restore old settings.
    let &shell = old_shell
    let &shellquote = old_shellquote
    let &shellpipe = old_shellpipe
    let &shellxquote = old_shellxquote
    let &shellcmdflag = old_shellcmdflag
    let &shellredir = old_shellredir
  else
    if !executable('gzip')
      call khulnasoft#log#Error('Failed to extract language server binary: missing `gzip`.')
      return ''
    endif
    call system('gzip -d ' . s:bin . '.gz')
    call system('chmod +x ' . s:bin)
  endif
  if !filereadable(s:bin)
    call khulnasoft#log#Error('Failed to download language server binary.')
    return ''
  endif
  call s:ActuallyStart()
endfunction

function! s:ActuallyStart() abort
  let config = get(g:, 'khulnasoft_server_config', {})
  let chat_ports = get(g:, 'khulnasoft_port_config', {})
  let manager_dir = tempname() . '/khulnasoft/manager'
  call mkdir(manager_dir, 'p')
  let args = [
        \ s:bin,
        \ '--api_server_url', get(config, 'api_url', 'https://server.khulnasoft.com'),
        \ '--enable_local_search', '--enable_index_service', '--search_max_workspace_file_count', '5000',
        \ '--enable_chat_web_server', '--enable_chat_client'
        \ ]
  if has_key(config, 'api_url') && !empty(config.api_url)
    let args += ['--enterprise_mode']
    let args += ['--portal_url', get(config, 'portal_url', 'https://khulnasoft.example.com')]
  endif
  if !khulnasoft#util#IsUsingRemoteChat()
    let args += ['--manager_dir', manager_dir]
  endif
  if has_key(chat_ports, 'web_server') && !empty(chat_ports.web_server)
    let args += ['--chat_web_server_port', chat_ports.web_server]
  endif
  if has_key(chat_ports, 'chat_client') && !empty(chat_ports.chat_client)
    let args += ['--chat_client_port', chat_ports.chat_client]
  endif

  call khulnasoft#log#Info('Launching server with manager_dir ' . manager_dir)
  if has('nvim')
    let g:khulnasoft_server_job = jobstart(args, {
                \ 'on_stderr': { channel, data, t -> khulnasoft#log#Info('[SERVER] ' . join(data, "\n")) },
                \ })
  else
    let g:khulnasoft_server_job = job_start(args, {
                \ 'out_mode': 'raw',
                \ 'err_cb': { channel, data -> khulnasoft#log#Info('[SERVER] ' . data) },
                \ })
  endif
  if !khulnasoft#util#IsUsingRemoteChat()
    call timer_start(500, function('s:FindPort', [manager_dir]), {'repeat': -1})
  endif
  call timer_start(5000, function('s:SendHeartbeat', []), {'repeat': -1})
endfunction
