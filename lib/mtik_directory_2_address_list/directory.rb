
module MtikDirectory2AddressList
  class Directory
    # Manage a directory of symbolic links.
    #
    # The IP address is the name of a symlink link in +@path+.
    # The address list name is what the symbolic link points to.
    #
    # @param [Hash] params
    # @option params [String] :path The path to the directory containing symbolic links
    def initialize(params)
      @path = params[:path]
    end

    # Return the address list associated with the specified IP.
    #
    # @param [String] ip The IP to search for
    #
    # @return [String] The value associated with +ip+
    # @return [nil] When the +ip+ is not found
    def [](ip)
      File.readlink(File.join(@path, ip))
    rescue Errno::EINVAL
      nil # Not a symlink
    end

    # The {#list} method will not enumerate symbolic links that do not match this regular expression.
    # The {#[]} method will read any symbolic link, even if its name does not match this regular expression.
    IP_RE = %r{ \A \d{1,3} \. \d{1,3} \. \d{1,3} \. \d{1,3} \z }x

    # Enumerates every IP in +@path+.
    #
    # @return [Enumerator] Arrays with: IP, address list
    def list
      Enumerator.new do |y|
        Dir.foreach(@path) do |de| file = File.basename(de)
          (file =~ IP_RE) && (value = self[file]) && (y << [file, value])
        end
      end
    end

    # Yield whenever +@path+ is modified.
    #
    # @yield Right after being called
    # @yield After every update to +@path+
    #
    # @return [void]
    def watch
      before = nil
      loop do sleep(1)
        next if before == (after = mtime)
        yield ; before = after
      end
    end

    # Watch +path+, and yield +list+ as a hash.
    #
    # @param [String] path The directory to watch for modifications
    #
    # @yieldparam Hash{String=>String} Map IP addresses to address list names
    #
    # @return [void]
    def self.watch(path)
      dir = self.new(path:path)
      dir.watch do
        yield(Hash[dir.list.to_a])
      end
    end

    private

    def mtime
      File.mtime(@path)
    end
  end
end
