require "csv"
require "time"
require "byebug"
require "selenium-webdriver"

def page_chk(time,path,option)
    wait = Selenium::WebDriver::Wait.new(:timeout => time)
    wait.until {@driver.find_element(:xpath, "#{path}").displayed?}
    if option == 0
    @driver.find_element(:xpath, "#{path}").click
    end
end

#日時の取得
t = Time.now
day = t.strftime("%Y%m%d%H%S")

#変数の宣言
@words = []
search_word = []#CSV読み込み格納変数
file_name = "output/output_#{day}.csv"

#CSV作成
CSV.open(file_name, 'w') do |csv|
  csv << ["英語", "日本語訳"]
end

#Selenium
@driver = Selenium::WebDriver.for :chrome
@driver.navigate.to"https://ejje.weblio.jp/"

#ターボモード
@driver.find_element(:xpath, '//*[@id="turbo"]/img').click#ターボON
page_chk(10,  '//*[@id="simplemodal-data"]/div/div[6]/a[2]', 0)
#@driver.find_element(:xpath, '//*[@id="simplemodal-data"]/div/div[6]/a[2]').click#ログイン画面へ
@driver.find_element(:xpath, '//*[@id="modal-mail"]').send_key("yuie7893@gmail.com")#メールアドレス
@driver.find_element(:xpath, '//*[@id="modal-password"]').send_key("yuie7893")#パスワード
@driver.find_element(:xpath, '//*[@id="simplemodal-data"]/div/div[6]/a[1]').click#ログイン
sleep 3
#csv読み込み
CSV.foreach("input.csv", headers: true) do |word|

  #関数内変数
  search_word = ""
  results = []


  @driver.find_element(:xpath, '//*[@id="searchWord"]').clear
  @driver.find_element(:xpath, '//*[@id="searchWord"]').send_keys(word)
begin
  page_chk(1, '//*[@id="turboContents"]/div/div[1]', 1)
  search_word = @driver.find_element(:xpath, '//*[@id="turboContents"]/div/div[1]').text#検索ワードのxpath
  @driver.find_elements(:class, 'level0').each do |element|#lvlB
    results << element.text
  end
rescue
  search_word = word
  results << "検索結果なし"
end

    puts ""
    puts "＝＝＝＝＝＝＝＝＝＝＝＝"
    puts "検索結果：#{word}"
    puts "＝＝＝＝＝＝＝＝＝＝＝＝"
    puts results

    #CSV書き込み
  CSV.open(file_name,'a') do |result|
    enter = []
    enter << search_word
    results.each do |jpn|
      enter << jpn.gsub(/(\r\n?|\n)/,",")
    end
    result << enter
  end
end

#CSV初期化
CSV.open("input.csv", "w") do |result|
  result << ["英単語"]
end
