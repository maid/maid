require 'fileutils'

require 'spec_helper'

module Maid
  describe TrashMigration, :fakefs => true do
    context 'when running on Linux' do
      before do
        Platform.stub(:linux?) { true }
      end

      context 'and the incorrect trash path does not exist' do
        it 'is not needed' do
          expect(subject.needed?).to be(false)
        end
      end

      context 'and the incorrect trash path exists' do
        before do
          FileUtils.mkdir_p(subject.incorrect_trash)
        end

        it 'is needed' do
          expect(subject.needed?).to be(true)
        end

        context 'and the kill switch is activated' do
          before do
            ENV.stub(:[]).with('MAID_NO_MIGRATE_TRASH') { 'any-value' }
          end

          it 'is not needed' do
            expect(subject.needed?).to be(false)
          end
        end
      end
    end

    context 'when running on OS X' do
      before do
        Platform.stub(:linux?) { false }
      end

      it 'is not needed' do
        expect(subject.needed?).to be(false)
      end
    end

    describe 'performing' do
      before do
        Logger.stub(:new) { double('Logger').as_null_object }
      end

      context 'in Linux' do
        let(:filename) { 'foo.txt' }
        let(:trash_contents) { Dir.glob(File.join(subject.correct_trash, '*'),
                                        File::FNM_DOTMATCH) }

        before do
          subject.stub(:correct_trash) { File.expand_path('~/.local/share/Trash/files/') }

          FileUtils.mkdir_p(subject.incorrect_trash)
          FileUtils.touch(File.join(subject.incorrect_trash, filename))
          FileUtils.mkdir_p(subject.correct_trash)

          subject.perform
        end


        it 'removes all files from incorrect trash directory' do
          expect(File.exist?(subject.incorrect_trash)).to be false
        end

        it 'moves all files to the correct trash directory' do
          expect(trash_contents.length).to eq(2)
          expect(trash_contents[0]).to match(/files\/\.Trash$/)
          expect(trash_contents[1]).to match(/files\/foo.txt$/)
        end
      end
    end
  end
end
