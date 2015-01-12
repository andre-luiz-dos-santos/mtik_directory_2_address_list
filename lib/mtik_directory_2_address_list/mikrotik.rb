# coding: utf-8
require 'mtik'

module MtikDirectory2AddressList
  class Mikrotik
    class Error < StandardError ; end
    class RouterError < StandardError ; end
    class SyncError < StandardError ; end

    def initialize(params)
      @prefix = (params[:prefix] || 'md2al_')
      @mtik_params = params.select { |k,_| %w(host user pass).include? k.to_s }
      fetch
    end

    # Enumerates every IP in address lists prefixed with +@prefix+.
    #
    # @return [Enumerator] Arrays with: IP, address list
    def list
      Enumerator.new do |y|
        @cache.each_value do |re|
          y << [re['address'], re['list']]
        end
      end
    end

    # Add IP to address list.
    #
    # @param [String] ip The IP address to add
    # @param [String] address_list The address list to add the IP into
    #
    # @raise [SyncError] When the IP already exists in the local cache
    # @raise [RouterError] When the IP already exists in the Mikrotik router
    #
    # @return [self]
    def add(ip, address_list)
      if @cache.key?(ip)
        raise(SyncError, "IP #{ip} already in cache")
      end
      id = address_list_add(ip, @prefix + address_list)
      @cache[ip] = {".id"=>id, "address"=>ip, "list"=>address_list}
      return self
    end

    # Move IP to a different address list.
    #
    # @param [String] ip The IP address to move
    # @param [String] address_list The address list to move the IP into
    #
    # @raise [SyncError] When the IP is not found in the local cache
    # @raise [RouterError] When the IP is not found in the Mikrotik router
    #
    # @return [self]
    def update(ip, address_list)
      unless (re = @cache[ip])
        raise(SyncError, "IP #{ip} not in cache")
      end
      address_list_set(re['.id'], @prefix + address_list)
      re['list'] = address_list
      return self
    end

    # Remove IP from its current address list.
    #
    # @param [String] ip The IP address to remove
    #
    # @raise [SyncError] When the IP is not found in the local cache
    # @raise [RouterError] When the IP is not found in the Mikrotik router
    #
    # @return [self]
    def delete(ip)
      unless (re = @cache.delete(ip))
        raise(SyncError, "IP #{ip} not in cache")
      end
      address_list_remove(re['.id'])
      return self
    end

    # Delete all IPs from address lists prefixed with +@prefix+.
    #
    # @return [self]
    def clear
      @cache.each_value do |re|
        address_list_remove(re['.id'])
      end
      @cache.clear
      return self
    end

    private

    # @return [MTik::Connection]
    def connection
      @connection ||= MTik::Connection.new(@mtik_params).tap do
        Log.info { "Connecting to Mikrotik at #{@mtik_params.inspect}" }
      end
    end

    # @return [String, nil]
    def request(*args)
      Log.info { "Mikrotik request: #{args.inspect}" }
      connection.get_reply_each(*args) do |request|
        while (re = request.reply.shift)
          Log.info { "Mikrotik reply: #{re.inspect}" }
          if re.key?('!re') ; yield(re)
          elsif re.key?('!done') ; return re['ret']
          elsif re.key?('!trap') ; raise(RouterError, re['message'])
          else raise(Error, "Unrecognized Mikrotik reply: #{re.inspect}")
          end
        end
      end
      raise(Error, "Missing reply: no !re, !done, !trap received")
    end

    # @return [void]
    def fetch
      @cache = {}
      request('/ip/firewall/address-list/print', '=.proplist=.id,address,list') do |re|
        re['list'].sub!(/\A#{Regexp.quote(@prefix)}/) do
          @cache[re['address']] = re
          next '' # replaces @prefix on re['list']
        end
      end
    rescue
      @cache = nil
      raise
    end

    # @param [String] ip
    # @param [String] address_list
    # @return [String] The ID of the added item
    def address_list_add(ip, address_list)
      request('/ip/firewall/address-list/add', "=address=#{ip}", "=list=#{address_list}")
    end

    # @param [String] id
    # @param [String] address_list
    # @return [void]
    def address_list_set(id, address_list)
      request('/ip/firewall/address-list/set', "=.id=#{id}", "=list=#{address_list}")
    end

    # @param [String] id
    # @return [void]
    def address_list_remove(id)
      request('/ip/firewall/address-list/remove', "=.id=#{id}")
    end
  end
end
