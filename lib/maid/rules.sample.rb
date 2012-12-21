# Sample Maid rules file -- some ideas to get you started.
#
# To use, remove ".sample" from the filename, and modify as desired.  Test using:
#
#     maid clean -n
#
# **NOTE:** It's recommended you just use this as a template; if you run these rules on your machine without knowing
# what they do, you might run into unwanted results!
#
# Don't forget, it's just Ruby!  You can define custom methods and use them below:
# 
#     def magic(*)
#       # ...
#     end
# 
# If you come up with some cool tools of your own, please send me a pull request on GitHub!  Also, please consider sharing your rules with others via [the wiki](https://github.com/benjaminoakes/maid/wiki).
#
# For more help on Maid:
#
# * Run `maid help`
# * Read the README, tutorial, and documentation at https://github.com/benjaminoakes/maid#maid
# * Ask me a question over email (hello@benjaminoakes.com) or Twitter (@benjaminoakes)
# * Check out how others are using Maid in [the Maid wiki](https://github.com/benjaminoakes/maid/wiki)

Maid.rules do
  # **NOTE:** It's recommended you just use this as a template; if you run these rules on your machine without knowing
  # what they do, you might run into unwanted results!

  rule 'Linux ISOs, etc' do
    trash(dir('~/Downloads/*.iso'))
  end

  rule 'Linux applications in Debian packages' do
    trash(dir('~/Downloads/*.deb'))
  end

  rule 'Mac OS X applications in disk images' do
    trash(dir('~/Downloads/*.dmg'))
  end

  rule 'Mac OS X applications in zip files' do
    found = dir('~/Downloads/*.zip').select { |path|
      zipfile_contents(path).any? { |c| c.match(/\.app$/) }
    }

    trash(found)
  end

  rule 'Misc Screenshots' do
    dir('~/Desktop/Screen shot *').each do |path|
      if 1.week.since?(accessed_at(path))
        move(path, '~/Documents/Misc Screenshots/')
      end
    end
  end

  # NOTE: Currently, only Mac OS X supports `duration_s`.
  rule 'MP3s likely to be music' do
    dir('~/Downloads/*.mp3').each do |path|
      if duration_s(path) > 30.0
        move(path, '~/Music/iTunes/iTunes Media/Automatically Add to iTunes/')
      end
    end
  end
  
  # NOTE: Currently, only Mac OS X supports `downloaded_from`.
  rule 'Old files downloaded while developing/testing' do
    dir('~/Downloads/*').each do |path|
      if downloaded_from(path).any? { |u| u.match('http://localhost') || u.match('http://staging.yourcompany.com') } &&
          1.week.since?(accessed_at(path))
        trash(path)
      end
    end
  end
end
