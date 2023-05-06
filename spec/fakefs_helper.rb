# FakeFS is missing #flock, see https://github.com/fakefs/fakefs/issues/433 and
# https://github.com/whitesmith/rubycritic/commit/57edc6244a9ebea8078a9c1dba32204ee7d1d895
module FakeFS
  class File < StringIO
    def flock(*)
      true
    end
  end
end
