" set this in ftplugins of vimwiki
" inoremap <expr><TAB> pumvisible() ? "\<C-n>" : vimwiki#tbl#kbd_tab()
" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : vimwiki#tbl#kbd_shift_tab()
" change the functionality of tab in insert mode to above for better tab
" completion

" config for path and settings
let wiki = {}
let wiki.path = '~/Documents/vimwiki'
" let wiki.nested_syntaxes = {'python': 'python', 'c++': 'cpp'}
let wiki.syntax = 'markdown'
let wiki.ext = '.md'
let wiki.links_space_char = '_'
" let wiki.auto_tags = 1
let g:vimwiki_list = [wiki]
" let g:vimwiki_list = [{'path': '~/Documents/vimwiki', 'syntax': 'markdown', 'ext': '.md', 'links_space_char': '_'}}]

" make the markdown cooments proper
" let g:vimwiki_filetypes = ['markdown', 'pandoc']


" to make the lists fold
let g:vimwiki_folding = 'list'

" change the symbols of checklist
" let g:vimwiki_listsyms = ' ○◐●✓'
" let g:vimwiki_listsyms = ' ○◐●X'

" to make the conceals look normal, i.e., they are not concealed
let g:vimwiki_conceallevel=0
let g:vimwiki_conceal_onechar_markers=0

" Conceal preformatted text markers. For example, code block
let g:vimwiki_conceal_pre=0



" Setting the value of |g:vimwiki_url_maxsave| to 0 will prevent any link shortening
let g:vimwiki_url_maxsave=0


" to invoke and update diary
command! Diary VimwikiDiaryIndex

augroup vimwikigroup
    autocmd!
    " automatically update links on read diary
    " this is slow
    autocmd BufRead,BufNewFile diary.md VimwikiDiaryGenerateLinks
    " update only on writing the file
    " autocmd BufWrite diary.md VimwikiDiaryGenerateLinks

    " to change the syntax to markdown
    autocmd BufWinEnter *.md setlocal syntax=markdown

    " for spellcheck
    autocmd BufWinEnter *.md setlocal spell

    " for completeopt coc dictionary
    autocmd BufWinEnter *.md setlocal dictionary+=/usr/share/dict/words

    " to correct the comment string
    autocmd BufWinEnter *.md setlocal commentstring=<!--%s-->

    " for every markdown set the file type as vimwiki
    " au BufRead,BufNewFile *.md set filetype=vimwiki
    " list stuff
    " autocmd FileType vimwiki inoremap <silent><buffer> <CR>
              " \ <C-]><Esc>:VimwikiReturn 3 5<CR>
    " autocmd FileType vimwiki inoremap <silent><buffer> <S-CR>
              " \ <Esc>:VimwikiReturn 2 2<CR>

    " sets a visual line to limit the line
    autocmd BufWinEnter *.md setlocal colorcolumn=118

    " automatically pushes the line to new line after 117 characters
    autocmd BufWinEnter *.md setlocal textwidth=117

    " Necessary for vimwiki to work with indentLines extension
    autocmd FileType vimwiki setlocal conceallevel=0 
    autocmd FileType vimwiki setlocal concealcursor=""

augroup end


" create new entry for today
command! CreateEntry VimwikiMakeDiaryNote
" go to the wiki
command! Wiki VimwikiIndex

" replace enter with alt enter to follow/create the link
nmap <A-CR> <Plug>VimwikiFollowLink


" replace tab with f1 to navigate through the links --didn't want to use this
nmap <f1> <Plug>VimwikiNextLink
nmap <S-f1> <Plug>VimwikiPrevLink

" the function to automatically update the todo list
function! UpdateTodo()

python3 << EOF
import re
import os, sys

def new_todo_list(current_file_name, current_file_object, todomd_object):
    current_file_lines = current_file_object.readlines()

    new_todo_file_list = []
    new_todo_line_list = []


    for i, line in enumerate(current_file_lines):

        if re.search(r"^\s*[-*]\s\[[\s.oO]\]", line):
            value = f"{current_file_name}:{i+1} {line}"
            new_todo_file_list.append(value)
            l = f"{current_file_name}:{i+1}"
            new_todo_line_list.append(l)

    todo_file_lines = todomd_object.readlines()
    todo_list = []

    for l in todo_file_lines:
        if current_file_name in l:
            continue
        todo_list.append(l)

    while len(new_todo_file_list) > 0 and new_todo_file_list[0] == "\n":
        new_todo_file_list = new_todo_file_list[1:]

    while len(todo_list) > 0 and todo_list[-1] == "\n":
        todo_list = todo_list[:-1]

    new_todo_file = "".join(todo_list) + "\n" + "".join(new_todo_file_list)
    
    while len(new_todo_file) > 0 and new_todo_file[0] == "\n":
        new_todo_file = new_todo_file[1:]
        
    while len(new_todo_file) > 0 and new_todo_file[-1] == "\n":
        new_todo_file = new_todo_file[:-1]

    return new_todo_file

def todo_driver():
    current_file_name = vim.eval("current_f")
    todomd_name = vim.eval("todo_f")
    path = vim.eval("path")

    if not os.path.exists(path):
        os.mkdir(path)

    if not os.path.exists(todomd_name):
        todomd_object_temp = open(todomd_name, "w")
        todomd_object_temp.close()

    todomd_object = open(todomd_name, "r")
    current_file_object = open(current_file_name, "r")

    new_todo_file = new_todo_list(current_file_name, current_file_object, todomd_object)
    todomd_object.close()
    current_file_object.close()
    
    todomd_object = open(todomd_name, "w")
    todomd_object.write(new_todo_file)
    todomd_object.close()

EOF
let current_f = expand('%:p')
let todo_f = "/home/abhishek/Documents/vimwiki/TODO/general_list.md"
let path = "/home/abhishek/Documents/vimwiki/TODO"

if(current_f =~? path)
  return
endif
if(current_f ==? todo_f)
  return
endif

if bufexists(todo_f)
  execute "e ".todo_f." | up! | bprev"
endif

python3 todo_driver()

endfunction

augroup updatetodo
  autocmd!
  " after writing *.md file, update todo
  au BufWritePost *.md call UpdateTodo()
augroup END


" for spellcheck in the vimwiki. it corrects the spelling by selecting the
" first suggestion. 
" function! FixLastSpellingError()
"   " normal! mm[s1z=`m"
"   normal! mm1z=`m"
" endfunction
" nnoremap <leader>sp :call FixLastSpellingError()<cr>

" to track all the incomplete tasks all over the places in wiki
" function! VimwikiFindIncompleteTasks()
  " lvimgrep /- \[ \]/ %:p
  " lopen
" endfunction

" serches for the tasks and automatically closes the vertical split if there are no tasks
" function! VimwikiFindAllIncompleteTasks()
"   VimwikiSearch /[-*] \[[ ○◐●]\]/
"   lopen
"   if line('$') == 1 && getline(1) == ''
"     bd
"     q
"   endif
" endfunction

" nmap <Leader>wa :vsp <bar> call VimwikiFindAllIncompleteTasks()<CR>
" nmap <Leader>wx :call VimwikiFindIncompleteTasks()<CR>
" nmap <leader>ww <Plug>VimwikiIndex <bar> :vsp <bar> call VimwikiFindAllIncompleteTasks()<CR>
