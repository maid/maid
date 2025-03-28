FROM ruby:3.2

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock maid.gemspec ./
COPY lib/maid/version.rb ./lib/maid/
# Remove "dubious ownership" error messages
RUN git config --global --add safe.directory /usr/src/app
RUN bundle install

ENV ISOLATED=true
CMD ["bash", "-c", "/usr/local/bin/bundle exec guard"]

