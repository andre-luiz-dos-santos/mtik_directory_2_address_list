# coding: utf-8
require 'mtik_directory_2_address_list/version'
require 'mtik_directory_2_address_list/log'
require 'mtik_directory_2_address_list/directory'
require 'mtik_directory_2_address_list/mikrotik'

module MtikDirectory2AddressList
  module_function

  # Synchronize a directory containing symbolic links with a Mikrotik address list.
  #
  # @param [String] src The directory where to look for symbolic links
  # @param [Hash] dst The object passed to the +mtik+ gem (keys: +host+, +user+, +pass+)
  # @param [String] prefix The prefix an address list name must have for it to be used
  # @return [nil]
  def sync(src, dst, prefix = "dir_")
    Log.info { "Synchronizing [#{src}] with router at [#{dst[:host]}]" }
    mtik = Mikrotik.new(dst.dup.merge(prefix:prefix))
    Directory.watch(src) do |dm| # Directory Map {ip => address_list}
      mm = Hash[mtik.list.to_a] # Mikrotik Map {ip => address_list}
      dm.each_pair do |d_ip, d_address_list|
        if mm.key? d_ip
          if d_address_list != mm[d_ip]
            Log.info { "Updating IP [#{d_ip}] to list [#{d_address_list}]" }
            mtik.update(d_ip, d_address_list)
          end
        else
          Log.info { "Adding IP [#{d_ip}] to list [#{d_address_list}]" }
          mtik.add(d_ip, d_address_list)
        end
      end
      mm.each_key do |m_ip|
        unless dm.key? m_ip
          Log.info { "Deleting IP [#{m_ip}]" }
          mtik.delete(m_ip)
        end
      end
    end
  end
end
