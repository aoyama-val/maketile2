FROM frolvlad/alpine-ruby
ENV LANG C.UTF-8
RUN apk update && apk add imagemagick
