class UDPSocketPool
	def initialize(port)
		@socket_list = {}
		@port = port
		
		init_socket_list
	end

	def self.listen(port, &block)
		pool = UDPSocketPool.new(port)
		
		pool.listen(&block)
	end
	
	def listen
		raise RuntimeError.new("No block given to UDPSocketPool#listen") unless block_given?

		loop do
			ready = IO::select(@socket_list.values)[0]
		
			ready.each do |s|
				data, origin = s.recvfrom(65535)
				if s == @socket_list['0.0.0.0']
					# We don't explicitly handle data received by the 'any'
					# socket, we just use it to trigger a rescan
					init_socket_list
				else
					result = yield(data)
					s.send(result, 0, origin[3], origin[1]) unless result.nil?
				end
			end
		end
	end
	
	def close
		@socket_list.values.each {|s| s.close}
	end
		
	private
	def init_socket_list
		addrs = address_list
		
		addrs.each do |a|
			next if @socket_list.keys.include? a
			@socket_list[a] = ::UDPSocket.new
			@socket_list[a].setsockopt(Socket::SOL_SOCKET,
			                           Socket::SO_REUSEADDR, 
			                           1)
			@socket_list[a].bind(a, @port)
		end
	end
			
	def address_list
		list = ['0.0.0.0']
		
		# This should be illegal -- mjp
		`/sbin/ifconfig`.grep(/inet addr/).each do |line|
			if line =~ /^\s+inet addr:([0-9.]+)\s/
				list << $1
			end
		end
		
		list
	end
end