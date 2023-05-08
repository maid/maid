# FakeFS is missing #flock, see https://github.com/fakefs/fakefs/issues/433 and
# https://github.com/whitesmith/rubycritic/commit/57edc6244a9ebea8078a9c1dba32204ee7d1d895

# NOTE: This avoid NotImplementedError on File.flock, but causes a myriad of
# other issues since it doesn't really provide any locking in practice.
# If required, include this file in spec_helper.rb to monkey-patch FakeFS.
module FakeFS
  class File < StringIO
    def flock(*)
      true
    end
  end
end
