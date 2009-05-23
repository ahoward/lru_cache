module LRU

  def LRU.cache(*args, &block)
    Cache.new(*args, &block)
  end

  class Cache
    Mb = 2 * 20
    Max = 1 * Mb
    Record = Struct.new(:key, :value, :hits, :at)

    attr_accessor :index
    attr_accessor :max
    attr_accessor :block

    def initialize(options = {}, &block)
      @index = Hash.new
      @linked_list = LinkedList[]
      @max = Float(options[:max]||options['max']||Max).to_i
      @block = block
    end

    def get key, &block
      if @index.has_key?(key)
        node = @index[key]
        @linked_list.remove_node(node)
        @linked_list.push_node(node)
        pair = node.object
        pair.last
      else
        block ||= @block
        raise 'no block!' unless block
        value = block.call(key)
        pair = [key, value]
        @linked_list.push(pair)
        node = @linked_list.last_node
        @index[key] = node
        pair.last
      end
    ensure
      manage_cache
    end

    def put(key, value)
      delete(key)
      get(key){ value }
    end

    def delete(key)
      if @index.has_key?(key)
        node = @index[key]
        pair = node.object
        @linked_list.remove_node(node)
        @index.delete(pair.first)
        pair.last
      end
    end

    def manage_cache
      if size > max
        until size <= max
          node = @linked_list.shift_node
          pair = node.object
          @index.delete(pair.first)
          @linked_list.remove_node(node)
        end
      end
    end

    def size
      @index.size
    end

    def values &block
      result = []
      @linked_list.each do |pair|
        value = pair.last
        block ? block.call(value) : result.push(value)
      end
      block ? self : result
    end

    def keys &block
      result = []
      @linked_list.each do |pair|
        key = pair.first
        block ? block.call(key) : result.push(key)
      end
      block ? self : result
    end

    def to_a
      keys.zip(values)
    end
  end

  class LinkedList
    Node = Struct.new :object, :prev, :next

    include Enumerable

    def LinkedList.[](*args)
      new(*args)
    end

    attr :size

    def initialize(*args)
      replace(args)
    end

    def replace(args=nil)
      @first = Node.new
      @last = Node.new
      @first.next = @last
      @last.prev = @first
      @size = 0
      args = args.to_a
      args.to_a.each{|arg| push(arg)} unless args.empty?
      self
    end

    def first
      not_empty! and @first.next.object
    end

    def first_node
      not_empty! and @first.next
    end

    def last
      not_empty! and @last.prev.object
    end

    def last_node
      not_empty! and @last.prev
    end

    def not_empty!
      @size <= 0 ? raise('empty') : @size
    end

    def push(object)
      push_node(Node.new(object, @last.prev, @last)).object
    end

    def push_node(node)
      @last.prev.next = node
      @last.prev = node
      @size += 1
      node
    end

    def <<(object)
      push(object)
      self
    end

    def pop
      pop_node.object
    end

    def pop_node
      raise('empty') if @size <= 0
      node = @last.prev
      node.prev.next = @last
      @last.prev = node.prev
      @size -= 1
      node
    end

    def unshift(object)
      unshift_node(Node.new(object, @first, @first.next)).object
    end

    def unshift_node(node)
      @first.next.prev = node
      @first.next = node
      @size += 1
      node
    end

    def shift
      shift_node.object
    end

    def shift_node
      raise('empty') if @size <= 0
      node = @first.next
      node.next.prev = @first
      @first.next = node.next
      @size -= 1
      node
    end

    def remove_node(node)
      not_empty!
      node.prev.next = node.next
      node.next.prev = node.prev
      node
    end

    def each_node
      node = @first.next
      while node != @last
        yield node
        node = node.next
      end
      self
    end

    def each
      each_node{|node| yield node.object}
    end

    def reverse_each_node
      node = @last
      loop do
        yield node
        node = node.prev
        if ! node
          break
        end
      end
      self
    end

    def reverse_each
      reverse_each_node{|node| yield node.object}
    end

    alias_method '__inspect__', 'inspect' unless instance_methods.include?('__inspect__')

    def inspect
      to_a.inspect
    end
  end

end
