function! khulnasoft#command#BrowserCommand() abort
  if has('win32') && executable('rundll32')
    return 'rundll32 url.dll,FileProtocolHandler'
  elseif isdirectory('/private') && executable('/usr/bin/open')
    return '/usr/bin/open'
  elseif executable('xdg-open')
    return 'xdg-open'
  else
    return ''
  endif
endfunction

function! khulnasoft#command#XdgConfigDir() abort
  let config_dir = get($, 'XDG_CONFIG_HOME', $HOME . '/.config')
  return config_dir . '/khulnasoft'
endfunction

function! khulnasoft#command#HomeDir() abort
  let data_dir = get($, 'XDG_DATA_HOME', $HOME . '/khulnasoft')
  return data_dir . '/khulnasoft'
endfunction

function! khulnasoft#command#LoadConfig(dir) abort
  let config_path = a:dir . '/config.json'
  if filereadable(config_path)
    let contents = join(readfile(config_path), '')
    if !empty(contents)
      return json_decode(contents)
    endif
  endif
  return {}
endfunction

let s:api_key = get(khulnasoft#command#LoadConfig(khulnasoft#command#HomeDir()), 'apiKey', '')

let s:commands = {}

function! s:commands.Auth(...) abort
  if !khulnasoft#util#HasSupportedVersion()
    let min_version = has('nvim') ? 'NeoVim 0.6' : 'Vim 9.0.0185'
    echoerr 'This version of Vim is unsupported. Install ' . min_version . ' or greater to use Khulnasoft.'
    return
  endif

  let config = get(g:, 'khulnasoft_server_config', {})
  let portal_url = get(config, 'portal_url', 'https://www.khulnasoft.com')
  let url = portal_url . '/profile?response_type=token&redirect_uri=vim-show-auth-token&state=a&scope=openid%20profile%20email&redirect_parameters_type=query'
  let browser = khulnasoft#command#BrowserCommand()
  let opened_browser = v:false

  if !empty(browser)
    echomsg 'Navigating to ' . url
    try
      call system(browser . ' ' . shellescape(url))
      if v:shell_error == 0
        let opened_browser = v:true
      endif
    catch
    endtry

    if !opened_browser
      echomsg 'Failed to open browser. Please go to the link above.'
    endif
  else
    echomsg 'No available browser found. Please go to ' . url
  endif

  let api_key = ''
  call inputsave()
  let auth_token = inputsecret('Paste your token here: ')
  call inputrestore()
  let tries = 0

  let register_user_url = get(config, 'api_url', 'https://api.khulnasoft.com') . '/exa.seat_management_pb.SeatManagementService/RegisterUser'

  while empty(api_key) && tries < 3
    let command = 'curl -sS ' . register_user_url . ' --header "Content-Type: application/json" --data ' . shellescape(json_encode({'firebase_id_token': auth_token}))
    let response = system(command)
    let curl_ssl_error = 'The revocation function was unable to check revocation for the certificate.'

    if has('win32') && response =~ curl_ssl_error
      call inputsave()
      let useNoSsl = input('For Windows systems behind a corporate proxy there may be trouble verifying the SSL certificates. Would you like to try auth without checking SSL certificate revocation? (y/n): ')
      call inputrestore()
      if useNoSsl ==? 'y'
        let command = 'curl --ssl-no-revoke -sS ' . register_user_url . ' --header "Content-Type: application/json" --data ' . shellescape(json_encode({'firebase_id_token': auth_token}))
        let response = system(command)
      endif
    endif

    let res = json_decode(response)
    let api_key = get(res, 'api_key', '')
    if empty(api_key)
      echomsg 'Unexpected response: ' . response
      call inputsave()
      let auth_token = inputsecret('Invalid token, please try again: ')
      call inputrestore()
    endif
    let tries += 1
  endwhile

  if !empty(api_key)
    let s:api_key = api_key
    let config_dir = khulnasoft#command#HomeDir()
    let config_path = config_dir . '/config.json'
    let config = khulnasoft#command#LoadConfig(config_dir)
    let config.apiKey = api_key

    try
      call mkdir(config_dir, 'p')
      call writefile([json_encode(config)], config_path)
    catch
      call khulnasoft#log#Error('Could not persist api key to config.json')
    endtry
  endif
endfunction

function! s:commands.Chat(...) abort
  call khulnasoft#Chat()
endfunction

function! s:commands.Disable(...) abort
  let g:khulnasoft_enabled = 0
endfunction

function! s:commands.DisableBuffer(...) abort
  let b:khulnasoft_enabled = 0
endfunction

function! khulnasoft#command#StartLanguageServer() abort
  if !get(g:, 'khulnasoft_server_started', v:false)
    call timer_start(0, function('khulnasoft#server#Start'))
    let g:khulnasoft_server_started = v:true
  endif
endfunction

function! s:commands.Enable(...) abort
  let g:khulnasoft_enabled = 1
  call khulnasoft#command#StartLanguageServer()
endfunction

function! s:commands.EnableBuffer(...) abort
  let b:khulnasoft_enabled = 1
  call khulnasoft#command#StartLanguageServer()
endfunction

function! s:commands.Toggle(...) abort
  if exists('g:khulnasoft_enabled') && !g:khulnasoft_enabled
    call s:commands.Enable()
  else
    call s:commands.Disable()
  endif
endfunction

function! khulnasoft#command#ApiKey() abort
  if empty(s:api_key)
    echom 'Khulnasoft: No API key found; maybe you need to run `:Khulnasoft Auth`?'
  endif
  return s:api_key
endfunction

function! khulnasoft#command#Complete(arg, lead, pos) abort
  let args = matchstr(strpart(a:lead, 0, a:pos), 'C\%[odeium][! ] *\zs.*')
  return sort(filter(keys(s:commands), { k -> strpart(k, 0, len(a:arg)) ==# a:arg }))
endfunction

function! khulnasoft#command#Command(arg) abort
  let cmd = matchstr(a:arg, '^\%(\\.\|\S\)\+')
  let arg = matchstr(a:arg, '\s\zs\S.*')
  if !has_key(s:commands, cmd)
    return 'echoerr ' . string("Khulnasoft: command '" . string(cmd) . "' not found")
  endif
  let res = s:commands[cmd](arg)
  return type(res) == v:t_string ? res : ''
endfunction
