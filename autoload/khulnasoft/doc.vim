let s:language_enum = {
      \ 'unspecified': 0,
      \ 'c': 1,
      \ 'clojure': 2,
      \ 'coffeescript': 3,
      \ 'cpp': 4,
      \ 'csharp': 5,
      \ 'css': 6,
      \ 'cudacpp': 7,
      \ 'dockerfile': 8,
      \ 'go': 9,
      \ 'groovy': 10,
      \ 'handlebars': 11,
      \ 'haskell': 12,
      \ 'hcl': 13,
      \ 'html': 14,
      \ 'ini': 15,
      \ 'java': 16,
      \ 'javascript': 17,
      \ 'json': 18,
      \ 'julia': 19,
      \ 'kotlin': 20,
      \ 'latex': 21,
      \ 'less': 22,
      \ 'lua': 23,
      \ 'makefile': 24,
      \ 'markdown': 25,
      \ 'objectivec': 26,
      \ 'objectivecpp': 27,
      \ 'perl': 28,
      \ 'php': 29,
      \ 'plaintext': 30,
      \ 'protobuf': 31,
      \ 'pbtxt': 32,
      \ 'python': 33,
      \ 'r': 34,
      \ 'ruby': 35,
      \ 'rust': 36,
      \ 'sass': 37,
      \ 'scala': 38,
      \ 'scss': 39,
      \ 'shell': 40,
      \ 'sql': 41,
      \ 'starlark': 42,
      \ 'swift': 43,
      \ 'typescriptreact': 44,
      \ 'typescript': 45,
      \ 'visualbasic': 46,
      \ 'vue': 47,
      \ 'xml': 48,
      \ 'xsl': 49,
      \ 'yaml': 50,
      \ 'svelte': 51,
      \ 'toml': 52,
      \ 'dart': 53,
      \ 'rst': 54,
      \ 'ocaml': 55,
      \ 'cmake': 56,
      \ 'pascal': 57,
      \ 'elixir': 58,
      \ 'fsharp': 59,
      \ 'lisp': 60,
      \ 'matlab': 61,
      \ 'ps1': 62,
      \ 'solidity': 63,
      \ 'ada': 64,
      \ 'blade': 84,
      \ 'astro': 85,
      \ }

let s:filetype_aliases = {
      \ 'bash': 'shell',
      \ 'coffee': 'coffeescript',
      \ 'cs': 'csharp',
      \ 'cuda': 'cudacpp',
      \ 'dosini': 'ini',
      \ 'javascriptreact': 'javascript',
      \ 'make': 'makefile',
      \ 'objc': 'objectivec',
      \ 'objcpp': 'objectivecpp',
      \ 'proto': 'protobuf',
      \ 'raku': 'perl',
      \ 'sh': 'shell',
      \ 'text': 'plaintext',
      \ }

function! khulnasoft#doc#GetDocument(bufId, curLine, curCol) abort
  let lines = getbufline(a:bufId, 1, '$')
  if getbufvar(a:bufId, '&endofline')
    call add(lines, '')
  endif

  let filetype = substitute(getbufvar(a:bufId, '&filetype'), '\..*', '', '')
  let language = get(s:filetype_aliases, empty(filetype) ? 'text' : filetype, filetype)
  if empty(filetype) && get(g:, 'khulnasoft_warn_filetype_missing', v:true)
    call khulnasoft#log#Warn('No filetype detected. This will affect completion quality.')
    let g:khulnasoft_warn_filetype_missing = v:false
  endif
  let editor_language = empty(getbufvar(a:bufId, '&filetype')) ? 'unspecified' : getbufvar(a:bufId, '&filetype')
  let doc = {
        \ 'text': join(lines, khulnasoft#util#LineEndingChars()),
        \ 'editor_language': editor_language,
        \ 'language': get(s:language_enum, language, 0),
        \ 'cursor_position': {'row': a:curLine - 1, 'col': a:curCol - 1},
        \ 'absolute_path_migrate_me_to_uri': fnamemodify(bufname(a:bufId), ':p'),
        \ }

  let line_ending = khulnasoft#util#LineEndingChars(v:null)
  if line_ending isnot# v:null
    let doc.line_ending = line_ending
  endif

  return doc
endfunction

function! khulnasoft#doc#GetEditorOptions() abort
  return {
      \ 'tab_size': shiftwidth(),
      \ 'insert_spaces': &expandtab ? v:true : v:false,
      \ }
endfunction
