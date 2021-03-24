require 'webpacker'

module Webpacker
  module WatchedFilesDigestPatch
    private

    def watched_files_digest
      Dir.chdir config.root_path do
        super
      end
    end
  end
end

Webpacker::Compiler.prepend Webpacker::WatchedFilesDigestPatch
