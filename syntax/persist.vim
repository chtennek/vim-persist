if exists("b:current_syntax")
  finish
endif

syntax match PersistText   '^ *\S\{1,2\} '
syntax match PersistTitles '--- \w* ---'

highlight default PersistTitles         guifg=Green ctermfg=Green
highlight default PersistText           guifg=Blue  ctermfg=Blue

let b:current_syntax = "persist"

" vim: ts=8 sw=4 sts=4 et foldenable foldmethod=marker foldcolumn=1
