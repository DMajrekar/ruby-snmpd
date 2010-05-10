class SNMP
  class MibNodePlugin < MibNode  # :nodoc:
  	def initialize(opts = {}, &block)
  		@log = opts[:logger].nil? ? Logger.new('/dev/null') : opts[:logger]
  		@plugin_timeout = opts[:plugin_timeout] ? 2 : opts[:plugin_timeout]
  		@proc = block
  		@oid = opts[:oid]
  		@cached_value = nil
  		@cache_until = 0
  	end

  	def value
  		nil
  	end

  	def to_hash
  		plugin_value.to_hash
  	end

  	def get_node(oid)
  		@log.debug("get_node(#{oid.to_s})")
  		plugin_value.get_node(oid) if plugin_value.respond_to? :get_node
  	end

  	def add_node(oid, node)
  		raise ArgumentError.new("Adding this plugin would encroach on the subtree of an existing plugin")
  	end

  	def left_path
  		plugin_value.left_path
  	end

  	def next_oid_in_tree(oid)
  		plugin_value.next_oid_in_tree(oid) if plugin_value.respond_to? :next_oid_in_tree
  	end

  	private
  	def plugin_value
  		@log.debug("Getting plugin value")
  		if Time.now.to_i > @cache_until
  			begin
  				plugin_data = nil
  				Timeout::timeout(@plugin_timeout) do
  					plugin_data = @proc.call
  				end
  			rescue Timeout::Error
  				@log.warn("Plugin for OID #{@oid} exceeded the timeout")
  				return MibNodeValue.new(:logger => @log, :value => nil)
  			rescue => e
  				@log.warn("Plugin for OID #{@oid} raised an exception: #{e.message}\n#{e.backtrace.join("\n")}")
  				return MibNodeValue.new(:logger => @log, :value => nil)
  			end

  			if plugin_data.is_a? Array
  				plugin_data = plugin_data.to_hash
  			end

  			if plugin_data.is_a? Hash
  				unless plugin_data[:cache].nil?
  					@cache_until = Time.now.to_i + plugin_data[:cache]
  					plugin_data.delete :cache
  				end
  			end

  			@cached_value = MibNode.create(plugin_data, :logger => @log)
  		end

  		@cached_value
  	end
  end

  
end