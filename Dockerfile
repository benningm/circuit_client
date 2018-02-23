FROM ruby:2.4

WORKDIR /usr/src/module

COPY Gemfile* ./
RUN bundle install

COPY . .

