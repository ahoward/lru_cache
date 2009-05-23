module LRU
  class Cache
    Mb = 2 * 20
    Max = 1 * Mb
    Record = Struct.new(:key, :value, :hits, :at)

    attr_accessor :cache
    attr_accessor :max
    attr_accessor :block

    def initialize options = {}, &block
      @cache = Hash.new
      @max = Float(options[:max]||options['max']||Max).to_i
      @block = block
    end

    def get key, &block
      block ||= @block
      record = @cache[key]
      if record
        record.hits += 1
      else
        raise 'no block!' unless block
        record = record_for(key, value=block.call(key))
        @cache[key] = record
      end
      record.value
    ensure
      manage_cache
    end

    def put key, value
      record = record_for(key, value)
      @cache[key] = record
      record.value
    ensure
      manage_cache
    end

    def record_for(*args)
      key, value, hits, at, *ignored = args
      hits ||= 0
      at ||= Time.now.to_f
      Record[key, value, hits, at]
    end

    def manage_cache
      if @cache.size > max 
        sorted = records
        until @cache.size <= max
          record = sorted.shift
          @cache.delete(record.key)
        end
      end
    end

    def records
      @cache.values.sort{|a,b| [a.hits, a.at] <=> [b.hits, b.at]}
    end

    def values &block
      result = []
      records.each do |record|
        value = record.value
        block ? block.call(value) : result.push(value)
      end
      block ? self : result
    end

    def keys &block
      result = []
      records.each do |record|
        key = record.key
        block ? block.call(key) : result.push(key)
      end
      block ? self : result
    end

    def to_a
      keys.zip(values)
    end
  end

  def LRU.cache(*args, &block)
    Cache.new(*args, &block)
  end
end
