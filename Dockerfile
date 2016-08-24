FROM ruby:2.1-onbuild

CMD ["bundle", "exec", "./lock-and-snap.rb"]
