FROM ruby:2.5.1-slim

COPY drone-slack.rb /bin/drone-slack

RUN gem install --no-document httparty

CMD ["/bin/drone-slack"]
