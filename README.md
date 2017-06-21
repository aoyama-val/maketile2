# 任意の画像をLeaflet用のタイル化するスクリプト


## 必要なもの

- Ruby
- ImageMagick


## 使い方

```
ruby maketile2.rb 画像ファイル
```

index.htmlが生成されるので、ブラウザで開いて表示確認します。


## Dockerを使う方法

```
docker build -t ruby-imagemagick .
docker run --rm -v $PWD:/work -w /work ruby-imagemagick ruby maketile2.rb 画像ファイル
```
