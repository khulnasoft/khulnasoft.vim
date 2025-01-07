if !exists('*khulnasoft#util#LineEndingChars')
  function! khulnasoft#util#LineEndingChars(...) abort
    return "\n"
  endfunction
endif

if !exists('*khulnasoft#util#HasSupportedVersion')
  function! khulnasoft#util#HasSupportedVersion() abort
    let s:nvim_virt_text_support = has('nvim-0.6') && exists('*nvim_buf_get_mark')
    let s:vim_virt_text_support = has('patch-9.0.0185') && has('textprop')

    return s:nvim_virt_text_support || s:vim_virt_text_support
  endfunction
endif

if !exists('*khulnasoft#util#IsUsingRemoteChat')
  function! khulnasoft#util#IsUsingRemoteChat() abort
    let chat_ports = get(g:, 'khulnasoft_port_config', {})
    return has_key(chat_ports, 'chat_client') && !empty(chat_ports.chat_client) && has_key(chat_ports, 'web_server') && !empty(chat_ports.web_server)
  endfunction
endif
