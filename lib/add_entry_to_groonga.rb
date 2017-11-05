# function 
# 
require 'groonga'

Groonga::Database.open("/tmp/myhatebu.db")

entries = Groonga["Entries"]

@entries = entries

def add_entry(url_key, title, issued)
  entry = @entries[url_key] || @entries.add(url_key, :title => title, :issued => issued)
end
