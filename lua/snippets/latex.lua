local ok, ls = pcall(require, 'luasnip')
if not ok then return end

local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local sn = ls.snippet_node
local fmt = require('luasnip.extras.fmt').fmt
local rep = require('luasnip.extras').rep

-- Core LaTeX snippets
ls.add_snippets('tex', {
  -- Minimal document skeleton
  s('doc', fmt([[\documentclass{{{cls}}}
% Packages
\usepackage[utf8]{{inputenc}}
\usepackage{{amsmath, amssymb, amsthm}}
\usepackage{{graphicx}}
\usepackage{{hyperref}}

\title{{{title}}}
\author{{{author}}}
\date{{{date}}}

\begin{{document}}
\maketitle

{body}

\end{{document}}
]], {
    cls = i(1, 'article'),
    title = i(2, 'Title'),
    author = i(3, 'Author'),
    date = i(4, '\\today'),
    body = i(0),
  })),

  -- Generic environment: env -> \begin{X} ... \end{X}
  s('env', fmt([[\begin{{{name}}}
  {body}
\end{{{name}}}]], {
    name = i(1, 'environment'),
    body = i(0),
  })),

  -- Equation environment
  s('eq', fmt([[\begin{{equation}}
  {body}
\label{{eq:{label}}}
\end{{equation}}]], {
    body = i(1, 'E = mc^2'),
    label = i(0, 'name'),
  })),

  -- Align environment
  s('align', fmt([[\begin{{align}}
  {body}
\end{{align}}]], {
    body = i(0, 'a &= b \\\\ &= c'),
  })),

  -- Figure environment with includegraphics
  s('fig', fmt([[\begin{{figure}}[{pos}]
  \centering
  \includegraphics[width={width}]{{{path}}}
  \caption{{{caption}}}
  \label{{fig:{label}}}
\end{{figure}}]], {
    pos = i(1, 'htbp'),
    width = i(2, '\\linewidth'),
    path = i(3, 'path/to/image.png'),
    caption = i(4, 'Caption'),
    label = i(0, 'label'),
  })),

  -- Itemize and enumerate
  s('itm', fmt([[\begin{{itemize}}
  \item {one}
  \item {two}
\end{{itemize}}]], {
    one = i(1, 'First item'),
    two = i(0, 'Second item'),
  })),

  s('enum', fmt([[\begin{{enumerate}}
  \item {one}
  \item {two}
\end{{enumerate}}]], {
    one = i(1, 'First'),
    two = i(0, 'Second'),
  })),

  -- Sections
  s('sec', fmt([[\section{{{title}}}\label{{sec:{label}}}]], { title = i(1, 'Title'), label = i(0, 'label') })),
  s('ssec', fmt([[\subsection{{{title}}}\label{{sec:{label}}}]], { title = i(1, 'Title'), label = i(0, 'label') })),
  s('sssec', fmt([[\subsubsection{{{title}}}\label{{sec:{label}}}]], { title = i(1, 'Title'), label = i(0, 'label') })),

  -- Math helpers
  s('frac', fmt([[\frac{{{a}}}{{{b}}}]], { a = i(1, 'a'), b = i(0, 'b') })),
  s('sum', fmt([[\sum_{{{idx}={from}}}^{{{to}}} {expr}]], { idx = i(1, 'i'), from = i(2, '1'), to = i(3, 'n'), expr = i(0, 'a_i') })),
  s('lim', fmt([[\lim_{{{var}\to {to}}} {expr}]], { var = i(1, 'x'), to = i(2, '0'), expr = i(0, '\\infty') })),
  s('pmat', fmt([[\begin{{pmatrix}}
  {body}
\end{{pmatrix}}]], { body = i(0, 'a & b \\\\ c & d') })),

  -- Theorem-like environments
  s('thm', fmt([[\begin{{theorem}}[{name}]
  {body}
\label{{thm:{label}}}
\end{{theorem}}]], { name = i(1), body = i(2, '...'), label = i(0, 'label') })),
  s('lem', fmt([[\begin{{lemma}}[{name}]
  {body}
\label{{lem:{label}}}
\end{{lemma}}]], { name = i(1), body = i(2, '...'), label = i(0, 'label') })),
  s('proof', fmt([[\begin{{proof}}
  {body}
\end{{proof}}]], { body = i(0, '...') })),

  -- Cross-references and citations
  s('lbl', fmt([[\label{{{prefix}:{name}}}]], { prefix = i(1, 'sec'), name = i(0, 'label') })),
  s('ref', fmt([[\ref{{{prefix}:{name}}}]], { prefix = i(1, 'sec'), name = i(0, 'label') })),
  s('eqref', fmt([[\eqref{{eq:{name}}}]], { name = i(0, 'name') })),
  s('cite', fmt([[\cite{{{key}}}]], { key = i(0, 'key') })),

  -- Text formatting
  s('bf', fmt([[\textbf{{{txt}}}]], { txt = i(0, 'bold') })),
  s('itxt', fmt([[\textit{{{txt}}}]], { txt = i(0, 'italic') })),
})

-- Reuse LaTeX snippets for related filetypes
ls.filetype_extend('plaintex', { 'tex' })
ls.filetype_extend('latex', { 'tex' })

