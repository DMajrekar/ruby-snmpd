class SNMP
  class MibNodeProxy < MibNode  # :nodoc:
  	def initialize(opts)
  		@base_oid = SNMP::ObjectId.new(opts[:base_oid])
  		@manager = SNMP::Manager.new(:Host => opts[:host], :Port => opts[:port])
  		@log = opts[:logger] ? opts[:logger] : Logger.new('/dev/null')
  	end

  	def get_node(oid)
  		oid = SNMP::ObjectId.new(oid) unless oid.is_a? SNMP::ObjectId

  		complete_oid = ObjectId.new(@base_oid + oid)

  		rv = @manager.get([complete_oid])

  		MibNodeValue.new(:value => rv.varbind_list[0].value)
  	end

  	def add_node(oid, node)
  		raise ArgumentError.new("Cannot add a node inside a MibNodeProxy")
  	end

  	def left_path()
  		next_oid_in_tree(@base_oid)
  	end

  	def next_oid_in_tree(oid)
  		oid = SNMP::ObjectId.new(oid) unless oid.is_a? SNMP::ObjectId

  		complete_oid = ObjectId.new(@base_oid + oid)

  		rv = @manager.get_next([complete_oid])

  		next_oid = rv.varbind_list[0].name

  		if next_oid.subtree_of? @base_oid
  			# Remember to only return the interesting subtree portion!
  			next_oid[@base_oid.length..-1]
  		else
  			nil
  		end
  	end
  end

  
end