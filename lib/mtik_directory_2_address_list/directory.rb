# coding: utf-8

module MtikDirectory2AddressList
  class Directory
    Error = Class.new(StandardError)

    # The {#list} method will not enumerate symbolic links that do not match this regular expression.
    # Other methods may raise Error.
    IP_RE = %r{ \A \d{1,3} \. \d{1,3} \. \d{1,3} \. \d{1,3} \z }x

    # Manage a directory of symbolic links.
    #
    # The IP address is the name of the symbolic link.
    # The address list name is what the symbolic link points to.
    #
    # @param [Hash] params
    # @option params [String] :path The path to the directory containing symbolic links
    def initialize(params)
      @path = params[:path]
    end

    # Return the address list associated with +ip+.
    #
    # @param [String] ip
    #
    # @return [String] The address list associated with +ip+
    # @return [nil] When the +ip+ is not found
    def [](ip)
      (ip =~ IP_RE) || raise(Error, "Invalid IP [#{ip}]")
      file = File.join(@path, ip)
      File.readlink(file)
    rescue Errno::ENOENT
      nil
    rescue Errno::EINVAL
      raise(Error, "IP [#{ip}] is not a symlink [#{file}]")
    end

    # Enumerate IPs associated with an address list.
    #
    # @return [Enumerator] Arrays with: IP, address list
    def list
      Enumerator.new do |y|
        Dir.foreach(@path) do |de| file = File.basename(de)
          (file =~ IP_RE) && (value = self[file]) && (y << [file, value])
        end
      end
    end

    # Yield whenever an association is modified.
    #
    # This is based on the mtime of the directory being watched.
    # If the mtime is not updated when a symbolic link is changed,
    # the directory must be touched manually.
    #
    # @yield Right after being called
    # @yield After every association update
    # @return [void]
    def watch
      before = nil
      loop do sleep(1)
        next if before == (after = mtime)
        yield ; before = after
      end
    end

    # Like the instance method {#watch}, but yield a Hash with the associations.
    #
    # @param [String] path The directory to watch for modifications
    #
    # @yieldparam Hash{String=>String} Map IP addresses to address list names
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
