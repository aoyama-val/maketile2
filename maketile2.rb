# 任意の画像をLeaflet用のタイル化するスクリプト

require "erb"

class MakeTile
  def execute(cmd)
    puts "実行: #{cmd}"
    system(cmd)
  end

  # numがdenomの倍数になるように切り上げる
  # > roundup(100, 256)
  # => 256
  # > roundup(300, 256)
  # => 512
  def roundup(num, denom)
    return (num.to_f / denom).ceil * denom
  end

  # 指定画像を縦横256の倍数になるよう透明余白を追加する（ファイルを上書き保存する）
  def splice(file, tile_size)
    puts "\n#splice"
    puts "指定画像を縦横256の倍数になるよう透明余白を追加する（ファイルを上書き保存する）"

    orig_w = `identify -format %w #{file}`.to_i
    orig_h = `identify -format %h #{file}`.to_i

    puts "orig_w = #{orig_w}"
    puts "orig_h = #{orig_h}"

    # 縦横256の倍数になるように丸めたサイズ
    spliced_w = roundup(orig_w, tile_size)
    spliced_h = roundup(orig_h, tile_size)
    padding_w = spliced_w - orig_w
    padding_h = spliced_h - orig_h

    puts "spliced_w = #{spliced_w}"
    puts "spliced_h = #{spliced_h}"
    puts "padding_w = #{padding_w}"
    puts "padding_h = #{padding_h}"

    # 縦横256の倍数になるよう透明余白を追加
    # -splice                      余白追加
    # -background transparent      背景色は透明
    # -gravity southeast           余白の位置は右下
    execute("convert #{file} -background transparent -gravity southeast -splice #{padding_w}x#{padding_h} #{file}")
  end

  def make(file, tile_dir: "tile", min_zoom: 8, max_zoom: nil, tile_size: 256, debug: false, tmp_dir: "./tmp")
    puts "\n#make"
    puts "作成開始"

    Dir.mkdir(tmp_dir) unless Dir.exist?(tmp_dir)

    # 元ファイルのサイズ
    orig_w = `identify -format %w #{file}`.to_i
    orig_h = `identify -format %h #{file}`.to_i
    orig_size = [orig_w, orig_h].max

    base = (Math.log(orig_size) / Math.log(2)).ceil
    if max_zoom.nil?
      # max_zoom
      max_zoom = base
    end

    puts "orig_w    = #{orig_w}"
    puts "orig_h    = #{orig_h}"
    puts "orig_size = #{orig_size}"
    puts "base      = #{base}"
    puts "max_zoom  = #{max_zoom}"

    # 既存のタイルディレクトリを削除
    execute("rm -rf #{tile_dir}")

    # 各ズームのタイル生成
    (min_zoom..max_zoom).each do |z|
      puts "\nz = #{z}"
      execute("mkdir -p #{tile_dir}/#{z}")
      tmp_z = "#{tmp_dir}/tmp_#{z}.png"
      scale = 2.0 ** (z - base)

      # リサイズ
      execute("convert #{file} -resize #{scale * 100}% #{tmp_z}")

      # 256の倍数になるよう透明余白追加
      splice(tmp_z, tile_size)

      # 256x256で切り出す
      # -crop   切り出す
      # -set    ImageMagickの変数をセット
      # $[fx:]  計算
      execute("convert #{tmp_z} -crop #{tile_size}x#{tile_size} -set filename:tile '%[fx:page.x/#{tile_size}]_%[fx:page.y/#{tile_size}]' #{tile_dir}/#{z}/%[filename:tile].png")
    end

    unless debug
      puts "一時ファイルを削除"
      execute("rm -rf #{tmp_dir}/tmp_*.png")
    end

    puts "index.htmlを生成"
    bounds_x = -1 * orig_h.to_f / 2 ** base
    bounds_y = orig_w.to_f / 2 ** base
    @center = "[#{bounds_x / 2}, #{bounds_y / 2}]"
    @max_zoom = max_zoom
    @bounds = "[[#{bounds_x}, 0], [0, #{bounds_y}]]"
    rendered = ERB.new(File.read("index.html.erb")).result(binding)
    File.write("index.html", rendered)
  end
end


if __FILE__ == $0
  if ARGV.length < 1
    puts "Usage: ruby maketile2.rb file"
    exit 1
  end
  # 入力ファイル
  file = ARGV[0]
  maketile = MakeTile.new
  maketile.make(file, debug: true)
end
