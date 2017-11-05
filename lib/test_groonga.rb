# groonga (rroonga)を irb でなく ruby programから使ってみるテスト
#2017/10/29(sun)
#irbのチュートリアルのを同じことをやればいいのかな。

require 'groonga'

Groonga::Database.open("/tmp/myhatebu.db")

entries = Groonga["Entries"]

printf("rec num = %d",entries.size)

the_entry = entries.select { |rec| rec.title = "Google"}

puts the_entry
