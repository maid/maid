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
# If you come up with some cool tools of your own, please send me a pull request on GitHub!
#
# For more help on Maid:
#
# * Run `maid help`
# * Read the README, tutorial, and documentation at https://github.com/benjaminoakes/maid#maid
# * Ask me a question over email (hello@benjaminoakes.com) or Twitter (@benjaminoakes)

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
        # NOTE: OS X Mountain Lion's folder is called 'Automatically Add to iTunes.localized'.
        # Moving files to a non-existent folder will just make a music file of that name, and
        # hence destroy all but one music file in your downloads folder. This line will
        # create a folder such that your music won't be destroyed, but won't be imported
        # If your folder is called *.localized when you view it in `ls' output, comment-toggle
        # the following three lines:
        
        mkdir('~/Music/iTunes/iTunes Media/Automatically Add to iTunes/')
        move(path, '~/Music/iTunes/iTunes Media/Automatically Add to iTunes/')
        # move(path, '~/Music/iTunes/iTunes Media/Automatically Add to iTunes.localized/')
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
