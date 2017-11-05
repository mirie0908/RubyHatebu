# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

require 'rubygems'
#require 'sinatra'
require 'oauth'
require 'json'
require 'active_support'
require 'active_support/core_ext'

require "./add_entry_to_groonga.rb"



# json file の access key, secretを読み込み

json_file_path = '../mytoken.json'

# 読み込んで
json_data = open(json_file_path) do |io|
  JSON.load(io)
end

printf("access token : %s\n", json_data["token"])
printf("access secret : %s\n", json_data["secret"])

#consumer credential
  @consumer = OAuth::Consumer.new(
    'HAUkmukk8HglPA==', #'5CCsq0IajQmxig==',
    'bTQvbu9rGqls51ql/a9x4fyLpmg=',#'HBnS4U8PoBY6jJj7AnAN6a3Jk64=',
    :site               => '',
    :request_token_path => 'https://www.hatena.com/oauth/initiate',
    :access_token_path  => 'https://www.hatena.com/oauth/token',
    :authorize_path     => 'https://www.hatena.ne.jp/oauth/authorize')
 
#access token
  access_token = OAuth::AccessToken.new(
    @consumer,json_data["token"],json_data["secret"])
  
# はてブ AtomAPI REST API エントリー取得  
#url = "http://api.b.hatena.ne.jp/1/entry" + "?url=http://b.hatena.ne.jp/mirie0908/bookmark"
#url = "http://d.hatena.ne.jp/mirie0908/atom/blog"

# Atom API 最近取得したブックマークの一覧
# ２．次に、feedURLにGETして、エントリ一覧を取得する
url = "http://b.hatena.ne.jp/" + "mirie0908" + "/atomfeed"

response = access_token.request(:get, url)

entries = Hash.from_xml(response.body)["feed"]["entry"]

printf("num of entries : %d\n",entries.count)

#
# ハッシュの配列　の各要素（ハッシュ）を、いくつかのkey項目に絞り、整形し、それを配列に。　＝　②
#filtered_entries = []
for entry in entries do
  #filtered_entries.push({"_key" => entry["link"][0]["href"], "title" => entry["title"], "issued" => entry["issued"]})
  add_entry(entry["link"][0]["href"], entry["title"], entry["issued"])
end

# ②の配列　の各要素（＝ハッシュ）を、jsonに変換し、それを配列に。＝③
# array of hash -> json
#filtered_entries_json = []
#filtered_entries.each { |e_hash| filtered_entries_json.push(e_hash.to_json) }

# ③のjsonの配列　を　ファイルに書き出す
#puts filtered_entries.
#puts filtered_entries_json
#entries_json_file_path = "/tmp/hatebu_entries.json"
#open(entries_json_file_path, 'w') do |io|
#  JSON.dump(filtered_entries_json, io)
#end

# 書き出したjsonのファイルを、groongaに格納
# これは bash から groongaコマンドか。






