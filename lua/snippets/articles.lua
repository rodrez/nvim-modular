local ls = require 'luasnip'
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local f = ls.function_node

ls.add_snippets('all', {
  s('article', {
    t {
      "import { ArticleLayout } from '@/components/article-layout'",
      '',
      'export const article = {',
      "  author: '",
    },
    i(1, 'Kiyotaka'),
    t { "',", "  date: '" },
    i(2, ''),
    t { "',", "  title: '" },
    i(3, ''),
    t { "',", '  draft: true,', "  description: '" },
    i(4, 'Description goes here'),
    t {

      "',",

      '}',
      '',
      'export const metadata = {',

      '  title: article.title,',
      '  description: article.description,',
      '}',
      '',
      'export default (props) => <ArticleLayout article={article} {...props} />',
    },
  }),
})
