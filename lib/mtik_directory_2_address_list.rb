require 'mtik_directory_2_address_list/version'
require 'mtik_directory_2_address_list/directory'

module MtikDirectory2AddressList
  # When a file is added to directory 'src', add it to address_list 'dst'.
  # When a file is removed from directory 'src', remove it from address_list 'dst'.
  def sync(src, dst)
    Directory.watch(src) do |dem| # Directory Entries Map [ip => address_list]
    end
  end
end
