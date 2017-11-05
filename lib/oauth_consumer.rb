# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.
# 2017/11/5(sun)  consumer key, secret を外だしする。

require 'rubygems'
require 'sinatra'
require 'oauth'
require 'erb'
require 'json'

require 'rexml/document'

 
set :sessions, true

# enable :sessions

# これのかわりにRackのミドルウエアを使う。2014/9/8
use Rack::Session::Pool, :expire_after => 2592000
 
before do
  
  # json file の consumer key, secretを読み込み
  consumer_json_file_path = '../myconsumertoken.json'

  # 読み込んで
  consumer_json_data = open(json_file_path) do |io|
    JSON.load(io)
  end
  
  @consumer = OAuth::Consumer.new(
    consumer_json_data["consumer_key"],     
    consumer_json_data["consumer_secret"], 
    :site               => '',
    :request_token_path => 'https://www.hatena.com/oauth/initiate',
    :access_token_path  => 'https://www.hatena.com/oauth/token',
    :authorize_path     => 'https://www.hatena.ne.jp/oauth/authorize')
end
 
get '/' do
  erb :index
end
 
# リクエストトークン取得から認証用URLにリダイレクトするためのアクション
get '/oauth' do
  # リクエストトークンの取得
  request_token = @consumer.get_request_token(
    { :oauth_callback => 'http://localhost:4567/oauth_callback' },
  #{ :oauth_callback => 'http://hatenadiarynb.herokuapp.com/oauth_callback' },
  #  :scope          => 'read_public,write_public')
    :scope          => 'read_private,write_private')
 
  # セッションへリクエストトークンを保存しておく
  session[:request_token] = request_token.token
  session[:request_token_secret] = request_token.secret
  

  
 
  # 認証用URLにリダイレクトする
  redirect request_token.authorize_url
end
 
# 認証からコールバックされ、アクセストークンを取得するためのアクション
get '/oauth_callback' do
  request_token = OAuth::RequestToken.new(
    @consumer,
    session[:request_token],
    session[:request_token_secret])
 
  # リクエストトークンとverifierを用いてアクセストークンを取得
  access_token = request_token.get_access_token(
    {},
    :oauth_verifier => params[:oauth_verifier])
 
  session[:request_token] = nil
  session[:request_token_secret] = nil
 
  # アクセストークンをセッションに記録しておく
  session[:access_token] = access_token.token
  session[:access_token_secret] = access_token.secret
  
  
  #2017/10/21 json に保存する
  json_file_path = '../mytoken.json'

  # 読み込んで
  json_data = open(json_file_path) do |io|
    JSON.load(io)
  end
  
  printf("current token : %s", json_data["token"])
  printf("current secret : %s", json_data["secret"])

  # 更新して
  json_data['token'] = access_token.token
  json_data['secret'] = access_token.secret
  
  printf("new token : %s", json_data["token"])
  printf("new secret : %s", json_data["secret"])

  # 保存する
  open(json_file_path, 'w') do |io|
    JSON.dump(json_data, io)
  end
  
  
 
  erb :oauth_callback, :locals => { :access_token => access_token }
  
end

get '/list' do
  access_token = OAuth::AccessToken.new(
    @consumer,session[:access_token],session[:access_token_secret])
  
  # access_tokenをつかって、一覧取得のAPIを利用
  response = access_token.request(:get, 'http://d.hatena.ne.jp/mirie0908/atom/blog')

  if response
    data = response.body
  else
    data = ""
  end
 
  doc = REXML::Document.new(data)
  
  if doc != nil
   # 取得した日付とエントリー本文はグローバル変数の代わりに連想配列 session に蓄える
   #$published = doc.elements.each('feed/entry/published') {|element| element.text}
   #$contents = doc.elements.each('feed/entry/content') {|element| element.text}
   session[:published] = doc.elements.each('feed/entry/published') {|element| element.text}
   session[:contents] = doc.elements.each('feed/entry/content') {|element| element.text}
  end

  #erb :listview_1, :locals => { :data => $published }
  erb :listview_1, :locals => { :data => session[:published] }
  
end

get '/atomAPIlist' do
  auth = Atompub::Auth::Wsse.new :username => 'mirie0908', :password => 'api_key'
  client = Atompub::HatenaClient.new :auth => auth
  service = client.get_service 'http://d.hatena.ne.jp/%s/atom' % 'mirie0908'
  collection_uri = service.workspace.collections[1].href

  entry = Atom::Entry.new(
    :title => 'My Entry Title',
    :updated => Time.now
  )

entry.content = <<EOF
entry conents..
EOF

  puts client.create_entry collection_uri, entry
  
end

get '/honbun' do
  idx = params[:idx]
  erb :entryview, :locals => { :idx => idx }
end
 
__END__
 
@@ index
<p><a href="/oauth">Hatena</a></p>
 
<% if session[:access_token] && session[:access_token_secret] %>
  <a href="/hello">hello oauth api.</a>
  <p><a href="/list">投稿一覧</a>
  <p><a href="/AtomAPIlist">AtomAPIでの投稿一覧</a>
<% end %>
 
@@ oauth_callback
<p>success getting access_token.</p>
 
<p>your access token is below.</p>
 
<dl>
  <dt>access_token</dt>
  <dd><%= access_token.params[:oauth_token] %></dd>
  <dt>access_token_secret</dt>
  <dd><%= access_token.params[:oauth_token_secret] %></dd>
</dl>
 
<a href="/">back to top</a>
    

@@ entryview
<p>entry view </p>

<% if session[:contents] != nil %>
  <% session[:contents].each_with_index do |e,index| %> 

     <% if index.to_s == idx.to_s then %>
        本文＝ <%= e.text %> <p>
     <% end %>
  <% end %> 
<% else %>
  エントリがありません。<p>
<% end %> 

<p>
<a href="/">back to top</a>



