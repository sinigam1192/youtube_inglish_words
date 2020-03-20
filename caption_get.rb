require "byebug"
require 'open-uri'

@video_id = ""

def get_video_id(video_url)
  return video_url.to_s.gsub!(/https:\/\/www.youtube.com\/watch\?v=|\n|\&(.*)/, "")
end

def get_caption_list()
  puts "字幕を取得したい動画のURLを入力してください"
  target_url = "https://www.youtube.com/watch?v=ry3Tupx4BL4&list=RDzEPOTM48Q48&index=23"
  @video_id = get_video_id(target_url)
  items_result = []
  list_uri = "http://video.google.com/timedtext?type=list&v=#{@video_id}"
  html = open(list_uri).read
  item_list = html.split("<track ").drop(1)

  item_list.each do |item|
    items = Hash.new
    h = item.split
    h.each do |t|
      sumay = t.match(/.*?=/).to_s.delete!("=")
      value = t.match(/=.*/).to_s.gsub!(/=|\\|"|\/|\>|/, '')
      unless sumay == nil
        items.store(sumay, value)
      end
    end
    items_result << items
  end

  if items_result.length == 0
  puts "字幕情報がありませんでした。"
  else
  puts "字幕情報が#{items_result.length}件ヒットしました。"
  items_result.each do |item|
    puts "\nid:#{item["id"]}"
    puts "言語:#{item["lang_original"]}(#{item["lang_translated"]})"
  end
  puts "id番号を入力してください。"
end
  return items_result
end

def get_video_caption(item_result)
  caption_uri = "http://video.google.com/timedtext?hl=#{item_result["lang_code"]}&lang=#{item_result["lang_code"]}&name=#{item_result["name"]}&v=#{@video_id}"
  html = open(caption_uri).read
  text = html.gsub!(/<transcript>|<\/transcript>|<text.*?>|<\?.*\?>/, '').split("</text>")
  puts text
end

def get_translate_words
end
test = get_caption_list()
