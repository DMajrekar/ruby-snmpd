class SNMP
  class MibNodeValue < MibNode  # :nodoc:
  	include Comparable

  	attr_reader :value

  	def initialize(opts)
  		@value = opts[:value]
  		@log = Logger.new('/dev/null')
  	end

  	def <=>(other)
  		@value.nil? or other.nil? ? 0 : @value <=> other.value
  	end

  	def get_node(oid)
  		oid.length == 0 ? self : MibNodeTree.new
  	end

  	def add_node(oid, node)
  		RuntimeError.new("You really shouldn't do that")
  	end

  	def left_path()
  		value.nil? ? nil : []
  	end

  	def next_oid_in_tree(oid)
  		nil
  	end
  end
  
end