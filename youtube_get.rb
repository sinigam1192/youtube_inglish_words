#OAuth 2.0の承認が必要
#その承認はローカルファイルの有無を確認する。
#該当するファイルが存在しない場合、スクリプトはブラウザを起動して応答を待ち、その後返された認証情報をローカルに保存します。
#https://qiita.com/eggman/items/b254612d36eba4370a17
#
#パイソンだけど。。。
#get_access_token()
#と
#refresh_token()

#まずはURLから動画タイトルを取得してみよう！
#~手順~
#１．google使用設定を行う※ログインできる仕組みを作成する
#２．googleページからidとか取得する（Google Developers Console）
#３．URLから動画データを取得できるか、
#４．翻訳のgoogle APIがあるっぽい
#５．seleniumである必要なし？
#youtubeインスタンスがyoutubeDBとの通信ができるメソッドを持っている
#APIはこのようなインスタンスメソッドにある相互受け渡しを行うメソッドがあるためそれを活用するとOK！
#参考サイト：https://whatsupguys.net/programming-learning-110/

require 'google/apis/youtube_v3'
require 'open-uri'
require 'json'
require 'byebug'

oauthuri = "https://accounts.google.com/o/oauth2/auth?client_id=[client_id]&redirect_uri=[redirect_uri]&scope=https://www.googleapis.com/auth/youtube.force-ssl&response_type=code&access_type=offline"

#APIキー：youtube_Data_api_v3

API_KEY = 'AIzaSyCM1X5xj2VcI0T2I1vHgU34d6jtnRk4-VI'
YOUTUBE_API_SERVICE_NAME = 'youtube'
YOUTUBE_API_VERSION = 'v3'
#youtube = Google::Apis::YoutubeV3::YouTubeService.new(
#  :key => API_KEY
#  :authorization => nil,
#  :application_name => $PROGRAM_NAME,
#  :application_version => '1.0.0'
#  )
#)

def get_authenticated_service
  client = Google::APIClient.new(
    :application_name => $PROGRAM_NAME,
    :application_version => '1.0.0'
  )
  youtube = client.discovered_api(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION)

  file_storage = Google::APIClient::FileStorage.new("#{$PROGRAM_NAME}-oauth2.json")
  if file_storage.authorization.nil?
    client_secrets = Google::APIClient::ClientSecrets.load
    flow = Google::APIClient::InstalledAppFlow.new(
      :client_id => client_secrets.client_id,
      :client_secret => client_secrets.client_secret,
      :scope => [YOUTUBE_SCOPE]
    )
    client.authorization = flow.authorize(file_storage)
  else
    client.authorization = file_storage.authorization
  end

  return client, youtube
end


def main()

#searchモジュール
youtube_search_list = youtube.list_searches("id,snippet", type: "video", q: "夏実萌恵", max_results: 1)

text = ""

youtube_search_list.items.each do |item|
  #検索内容
  title = item.snippet.title
  video_id = item.id.video_id

  #JSONファイルを取得する
  #字幕の各言語のIDを取得する
  caption_id = []
  uri = "https://www.googleapis.com/youtube/v3/captions?part=snippet&videoId=#{video_id}&key=#{youtube.key}"
  request = open(uri)
  lang_data = JSON.load(request)
  lang_data["items"].each do |item|
    if item["snippet"]["language"] == "ja" && item["snippet"]["trackKind"] == "standard"
      caption_id = item["id"]
      caption_uri = "https://www.googleapis.com/youtube/v3/captions/#{caption_id}?tfmt=ttml&key=#{youtube.key}"

      byebug

      test = open(caption_uri, {:http_basic_authentication => ["1064989834175-ivgpekij5ap8fb9uc338qh9sq4sl9gm5.apps.googleusercontent.com", "nU6Mi4ujsJs9mBr7dMv5JW9r"]})
      puts test
      #http = Net::HTTP.new(caption_uri.host, uri.port)
      #http.use_ssl = uri.scheme === "https"

      #hraders = {"Authorization" => " Bearer  #{access_token}"}
      #response = http.get(uri.path, headers)
      #authentication = "1064989834175-ivgpekij5ap8fb9uc338qh9sq4sl9gm5.apps.googleusercontent.com"
      #request_app = open(caption_uri)#, authentication)
      #puts request_app
    end
    end

  text +=<<~EOS
  タイトル：#{title}
  URL：https://www.youtube.com/watch?v=#{video_id}
  EOS
end
puts text
end
