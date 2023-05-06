FROM ruby:3.2

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock maid.gemspec ./
COPY lib/maid/version.rb ./lib/maid/
# Remove "dubious ownership" error messages
RUN git config --global --add safe.directory /usr/src/app
RUN bundle install

CMD ["bash", "-c", "/usr/local/bundle/bin/bundle exec guard"]

