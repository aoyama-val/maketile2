FROM ruby:2.3.1
ENV LANG C.UTF-8
RUN apt-get update -qq && apt-get install -y imagemagick
RUN rm -rf /var/lib/apt/lists/*
