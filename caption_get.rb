require 'open-uri'
require 'csv'
require 'time'
require 'json'
require 'selenium-webdriver'
require 'byebug'
require 'cgi/escape'


#SdD.W8ZXYBLhMtC

@video_id = ""
@user_email = ""
@user_paswd = ""
@user_pc = ""
@caption_dir = "result/captions/"
@words_dir = "result/words/"
@csv_summary = ["英語", "日本語訳"]

def generate_json_file(mail, password, pc)
  File.open("user.json", 'w') do |file|
  hash = { "user" => { "email" => mail, "password" => password, "user_pc" => pc }}
  str = JSON.dump(hash, file)
  end
end

def read_json_file()
  File.open("user.json") do |file|
  hash = JSON.load(file)
  @user_email = hash["user"]["email"]
  @user_paswd = hash["user"]["password"]
  @user_pc = hash["user"]["user_pc"]
  end
end


def get_user()
  chk = false
  if File.exist?("user.json") == false
    puts "初期登録します"
    puts "下記URLにアクセスし登録する。\n URL：https://accounts.weblio.jp/uwl/register/user-entry"
    while chk == false
      puts "登録したメールアドレスを入力してください."
      mail = gets.chomp
      puts "パスワードを入力してください。"
      password = gets.chomp
      puts "使用しているパソコンがwindowsですか?(y/n)"
      ans_pc = gets.chomp
      if ans_pc == "y"
        pc = "win"
      else
        pc = "mac"
      end
      puts "下記ユーザー情報を登録します。よろしいですか？\n
      ============================\n
      mail:#{mail}\n
      pass:#{password}\n
      use_pc:#{pc}\n
      ============================\n
      よろしいですか？(y/n)"
      admit = gets.chomp
      if admit == "y"
        generate_json_file(mail, password, pc)
        puts "ユーザー情報を登録しました。\n"
        chk = true
      end
    end
  end
  read_json_file()
end

def get_video_id(video_url)
  return video_url.to_s.gsub!(/https:\/\/www.youtube.com\/watch\?v=|\n|\&(.*)/, "")
end

def get_caption_list()
  puts "●字幕を取得したい動画のURLを入力してください"
  video_url = gets
  @video_id = get_video_id(video_url)
  items_result = []
  list_uri = "http://video.google.com/timedtext?type=list&v=#{@video_id}"
  begin
    html = open(list_uri).read
  rescue
    puts "error:youtubeのURLを入力してください。"
    exit!
  end
  item_list = html.split("<track").drop(1)

  item_list.each do |item|
    items = Hash.new
    i = item.split
    i.each do |t|
      summary = t.match(/.*?=/).to_s.delete!("=")
      value = t.match(/=.*/).to_s.gsub!(/=|\\|"|\/|\>|\?/, '')
      unless summary == nil
        items.store(summary, value)
      end
    end
    items_result << items
  end

  if items_result.length == 0
    puts "全力を尽くして探しましたが字幕情報が見つかりませんでした。orz"
    exit!
  else
    puts "やった！字幕情報が#{items_result.length}件ヒットしました。"
    items_result.each do |item|
      puts "\nid:#{item["id"]}"
      puts "言語:#{item["lang_original"]}(#{item["lang_translated"]})"
    end
    puts "\n●id番号を入力してください。"
    req_no = gets.chomp
    items_result.each do |req|
      if req_no == req["id"]
        puts "=======================================\n
        [#{req["lang_translated"]}]の字幕を取得します。\n
        =======================================\n\n"
        return req
      else
      end
    end
    puts "error！！！：idを入力(半角)してください"
  end
end

def get_video_caption(item_result)
  caption_uri = "http://video.google.com/timedtext?hl=#{item_result["lang_code"]}&lang=#{item_result["lang_code"]}&name=#{item_result["name"]}&v=#{@video_id}"
  html = open(caption_uri).read
  #テキスト整理
  html.to_s.gsub!(/&amp;#39;/, "'")
  html.to_s.gsub!(/&amp;quot;/, "\"")
  text = html.gsub!(/<transcript>|<\/transcript>|<text.*?>|<\?.*\?>/, '').split("</text>")
  caption_flie = File.open("#{@caption_dir}caption_#{@video_id}.txt", "w") do |f|
    f.puts(text)
  end
  puts text
  return text
end

def get_video_words(caption)
  #英文から外したい語句を「｜」で仕切って入力する（※正規表現）
  s = caption.to_s.gsub!(/"|,|\[|\]|-|:|\/|\?|\\|!|@/, ' ')
  words = s.to_s.downcase.split(" ").uniq!#重複する単語を削除する
  puts "\n=======================================\n
        抽出単語リスト\n
        =======================================\n
        #{words}\n"
  puts "=======================================\n
        抽出単語数:[#{words.length}]語"
  return words
end


#####seleniumの部分
def page_chk(time,path,option)
    wait = Selenium::WebDriver::Wait.new(:timeout => time)
    wait.until {@driver.find_element(:xpath, "#{path}").displayed?}
    if option == 0
    @driver.find_element(:xpath, "#{path}").click
    elsif option == 2

    end
end

def selenium(words)
  #日時の取得
  puts "英単語検索する？(y/n)※100語5分くらいかかります。"
  ans = gets.chomp
  if ans == "y"
    t = Time.now
    day = t.strftime("%Y%m%d%H%S")

    #変数の宣言
    search_word = []#CSV読み込み格納変数
    file_name = "result/words/output_#{@video_id}.csv"

    #CSV作成
    #, :encoding => "SJIS"
    CSV.open(file_name, 'w') do |csv|
      if @user_pc == "win"
        @csv_summary.each do |t|
          t.to_s.encode(Encoding::SJIS, :invalid => :replace, :undef => :replace)
        end
        csv << @csv_summary

      elsif @user_pc == "mac"
        csv << @csv_summary
      end
    end

    #Selenium
    @driver = Selenium::WebDriver.for :chrome
    @driver.navigate.to"https://ejje.weblio.jp/"

    #ターボモード
    @driver.find_element(:xpath, '//*[@id="turbo"]/img').click#ターボON
    page_chk(10,  '//*[@id="simplemodal-data"]/div/div[6]/a[2]', 0)
    @driver.find_element(:xpath, '//*[@id="modal-mail"]').send_key(@user_email)#メールアドレス
    @driver.find_element(:xpath, '//*[@id="modal-password"]').send_key(@user_paswd)#パスワード
    @driver.find_element(:xpath, '//*[@id="simplemodal-data"]/div/div[6]/a[1]').click#ログイン
    sleep 3

    words.each do |word|
      #関数内変数
      search_word = nil
      results = []

      #検索ボックス
      @driver.find_element(:xpath, '//*[@id="searchWord"]').clear
      @driver.find_element(:xpath, '//*[@id="searchWord"]').send_keys(word)
      @driver.find_element(:xpath, '//*[@id="headFixBxTR"]/input').click
      begin

        #ここいらない？
        #page_chk(2, '//*[@id="turboContents"]/div/div[1]', 1)#検索結果チェック

        search_word = @driver.find_element(:xpath, '//*[@id="turboContents"]/div/div[1]').text#検索ワードのxpath
        @driver.find_elements(:class, 'level0').each do |element|#lvlB：検索語句の詳細
          results << element.text.encode(Encoding::SJIS, :invalid => :replace, :undef => :replace)
        end
      rescue
        search_word = word
        if results == nil
          results << "検索結果なし"
        end
      end

      puts ""
      puts "＝＝＝＝＝＝＝＝＝＝＝＝"
      puts "検索結果：#{word}"
      puts "＝＝＝＝＝＝＝＝＝＝＝＝"
      puts results

      #CSV書き込み
      CSV.open(file_name,'a') do |result|
        enter = []
        if @user_pc == "win"
        enter << search_word.encode(Encoding::SJIS, :invalid => :replace, :undef => :replace)
      elsif @user_pc == "mac"
        enter << search_word
      end

        results.each do |jpn|
          enter << jpn.gsub(/(\r\n?|\n)/,",")
        end
        if @user_pc == "win"
        result << enter#.encode(Encoding::SJIS, :invalid => :replace, :undef => :replace)
        elsif @user_pc == "mac"
          result << enter
        end
      end
    end
  end
end

def main
get_user()
target = get_caption_list()
caption = get_video_caption(target)
words = get_video_words(caption)
selenium(words)
puts "======================END========================"
end

main()
__END__
