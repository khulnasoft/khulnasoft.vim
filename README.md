# KhulnaSoft.vim

---

[![Discord](https://img.shields.io/discord/1027685395649015980?label=community&color=5865F2&logo=discord&logoColor=FFFFFF)](https://discord.gg/3XFf78nAx5)
[![Twitter Follow](https://img.shields.io/badge/style--blue?style=social&logo=twitter&label=Follow%20%40khulnasoftdev)](https://twitter.com/intent/follow?screen_name=khulnasoftdev)
![License](https://img.shields.io/github/license/KhulnaSoft/khulnasoft.vim)
[![Docs](https://img.shields.io/badge/Khulnasoft%20Docs-09B6A2)](https://docs.khulnasoft.com)
[![Canny Board](https://img.shields.io/badge/Feature%20Requests-6b69ff)](https://khulnasoft.canny.io/feature-requests/)
[![built with Khulnasoft](https://khulnasoft.com/badges/main)](https://khulnasoft.com?repo_name=khulnasoft%2Fkhulnasoft.vim)

[![Visual Studio](https://img.shields.io/visual-studio-marketplace/i/Khulnasoft.khulnasoft?label=Visual%20Studio&logo=visualstudio)](https://marketplace.visualstudio.com/items?itemName=Khulnasoft.khulnasoft)
[![JetBrains](https://img.shields.io/jetbrains/plugin/d/20540?label=JetBrains)](https://plugins.jetbrains.com/plugin/20540-khulnasoft/)
[![Open VSX](https://img.shields.io/open-vsx/dt/Khulnasoft/khulnasoft?label=Open%20VSX)](https://open-vsx.org/extension/Khulnasoft/khulnasoft)
[![Google Chrome](https://img.shields.io/chrome-web-store/users/hobjkcpmjhlegmobgonaagepfckjkceh?label=Google%20Chrome&logo=googlechrome&logoColor=FFFFFF)](https://chrome.google.com/webstore/detail/khulnasoft/hobjkcpmjhlegmobgonaagepfckjkceh)

_Free, ultrafast Copilot alternative for Vim and Neovim_

Khulnasoft autocompletes your code with AI in all major IDEs. We [launched](https://www.khulnasoft.com/blog/khulnasoft-copilot-alternative-in-vim) this implementation of the Khulnasoft plugin for Vim and Neovim to bring this modern coding superpower to more developers. Check out our [playground](https://www.khulnasoft.com/playground) if you want to quickly try out Khulnasoft online.

Contributions are welcome! Feel free to submit pull requests and issues related to the plugin.

<br />

![Example](https://user-images.githubusercontent.com/1908017/213154744-984b73de-9873-4b85-998f-799d92b28eec.gif)

<br />

## 🚀 Getting started

1. Install [Vim](https://github.com/vim/vim) (at least 9.0.0185) or [Neovim](https://github.com/neovim/neovim/releases/latest) (at
   least 0.6)

2. Install `KhulnaSoft/khulnasoft.vim` using your vim plugin manager of
   choice, or manually. See [Installation Options](#-installation-options) below.

3. Run `:Khulnasoft Auth` to set up the plugin and start using Khulnasoft.

You can run `:help khulnasoft` for a full list of commands and configuration
options, or see [this guide](https://www.khulnasoft.com/vim_tutorial) for a quick tutorial on how to use Khulnasoft.

## 🛠️ Configuration

For a full list of configuration options you can run `:help khulnasoft`.
A few of the most popular options are highlighted below.

### ⌨️ Keybindings

Khulnasoft provides the following functions to control suggestions:

| Action                       | Function                       | Default Binding |
| ---------------------------  | ------------------------------ | --------------- |
| Clear current suggestion     | `khulnasoft#Clear()`              | `<C-]>`         |
| Next suggestion              | `khulnasoft#CycleCompletions(1)`  | `<M-]>`         |
| Previous suggestion          | `khulnasoft#CycleCompletions(-1)` | `<M-[>`         |
| Insert suggestion            | `khulnasoft#Accept()`             | `<Tab>`         |
| Manually trigger suggestion  | `khulnasoft#Complete()`           | `<M-Bslash>`    |
| Accept word from suggestion  | `khulnasoft#AcceptNextWord()`     | `<C-k>`         |
| Accept line from suggestion  | `khulnasoft#AcceptNextLine()`     | `<C-l>`         |

Khulnasoft's default keybindings can be disabled by setting

```vim
let g:khulnasoft_disable_bindings = 1
```

or in Neovim:

```lua
vim.g.khulnasoft_disable_bindings = 1
```

If you'd like to just disable the `<Tab>` binding, you can alternatively
use the `g:khulnasoft_no_map_tab` option.

If you'd like to bind the actions above to different keys, this might look something like the following in Vim:

```vim
imap <script><silent><nowait><expr> <C-g> khulnasoft#Accept()
imap <script><silent><nowait><expr> <C-h> khulnasoft#AcceptNextWord()
imap <script><silent><nowait><expr> <C-j> khulnasoft#AcceptNextLine()
imap <C-;>   <Cmd>call khulnasoft#CycleCompletions(1)<CR>
imap <C-,>   <Cmd>call khulnasoft#CycleCompletions(-1)<CR>
imap <C-x>   <Cmd>call khulnasoft#Clear()<CR>
```

Or in Neovim (using [wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim#specifying-plugins) or [folke/lazy.nvim](https://github.com/folke/lazy.nvim)):

```lua
-- Remove the `use` here if you're using folke/lazy.nvim.
use {
  'KhulnaSoft/khulnasoft.vim',
  config = function ()
    -- Change '<C-g>' here to any keycode you like.
    vim.keymap.set('i', '<C-g>', function () return vim.fn['khulnasoft#Accept']() end, { expr = true, silent = true })
    vim.keymap.set('i', '<c-;>', function() return vim.fn['khulnasoft#CycleCompletions'](1) end, { expr = true, silent = true })
    vim.keymap.set('i', '<c-,>', function() return vim.fn['khulnasoft#CycleCompletions'](-1) end, { expr = true, silent = true })
    vim.keymap.set('i', '<c-x>', function() return vim.fn['khulnasoft#Clear']() end, { expr = true, silent = true })
  end
}
```

(Make sure that you ran `:Khulnasoft Auth` after installation.)

### ⛔ Disabling Khulnasoft

Khulnasoft can be disabled for particular filetypes by setting the
`g:khulnasoft_filetypes` variable in your vim config file (vimrc/init.vim):

```vim
let g:khulnasoft_filetypes = {
    \ "bash": v:false,
    \ "typescript": v:true,
    \ }
```

Khulnasoft is enabled by default for most filetypes.

You can also _disable_ khulnasoft by default with the `g:khulnasoft_enabled` variable,
and enable it manually per buffer by running `:KhulnasoftEnable`:

```vim
let g:khulnasoft_enabled = v:false
```

or in Neovim:

```lua
vim.g.khulnasoft_enabled = false
```

Or you can disable khulnasoft for _all filetypes_ with the `g:khulnasoft_filetypes_disabled_by_default` variable,
and use the `g:khulnasoft_filetypes` variable to selectively enable khulnasoft for specified filetypes:

```vim
" let g:khulnasoft_enabled = v:true
let g:khulnasoft_filetypes_disabled_by_default = v:true

let g:khulnasoft_filetypes = {
    \ "rust": v:true,
    \ "typescript": v:true,
    \ }
```

If you would like to just disable the automatic triggering of completions:

```vim
let g:khulnasoft_manual = v:true

" You might want to use `CycleOrComplete()` instead of `CycleCompletions(1)`.
" This will make the forward cycling of suggestions also trigger the first
" suggestion manually.
imap <C-;> <Cmd>call khulnasoft#CycleOrComplete()<CR>
```

To disable automatic text rendering of suggestions (the gray text that appears for a suggestion):

```vim
let g:khulnasoft_render = v:false
```

### Show Khulnasoft status in statusline

Khulnasoft status can be generated by calling the `khulnasoft#GetStatusString()` function. In
Neovim, you can use `vim.api.nvim_call_function("khulnasoft#GetStatusString", {})` instead.
It produces a 3 char long string with Khulnasoft status:

- `'3/8'` - third suggestion out of 8
- `'0'` - Khulnasoft returned no suggestions
- `'*'` - waiting for Khulnasoft response

In normal mode, status shows if Khulnasoft is enabled or disabled by showing
`'ON'` or `'OFF'`.

In order to show it in status line add following line to your `.vimrc`:

```set statusline+=\{…\}%3{khulnasoft#GetStatusString()}```

Shorter variant without Khulnasoft logo:

```set statusline+=%3{khulnasoft#GetStatusString()}```

Please check `:help statusline` for further information about building statusline in VIM.

vim-airline supports Khulnasoft out-of-the-box since commit [3854429d](https://github.com/vim-airline/vim-airline/commit/3854429d99c8a2fb555a9837b155f33c957a2202).

### Launching Khulnasoft Chat

Calling the `khulnasoft#Chat()` function or using the `Khulnasoft Chat` command will enable search and indexing in the current project and launch Khulnasoft Chat in a new browser window.

```vim
:call khulnasoft#Chat()
:Khulnasoft Chat
```

The project root is determined by looking in Vim's current working directory for some specific files or directories to be present and goes up to parent directories until one is found.  This list of hints is user-configurable and the default value is:

```let g:khulnasoft_workspace_root_hints = ['.bzr','.git','.hg','.svn','_FOSSIL_','package.json']```

Note that launching chat enables telemetry.

## 💾 Installation Options

### 💤 Lazy

```lua
{
  'KhulnaSoft/khulnasoft.vim',
  event = 'BufEnter'
}
```

### 🔌 vim-plug

```vim
Plug 'KhulnaSoft/khulnasoft.vim', { 'branch': 'main' }
```

### 📦 Vundle

```vim
Plugin 'KhulnaSoft/khulnasoft.vim'
```

### 📦 packer.nvim:

```vim
use 'KhulnaSoft/khulnasoft.vim'
```

### 💪 Manual

#### 🖥️ Vim

Run the following. On windows, you can replace `~/.vim` with
`$HOME/vimfiles`:

```bash
git clone https://github.com/KhulnaSoft/khulnasoft.vim ~/.vim/pack/KhulnaSoft/start/khulnasoft.vim
```

#### 💻 Neovim

Run the following. On windows, you can replace `~/.config` with
`$HOME/AppData/Local`:

```bash
git clone https://github.com/KhulnaSoft/khulnasoft.vim ~/.config/nvim/pack/KhulnaSoft/start/khulnasoft.vim
```
