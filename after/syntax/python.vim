" Custom syntax highlighting for Jupyter output in Python files

" Define syntax groups for different types of output
syntax match JupyterOutput "^# [^E].*$" contains=@NoSpell
syntax match JupyterError "^# ERROR:.*$" contains=@NoSpell
syntax match JupyterPlot "^# OUTPUT-PLOT:.*$" contains=@NoSpell

" Define highlight groups with colors that work with tokyonight theme
highlight default JupyterOutput ctermfg=244 guifg=#565f89 gui=italic
highlight default JupyterError ctermfg=203 guifg=#f7768e gui=bold
highlight default JupyterPlot ctermfg=158 guifg=#9ece6a gui=bold

" Link to existing highlight groups for better theme integration
highlight default link JupyterOutput Comment
highlight default link JupyterError ErrorMsg
highlight default link JupyterPlot String