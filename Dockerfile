FROM ruby:2.5.1-slim

WORKDIR /usr/src/app

COPY . .

RUN bundle install

CMD ["./run.rb"]
