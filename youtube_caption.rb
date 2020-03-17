#シナリオ
#1.google/youtube_data_api_v3を使用する
#2.動画に紐づくcaption_idを取得する
#3.caption_idをキーにしてcaptionのダウンロードを行う
#4.3のとき、Oauth2.0承認が必要？
#5.APIキーで取得できるものはプライベート ユーザーデータではない情報であること。
#6.プライベート ユーザーデータの場合、AOuth2.0承認が必要で、captionはプライベートに含まれる

require 'google/apis/youtube_v3'
require 'open-uri'
require 'json'
require 'byebug'
require "net/http"

API_KEY = 'AIzaSyCM1X5xj2VcI0T2I1vHgU34d6jtnRk4-VI'
YOUTUBE_API_SERVICE_NAME = 'youtube'
YOUTUBE_API_VERSION = 'v3'
@token = "4/xgEDZxsjwzg943VfcsrozdULlRG3_X3WJyoRrtQ16-TfGygIFS6PBIE"
youtube = Google::Apis::YoutubeV3::YouTubeService.new
youtube.key = API_KEY
#outh_uri = "https://accounts.google.com/o/oauth2/auth?client_id=#{client_id}&redirect_uri=#{redirect_uri}&scope=https://www.googleapis.com/auth/youtube.force-ssl&response_type=code&access_type=offline"

def get_access_token()
  url = "https://accounts.google.com/o/oauth2/token"
end





def get_caption_param(youtube)
  text = ""
  #検索情報 q:検索ワード, max_results:検索件数
  youtube_search_list = youtube.list_searches("id,snippet", type: "video", q: "bad guy", max_results: 1)


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
      #字幕情報が英語のcaption情報を取得する
      if item["snippet"]["language"] == "en" && item["snippet"]["trackKind"] == "standard"
        caption_id = item["id"]
        caption_uri = "https://www.googleapis.com/youtube/v3/captions/#{caption_id}?tfmt=ttml&key=#{youtube.key}"

        text += <<~EOS

        タイトル：#{title}
        URL：https://www.youtube.com/watch?v=#{video_id}
        EOS
        puts caption_id
        puts item
        byebug
      end
    end
        res = open("https://www.googleapis.com/youtube/v3/captions/#{caption_id}?key=#{youtube.key}",
          "Authorization" => "bearer #{@token}")
          puts res


    puts text
    #ここでAOuth2.0の承認が必要 Unauthorized (Google::Apis::AuthorizationError)

    #caption_request = youtube.download_caption(caption_id)
    puts caption_request
  end
end

get_caption_param(youtube)
