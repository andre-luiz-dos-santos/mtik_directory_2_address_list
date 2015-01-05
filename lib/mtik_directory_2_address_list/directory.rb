
module MtikDirectory2AddressList
  class Directory
    # @option params [String] :path The path to the directory to manage
    def initialize(params)
      @path = params[:path]
    end

    # @param [String] key the IP to search for
    # @return [String] the value associated with key
    # @return [nil] if key is not found
    def [](key)
      File.readlink(File.join(@path, key))
    rescue Errno::EINVAL
      nil # Not a symlink
    end

    IP_RE = %r{ \A \d{1,3} \. \d{1,3} \. \d{1,3} \. \d{1,3} \z }x

    # @return [Enumerator] pairs of [IP, value]
    def list
      Enumerator.new do |y|
        Dir.foreach(@path) do |de| file = File.basename(de)
          (file =~ IP_RE) && (value = self[file]) && (y << [file, value])
        end
      end
    end

    # @yield Notifies that there are updates
    def watch
      before = nil
      loop do sleep(1)
        next if before == (after = mtime)
        yield ; before = after
      end
    end

    def self.watch(path)
      self.new(path:path).tap do |dir|
        dir.watch { yield(Hash[dir.list.to_a]) }
      end
    end

    def mtime
      File.mtime(@path)
    end
  end
end
