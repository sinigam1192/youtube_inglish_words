require 'open-uri'
require 'csv'
require 'time'
require 'json'
require 'selenium-webdriver'
require 'byebug'
require 'cgi/escape'
require 'nokogiri'

#SdD.W8ZXYBLhMtC

@video_id = ""
@user_pc = ""
@caption_dir = "result/captions/"
@words_dir = "result/words/"
@csv_summary = ["English", "Japanese"]
@uri_count = 0

def generate_json_file(pc)
  File.open("user.json", 'w') do |file|
  hash = {"user_pc" => pc }
  str = JSON.dump(hash, file)
  end
end

def read_json_file()
  File.open("user.json") do |file|
  hash = JSON.load(file)
  @user_pc = hash["user"]["user_pc"]
  end
end


def get_user()
  chk = false
  if File.exist?("user.json") == false
    while chk == false
      puts "使用しているパソコンがwindowsですか?(y/n)"
      ans_pc = gets.chomp
      if ans_pc == "y"
        pc = "win"
      else
        pc = "mac"
      end
      puts "下記情報で保存します。\n
      ============================\n
      use_pc:#{pc}\n
      ============================\n
      よろしいですか？(y/n)"
      admit = gets.chomp
      if admit == "y"
        generate_json_file(pc)
        puts "保存しました。\n"
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

def count_chk()
  @uri_count = @uri_count + 1
  if @uri_count == 15
    sleep 10
     @uri_count = 0
   end
 end

def get_meaning_word(target_word)
  count_chk()
  req_url =  "https://ejje.weblio.jp/content/#{target_word}"
  result = []
  begin
    html = open(req_url).read
    doc = Nokogiri::HTML(html)
    text = doc.css('.midashigo/text()').first.content
  result << text
  word_content = doc.css('.Kejje') #意味全部のHTML
  means = word_content.css('.level0', '.KejjeYr')#品詞、日本語訳、例文のHTML
  cntents = word_content.css('.qotC')#熟語？体力あったら抜く

  means.each do |mean|
    if mean.attributes["class"].to_s == "level0"#品詞、日本語訳のHTML
      if mean.css('.KnenjSub').to_s != ""#品詞
        part = mean.css('.KnenjSub').text
        result << "【#{part}】"
      elsif mean.css('.lvlB').to_s != ""#日本語訳
        content = mean.css('.lvlB').text
        result << content
      end

    elsif mean.attributes["class"].to_s == "KejjeYr"#例文のHTML
      ex_sentences = mean.css('.KejjeYrLn.rmvDots')
      ex_sentences.each do |ex_sentence|
        en = ex_sentence.css('.KejjeYrEn').text#例文英語
        ja = ex_sentence.css('.KejjeYrJp').text#例文日本語訳
        result << "【例文】#{en} 【意味】#{ja}"
      end
    end
  end
rescue
  text = [target_word, "検索情報なし"]
  result << text
end
  return result
end

def create_csv()
  CSV.open("words_#{@video_id}.csv",'w') do |csv|
    if @user_pc == "win"
      @csv_summary.each do |t|
        t.to_s.encode(Encoding::SJIS, :invalid => :replace, :undef => :replace)
      end
      csv << @csv_summary
    elsif @user_pc == "mac"
      csv << @csv_summary
    end
  end

end
def enter_csv(result)
  #CSV書き込み
  CSV.open("words_#{@video_id}.csv",'a') do |csv|
    if @user_pc == "win"
      csv << result#.encode(Encoding::SJIS, :invalid => :replace, :undef => :replace)
    elsif @user_pc == "mac"
      csv << result
    end
  end
end


def main
get_user()
target = get_caption_list()
caption = get_video_caption(target)
words = get_video_words(caption)
create_csv()
words.each do |word|
  result = get_meaning_word(word)
  enter_csv(result)
end

puts "======================END========================"
end

main()
__END__
