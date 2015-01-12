# coding: utf-8

require 'simplecov'

gem 'minitest'
gem 'mocha'
require 'minitest/autorun'
require 'mocha/setup'
require 'mtik_directory_2_address_list'

begin
  file = File.join(File.dirname(__FILE__), 'mikrotik.eval')
  $mtik_params = eval(IO.read(file))
rescue => err
  puts "Cannot read Mikrotik configuration file: #{err}"
  puts "Example: {host:'10.9.8.7', user:'login', pass:'123', prefix:'download_speed_'}"
else
  module MtikDirectory2AddressList
    describe "Mikrotik" do
      subject do
        Mikrotik.new($mtik_params)
      end

      before do
        subject.clear
      end

      it "#add" do
        subject.add('1.2.3.4', 'address-list-name')
        assert_equal([%w(1.2.3.4 address-list-name)], subject.list.to_a)
      end

      it "raises SyncError on duplicated IP on #add" do
        subject.add('1.2.3.4', 'address-list-name')
        assert_raises(Mikrotik::SyncError) { subject.add('1.2.3.4', 'address-list-name') }
      end

      it "#list" do
        subject.add('1.2.3.4', 'address-list-name')
        subject.send(:fetch)
        assert_equal([%w(1.2.3.4 address-list-name)], subject.list.to_a)
      end

      it "#delete" do
        subject.add('1.2.3.4', 'address-list-name')
        subject.send(:fetch)
        subject.delete('1.2.3.4')
        assert_equal([], subject.list.to_a)
      end

      it "#delete after #add" do
        subject.add('1.2.3.4', 'address-list-name')
        subject.delete('1.2.3.4')
        assert_equal([], subject.list.to_a)
        subject.send(:fetch)
        assert_equal([], subject.list.to_a)
      end

      it "raises SyncError on missing IP on #delete" do
        assert_raises(Mikrotik::SyncError) { subject.delete('1.2.3.4') }
      end

      it "#update" do
        subject.add('1.2.3.4', 'address-list-name')
        subject.send(:fetch)
        subject.update('1.2.3.4', 'brand-new-name')
        assert_equal([%w(1.2.3.4 brand-new-name)], subject.list.to_a)
        subject.send(:fetch)
        assert_equal([%w(1.2.3.4 brand-new-name)], subject.list.to_a)
      end

      it "#update after #add" do
        subject.add('1.2.3.4', 'address-list-name')
        subject.update('1.2.3.4', 'brand-new-name')
        assert_equal([%w(1.2.3.4 brand-new-name)], subject.list.to_a)
        subject.send(:fetch)
        assert_equal([%w(1.2.3.4 brand-new-name)], subject.list.to_a)
      end

      it "raises SyncError on missing IP on #update" do
        assert_raises(Mikrotik::SyncError) { subject.update('1.2.3.4', 'address-list-name') }
      end

      it "raises RouterError on !trap" do
        mtik_api = %w(/ip/firewall/address-list/remove =.id=XXX)
        err = assert_raises(Mikrotik::RouterError) { subject.send(:request, *mtik_api) }
        assert_equal('no such item', err.to_s) # ID XXX is impossible/invalid
      end

      it "raises Error on unrecognized Mikrotik reply" do
        re = {'unexpected'=>nil}
        request = mock(:reply => [re])
        subject.send(:connection).stubs(:get_reply_each).yields(request)
        err = assert_raises(Mikrotik::Error) { subject.send(:request, '/xxx') }
        assert_equal('Unrecognized Mikrotik reply: {"unexpected"=>nil}', err.to_s)
      end

      it "raises Error on incomplete Mikrotik reply" do
        subject.send(:connection).stubs(:get_reply_each)
        err = assert_raises(Mikrotik::Error) { subject.send(:request, '/xxx') }
        assert_equal('Missing reply: no !re, !done, !trap received', err.to_s)
      end

      it "nil @cache on fetch error" do
        class MyError < StandardError ; end
        subject.stubs(:request).raises(MyError)
        assert_raises(MyError) { subject.send(:fetch) }
        assert_equal(nil, subject.instance_variable_get(:@cache))
      end
    end
  end
end
