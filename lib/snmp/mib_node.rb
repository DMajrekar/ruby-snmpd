module SNMP
  class MibNode  # :nodoc:
  	# Create a new MibNode (of some type)
  	#
  	# This is quite a tricky piece of work -- we have to work out whether
  	# we're being asked to create a MibNodeTree (initial_data is a hash or
  	# array), a MibNodeValue (initial_data is some sort of scalar), a
  	# MibNodeProxy (initial_data consists of :host and :port), or a
  	# MibNodePlugin (a block was given).
  	#
  	# What comes out the other end is something that will respond to the
  	# standard MibNode interface, whatever it may be underneath.
  	#
  	def self.create(initial_data = {}, opts = {}, &block)
  		if initial_data.respond_to? :next_oid_in_tree
  			return initial_data
  		end

  		if initial_data.is_a? Array
  			initial_data = initial_data.to_hash
  		end

  		if initial_data.is_a? Hash
  			initial_data.merge! opts
  			if block_given?
  				return MibNodePlugin.new(initial_data, &block)
  			elsif initial_data.keys.member? :host and initial_data.keys.member? :port
  				return MibNodeProxy.new(initial_data)
  			else
  				return MibNodeTree.new(initial_data.merge(opts))
  			end
  		else
  			return MibNodeValue.new({:value => initial_data}.merge(opts))
  		end
  	end
  end

  
end