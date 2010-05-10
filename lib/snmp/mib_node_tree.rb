class SNMP
  class MibNodeTree < MibNode  # :nodoc:
  	def initialize(initial_data = {})
  		@log = initial_data.keys.include?(:logger) ? initial_data.delete(:logger) : Logger.new('/dev/null')
  		@subnodes = Hash.new { |h,k| h[k] = SNMP::MibNodeTree.new(:logger => @log) }

  		initial_data.keys.each do |k|
  			raise ArgumentError.new("MIB key #{k} is not an integer") unless k.is_a? ::Integer
  			@subnodes[k] = MibNode.create(initial_data[k], :logger => @log)
  		end
  	end

  	def to_hash
  		output = {}
  		keys.each do |k|
  			output[k] = @subnodes[k].respond_to?(:to_hash) ? @subnodes[k].to_hash : @subnodes[k]
  		end

  		output
  	end

  	def empty?
  		length == 0
  	end

  	def value
  		nil
  	end

  	def get_node(oid)
  		oid = ObjectId.new(oid)
  		@log.debug("get_node(#{oid.to_s})")

  		next_idx = oid.shift
  		if next_idx.nil?
  			# End of the road, bud
  			return self
  		else
  			return sub_node(next_idx).get_node(oid)
  		end
  	end

  	def add_node(oid, node)
  		oid = ObjectId.new(oid) unless oid.is_a? ObjectId
  		@log.debug("Adding a #{node.class} at #{oid.to_s}")

  		sub = oid.shift

  		if oid.length == 0
  			if @subnodes.has_key? sub
  				raise ArgumentError.new("OID #{oid} is already occupied by something; cannot put a node here")
  			else
  				@log.debug("Inserted")
  				@subnodes[sub] = node
  				@log.debug("#{self.object_id}.subnodes[#{sub}] is now a #{@subnodes[sub].class}")
  			end
  		else
  			@subnodes[sub].add_node(oid, node)
  		end
  	end

  	# Return the path down the 'left' side of the MIB tree from this point.
  	# The 'left' is, of course, the smallest node in each subtree until we
  	# get to a leaf.  It is possible that the subtree doesn't contain any
  	# actual data; in this instance, left_path will return nil to indicate
  	# "no tree here, look somewhere else".
  	def left_path()
  		@log.debug("left_path")
  		path = nil

  		keys.sort.each do |next_idx|
  			@log.debug("Boink (#{next_idx})")
  			# Dereference into the subtree. Let's see what we've got here, shall we?
  			next_node = sub_node(next_idx)

  			path = next_node.left_path()
  			unless path.nil?
  				# Add ourselves to the front of the path, and we're done
  				path.unshift(next_idx)
  				return path
  			end
  		end

  		# We chewed through all the keys and all the subtrees were completely
  		# empty.  Bugger.
  		return nil
  	end

  	# Return the next OID strictly larger than the given OID from this node.
  	# Returns nil if there is no larger OID in the subtree.
  	def next_oid_in_tree(oid)
  		@log.debug("MibNodeTree#next_oid_in_tree(#{oid})")
  		oid = ObjectId.new(oid)

  		# End of the line, bub
  		return self.left_path if oid.length == 0

  		sub = oid.shift

  		next_oid = sub_node(sub).next_oid_in_tree(oid)

  		@log.debug("Got #{next_oid.inspect} from call to subnodes[#{sub}].next_oid_in_tree(#{oid.to_s})")

  		if next_oid.nil?
  			@log.debug("No luck asking subtree #{sub}; how about the next subtree(s)?")
  			sub = @subnodes.keys.sort.find { |k|
  				if k > sub
  					@log.debug("Examining subtree #{k}")
  					!sub_node(k).left_path.nil?
  				else
  					false
  				end
  			}

  			if sub.nil?
  				@log.debug("This node has no valid next nodes")
  				return nil
  			end

  			next_oid = sub_node(sub).left_path
  		end

  		if next_oid.nil?
  			# We've got no next node below us
  			return nil
  		else
  			# We've got a next OID to go to; append ourselves to the front and
  			# send it back up the line
  			next_oid.unshift(sub)
  			@log.debug("The next OID for #{oid.inspect} is #{next_oid.inspect}")
  			return ObjectId.new(next_oid)
  		end
  	end

  	private
  	def sub_node(idx)
  		@log.debug("sub_node(#{idx.inspect})")
  		raise ArgumentError.new("Index [#{idx}] must be an integer in a MIB tree") unless idx.is_a? ::Integer

  		# Dereference into the subtree. Let's see what we've got here, shall we?
  		@log.debug("#{self.object_id}.subnodes[#{idx}] is a #{@subnodes[idx].class}")
  		@subnodes[idx]
  	end

  	def keys
  		@subnodes.keys
  	end

  	def length
  		@subnodes.length
  	end
  end
end