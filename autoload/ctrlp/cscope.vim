" =============================================================================
" File:          autoload/ctrlp/cscope.vim
" Description:   cscope extension for ctrlp.vim
" =============================================================================

" Change the name of the g:loaded_ variable to make it unique
if ( exists('g:loaded_ctrlp_cscope') && g:loaded_ctrlp_cscope )
      \ || v:version < 700 || &cp
  finish
endif
let g:loaded_ctrlp_cscope = 1


" Add this extension's settings to g:ctrlp_ext_vars
"
" Required:
"
" + init: the name of the input function including the brackets and any
"         arguments
"
" + accept: the name of the action function (only the name)
"
" + lname & sname: the long and short names to use for the statusline
"
" + type: the matching type
"   - line : match full line
"   - path : match full line like a file or a directory path
"   - tabs : match until first tab character
"   - tabe : match until last tab character
"
" Optional:
"
" + enter: the name of the function to be called before starting ctrlp
"
" + exit: the name of the function to be called after closing ctrlp
"
" + opts: the name of the option handling function called when initialize
"
" + sort: disable sorting (enabled by default when omitted)
"
" + specinput: enable special inputs '..' and '@cd' (disabled by default)
"
let s:ctrlp_var = {
      \ 'init'  : 'ctrlp#cscope#init()',
      \ 'accept': 'ctrlp#cscope#accept',
      \ 'lname' : 'cscope',
      \ 'sname' : 'csc',
      \ 'type'  : 'tabs',
      \ 'sort'  : 1,
      \ }

let s:cscope_definitions = []

" Append s:ctrlp_var to g:ctrlp_ext_vars
if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:ctrlp_var)
else
  let g:ctrlp_ext_vars = [s:ctrlp_var]
endif

function! s:parse(val)
  let words = split(a:val)
  return printf("%s\t | %s:%s", join(words[3:]), words[0], words[2])
endfunction

function! s:syntax()
  call ctrlp#hicheck('CtrlPCscopeExtra', 'Comment')
  syntax match CtrlPCScopeExtra '\zs\t.*\ze'
endfunction

" Provide a list of strings to search in
"
" Return: command
function! ctrlp#cscope#init()
	if len(s:cscope_definitions) == 0
		" Support existing 'cscope.files' list.
		let s:cscope_files = ''
		let s:cscope_opts = ''
    let s:gitroot = system('cd '.shellescape(expand('%:h')).'&& git rev-parse --git-dir 2>/dev/null')
    let s:gitroot = substitute(s:gitroot, "\n", "", "g" )
		let s:cscope_index = '.cscope.out'
		if !empty(s:gitroot) && filereadable(s:gitroot.'/cscope.files')
			" It may be in the .git folder if we are at the root of the tree and the
			" git cscope hook kicked in.
			let s:cscope_files = '-i'.s:gitroot.'/cscope.files'
			let s:cscope_index = s:gitroot.'/cscope.out'
		elseif filereadable('cscope.files')
			" It may be in the current directory.
			let s:cscope_files = '-icscope.files'
			if filereadable('cscope.out')
				let s:cscope_index = 'cscope.out'
			else
				let s:cscope_index = '.cscope.out'
			endif
		else
			" Otherwise don't create one, just scan subfolders
			let s:cscope_opts .= '-R -s .'
		endif

		let s:cscope_opts  = '-f' . s:cscope_index
		let s:cscope_opts .= ' -c'
		if filereadable(s:cscope_index)
			let s:cscope_opts .= ' -d'
		endif

		" the -1 limits the search to function/type names, -2 for function/type usage, or -0 for both.
		let s:cscope_cmd = 'cscope -q -L -k ' . s:cscope_opts . ' ' . s:cscope_files . ' -1 ''.*'' 2>/dev/null'
		let s:cscope_definitions = map(systemlist(s:cscope_cmd), "s:parse(v:val)")
		unlet s:cscope_cmd
  endif
  call s:syntax()
  return s:cscope_definitions
endfunction


" The action to perform on the selected string.
"
" Arguments:
"  a:mode   the mode that has been chosen by pressing <cr> <c-v> <c-t> or <c-x>
"           the values are 'e', 'v', 't' and 'h', respectively
"  a:str    the selected string
function! ctrlp#cscope#accept(mode, str)
  call ctrlp#exit()
  let fullloc = split(a:str, "\t | ")[-1]
  let filename = split(fullloc, ':')[0]
  let fileloc = split(fullloc, ':')[1]
  call ctrlp#acceptfile(a:mode, filename, fileloc)
endfunction

" Give the extension an ID
let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
" Allow it to be called later
function! ctrlp#cscope#id()
  return s:id
endfunction

" Create a command to directly call the new search type
"
" Put this in vimrc
command! CtrlPCscope call ctrlp#init(ctrlp#cscope#id())

" vim:fen:fdl=0:ts=2:sw=2:sts=2
