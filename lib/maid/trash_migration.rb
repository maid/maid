# Migrate trash to correct directory on Linux due to a configuration bug in previous releases.
#
# It used to be that the default trash path was the same on every platform, so everything used to go to `~/.Trash` regardless of OS.  (For what it's worth, that used to be the correct trash path on older releases of Ubuntu.)
module Maid
  module TrashMigration
    class << self
      def incorrect_trash
        File.expand_path('~/.Trash') + '/'
      end
  
      def correct_trash
        Maid.new.trash_path + '/'
      end

      def needed?
        Platform.linux? &&
          File.directory?(incorrect_trash) &&
          !ENV['MAID_NO_MIGRATE_TRASH']
      end
 
      def perform
        maid = ::Maid::Maid.new(:trash_path => correct_trash)
        # Use local variable so it's available in the closure used by `instance_eval`
        path = incorrect_trash

        # Might as well use Maid itself for this :)
        maid.instance_eval do
          rule 'Migrate Linux trash to correct path' do
            trash(dir("#{ path }/*"))
            trash(path)
          end
        end

        maid.clean
      end
    end
  end
end
