FROM ruby:2.5.1-slim

ENV LANG=en_GB.UTF-8

COPY drone-slack.rb /bin/drone-slack

RUN gem install --no-document httparty

CMD ["/bin/drone-slack"]
