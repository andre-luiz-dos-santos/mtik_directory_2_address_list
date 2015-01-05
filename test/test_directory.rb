# encoding: utf-8

gem 'minitest'
gem 'mocha'
require 'minitest/autorun'
require 'mocha/setup'
require 'mtik_directory_2_address_list/directory'

describe "OS" do
  # man READLINK(2) says:
  #  EINVAL The named file is not a symbolic link.
  it "readlink should yield EINVAL on non-symlinks" do
    begin
      File.readlink("/") # "/" is always a directory
    rescue => err
      assert_instance_of(Errno::EINVAL, err)
    end
  end
end

describe "Directory" do
  describe "sample-1" do
    let :path do
      "/tmp/sample-1"
    end

    before do
      FileUtils.mkdir(path)
      Dir.chdir(path) do
        FileUtils.touch(%w(ignored 9.8.7.6))
        File.symlink("account-name-1", "1.2.3.4")
        File.symlink("account-name-2", "1.2.3.5")
      end
    end

    after do
      FileUtils.rm_rf(path)
    end

    it "should list one link" do
      res = MtikDirectory2AddressList::Directory.new(path:path).list
      assert_equal([%w(1.2.3.4 account-name-1), %w(1.2.3.5 account-name-2)], res.to_a)
      assert_equal({'1.2.3.4' => 'account-name-1', '1.2.3.5' => 'account-name-2'}, Hash[res.to_a])
    end
  end

  it "should yield on different mtime" do
    d = MtikDirectory2AddressList::Directory.new(path:"/tmp")
    d.stubs(:sleep)
    d.stubs(:loop).multiple_yields(*4.times)
    d.stubs(:mtime).returns(10, 10, 20, 20)
    times = 0 ; d.watch { times += 1 }
    assert_equal(2, times)
  end
end
