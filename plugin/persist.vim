if &cp || exists('g:loaded_persist')
    finish
endif

" Basic init {{{1

if !exists('g:persist_width')
    let g:persist_width = 40
endif


" Commands {{{1

command! -nargs=0 PersistToggle  call persist#ToggleWindow()
command! -nargs=0 PersistOpen    call persist#OpenWindow()
command! -nargs=0 PersistClose   call persist#CloseWindow()
command! -nargs=0 PersistRefresh call persist#RefreshWindow()

" Modeline {{{1
" vim: ts=8 sw=4 sts=4 et foldenable foldmethod=marker foldcolumn=1
