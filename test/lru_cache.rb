#! /usr/bin/env ruby
 
Testy.testing 'lru_cache' do

  test 'empty constructor' do |result|
    klass =
      begin
        lru = LRU.cache
        lru.class
      rescue Object => e
        e.class
      end
    result.check :class, :expect => LRU::Cache.name, :actual => klass.name
  end

  context 'with an lru contructed' do
    setup do
      @lru = LRU.cache
    end

    test 'put a key/val pair' do |result|
      actual =
        begin
          @lru.put :key, :val
          :val
        rescue
          false
        end
      result.check :put, :expect => :val, :actual => actual
    end

    test 'put a key/val pair and get it' do |result|
      @lru = LRU.cache
      actual =
        begin
          @lru.put :key, :val
        rescue
          false
        end
      result.check :put, :expect => :val, :actual => actual
      result.check :get, :expect => :val, :actual => @lru.get(:key)
    end

    test 'get a key with a block to put it when it is missing' do |result|
      @lru = LRU.cache
      actual = @lru.get(:key){ :val }
      result.check :get, :expect => :val, :actual => @lru.get(:key)
    end
  end

  test 'sized constructor' do |result|
    klass =
      begin
        lru = LRU.cache :max => 2
        lru.class
      rescue Object => e
        e.class
      end
    result.check :class, :expect => LRU::Cache.name, :actual => klass.name
    result.check :size, :expect => 2, :actual => lru.max
  end

  context 'with an sized lru contructed' do
    setup do
      @lru = LRU.cache :max => 2
    end

    test 'putting > size values and have the cache remain size' do |result|
      (@lru.max + 1).times do |i|
        @lru.put(i, i)
      end
      result.check :size, :expect => 2, :actual => @lru.max
    end

    test 'least recently used value is nuked first when cache becomes full' do |result|
      (@lru.max + 1).times do |i|
        @lru.put(i, i)
      end
      result.check :size, :expect => 2, :actual => @lru.max
      result.check :values, :expect => [1,2], :actual => @lru.values.sort
    end

    test 'accessing a value decreases the chance of it being nuked' do |result|
      @lru = LRU.cache :max => 3
      @lru.max.times{|i| @lru.put(i, i)}
      result.check :size, :expect => 3, :actual => @lru.max
      @lru.get(0)
      @lru.put(3,3)
      result.check :values, :expect => [0,2,3], :actual => @lru.values.sort
      @lru.put(4,4)
      result.check :values, :expect => [0,3,4], :actual => @lru.values.sort
    end

  end


end




BEGIN {
  testdir = File.expand_path(File.dirname(__FILE__))
  rootdir = File.dirname(testdir)
  libdir = File.join(rootdir, 'lib')

  $:.unshift testdir
  $:.unshift libdir

  require 'lru_cache'

  begin
    require 'rubygems'
  rescue
    nil
  end

  begin
    require 'testy'
  rescue
    require File.join(testing, 'testy')
  end
}
