" ============================================================================
" File:        persist.vim
" Description: List output from ls, marks, or registers in a persistent buffer
" Author:      Kenneth Cheng <me@chtennek.com>
" License:     Vim license
" Website:     http://chtennek.github.com/vim-persist/
" Version:     0.1
" Note:        This plugin was heavily adapted from the 'tagbar' and
"              'vim-signature' plugins.
"
" Original taglist copyright notice:
"              Permission is hereby granted to use and distribute this code,
"              with or without modifications, provided that this copyright
"              notice is copied with it. Like anything else that's free,
"              taglist.vim is provided *as is* and comes with no warranty of
"              any kind, either expressed or implied. In no event will the
"              copyright holder be liable for any damamges resulting from the
"              use of this software.
" ============================================================================

" Initialization {{{1

" Basic init {{{2

let g:loaded_persist = 1

let s:autocommands_done = 0

" s:CreateAutocommands() {{{2
function! s:CreateAutocommands()
    augroup PersistAutoCmds
        autocmd!
        autocmd BufEnter   __Persist__ nested call s:QuitIfOnlyWindow()
        "autocmd BufUnload  __Persist__ call s:CleanUp()

        " :buffers
        autocmd BufCreate,BufDelete,BufFilePost,TabEnter * call
                    \ s:AutoUpdate()
        " :marks
        " :registers
        autocmd CursorHold * call
                    \ s:AutoUpdate()
    augroup END

    let s:autocommands_done = 1
endfunction

" Window management {{{1
" s:ToggleWindow() {{{2
function! s:ToggleWindow()
    let persistwinnr = bufwinnr("__Persist__")
    if persistwinnr != -1
        call s:CloseWindow()
        return
    endif

    call s:OpenWindow()
endfunction

" s:OpenWindow() {{{2
function! s:OpenWindow()
    " If the window is already open don't do anything
    if bufwinnr('__Persist__') != -1
        return
    endif

    let eventignore_save = &eventignore
    set eventignore=all

    exec 'silent keepalt botright vertical ' . g:persist_width . 'split ' . '__Persist__'

    let &eventignore = eventignore_save

    call s:InitWindow()

    wincmd p
endfunction

" s:InitWindow() {{{2
function! s:InitWindow()
    setlocal noreadonly " in case the "view" mode is used
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted
    setlocal nomodifiable
    setlocal filetype=persist
    setlocal nolist
    setlocal nonumber
    setlocal nowrap
    setlocal winfixwidth
    setlocal textwidth=0
    setlocal nocursorline
    setlocal nocursorcolumn

    if exists('+relativenumber')
        setlocal norelativenumber
    endif

    setlocal nofoldenable
    setlocal foldcolumn=0
    " Reset fold settings in case a plugin set them globally to something
    " expensive. Apparently 'foldexpr' gets executed even if 'foldenable' is
    " off, and then for every appended line (like with :put).
    setlocal foldmethod&
    setlocal foldexpr&

    setlocal statusline=vim-persist

    " Script-local variable needed since compare functions can't
    " take extra arguments
    let s:is_maximized = 0
    let s:short_help   = 1

    let cpoptions_save = &cpoptions
    set cpoptions&vim

    if !s:autocommands_done
        call s:CreateAutocommands()
    endif

    let &cpoptions = cpoptions_save
endfunction

" s:CloseWindow() {{{2
function! s:CloseWindow()
    let persistwinnr = bufwinnr('__Persist__')
    if persistwinnr == -1
        return
    endif

    let persistbufnr = winbufnr(persistwinnr)

    if winnr() == persistwinnr
        if winbufnr(2) != -1
            " Other windows are open, only close the persist one
            close
            wincmd p
        endif
    else
        " Go to the persist window, close it and then come back to the
        " original window
        let curbufnr = bufnr('%')
        execute persistwinnr . 'wincmd w'
        close
        " Need to jump back to the original window only if we are not
        " already in that window
        let winnum = bufwinnr(curbufnr)
        if winnr() != winnum
            exe winnum . 'wincmd w'
        endif
    endif
endfunction

" Helper functions {{{1
" s:CleanUp() {{{2
function! s:CleanUp()
    silent autocmd! PersistAutoCmds

    unlet s:is_maximized
    unlet s:short_help
endfunction

" s:QuitIfOnlyWindow() {{{2
function! s:QuitIfOnlyWindow()
    " Before quitting Vim, delete the persist buffer so that
    " the '0 mark is correctly set to the previous buffer.
    if winbufnr(2) == -1
        " Check if there is more than one tab page
        if tabpagenr('$') == 1
            bdelete
            quit
        else
            close
        endif
    endif
endfunction

" s:AutoUpdate() {{{2
function! s:AutoUpdate()
    " Don't do anything if persist is not open
    let persistwinnr = bufwinnr('__Persist__')
    if persistwinnr == -1
        return
    endif

    " Display the persist content
    call s:RenderContent()
endfunction

" s:IsValidFile() {{{2
function! s:IsValidFile(fname)
    if a:fname == ''
        return 0
    endif
    if !filereadable(a:fname)
        return 0
    endif
    return 1
endfunction

" Display {{{1
" s:RenderContent() {{{2
function! s:RenderContent()
    redir => content
    silent echo "--- Marks ---"
    silent exec 'marks'
    silent echo "\n--- Buffers ---"
    silent exec 'buffers'
    silent echo ""
    silent exec 'registers'
    redir END

    let marklistwinnr = bufwinnr('__Persist__')

    if &filetype == 'persist'
        let in_marklist = 1
    else
        let in_marklist = 0
        let prevwinnr = winnr()
        execute marklistwinnr . 'wincmd w'
    endif

    let lazyredraw_save = &lazyredraw
    set lazyredraw
    let eventignore_save = &eventignore
    set eventignore=all
    setlocal modifiable

    silent %delete _
    silent 0put = content
    put = 'Hi'

    " Delete empty lines at the end of the buffer
    for linenr in range(line('$'), 1, -1)
        break
        if getline(linenr) =~ '^$'
            execute 'silent ' . linenr . 'delete _'
        else
            break
        endif
    endfor

    " Make sure as much of the Marklist content as possible is shown in the
    " window by jumping to the top after drawing
    execute 'normal gg'

    setlocal nomodifiable
    let &lazyredraw  = lazyredraw_save
    let &eventignore = eventignore_save

    if !in_marklist
        execute prevwinnr . 'wincmd w'
    endif
endfunction

" Autoload functions {{{1
function! persist#ToggleWindow()
    call s:ToggleWindow()
endfunction

function! persist#OpenWindow()
    call s:OpenWindow()
endfunction

function! persist#CloseWindow()
    call s:CloseWindow()
endfunction

function! persist#RefreshWindow()
    call s:RenderContent()
endfunction

" Automatically open Persist if one of the open buffers contains a supported
" file
function! persist#autoopen()
    for bufnr in range(1, bufnr('$'))
        if buflisted(bufnr)
            if s:IsValidFile(bufname(bufnr))
                call s:OpenWindow()
                return
            endif
        endif
    endfor
endfunction

" Modeline {{{1
" vim: ts=8 sw=4 sts=4 et foldenable foldmethod=marker foldcolumn=1
