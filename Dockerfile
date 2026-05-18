FROM ruby:3.2.9-trixie

COPY . /test/

WORKDIR /test/

ENV BUNDLE_GEMFILE=Gemfile8
ENV FIXTURES_YML=fixtures8.yml
ENV PUPPET_FORGE=https://forge.puppet.com

RUN bundle config set path 'vendor/bundle'
RUN bundle install --jobs=4 --retry=3
#RUN bundle exec rake lint
#RUN bundle exec rake test
