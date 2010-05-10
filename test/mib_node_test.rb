require File.dirname(__FILE__) + '/test_helper.rb'

require 'snmp/agent'

class MibNodeTest < Test::Unit::TestCase
	def test_elementary_creation
		n = SNMP::MibNodeTree.new
		class << n
			public :length, :keys
		end
		
		assert_equal(SNMP::MibNodeTree, n.class)
		assert_equal(0, n.length)
		assert_equal([], n.keys)
		
		n = SNMP::MibNodeTree.new({0 => 1, 1 => 2, 2 => 3})
		class << n; attr_reader :subnodes; public :length, :keys; end
		
		assert_equal(3, n.length)
		assert_equal([0, 1, 2], n.keys.sort)
		assert_equal(1, n.subnodes[0].value)
		assert_equal(2, n.subnodes[1].value)
		assert_equal(3, n.subnodes[2].value)

		n = SNMP::MibNodeTree.new([1, 2, 3])
		class << n; attr_reader :subnodes; public :length, :keys; end

		assert_equal(3, n.length)
		assert_equal([0, 1, 2], n.keys.sort)
		assert_equal(1, n.subnodes[0].value)
		assert_equal(2, n.subnodes[1].value)
		assert_equal(3, n.subnodes[2].value)
		
		n = SNMP::MibNodeTree.new({1 => 1, 2 => 3, 5 => 8, 13 => 21})
		class << n; attr_reader :subnodes; public :length, :keys; end

		assert_equal(4, n.length)
		assert_equal([1, 2, 5, 13], n.keys.sort)
		assert_equal(1, n.subnodes[1].value)
		assert_equal(3, n.subnodes[2].value)
		assert_equal(8, n.subnodes[5].value)
		assert_equal(21, n.subnodes[13].value)
		assert_equal(nil, n.subnodes[0].value)
	end

	def test_more_interesting_creation
		n = SNMP::MibNodeTree.new({0 => [0, 0, 0, 0], 1 => [0, 1, 2, 3], 2 => [0, 2, 4, 6], 4 => [0, 4, 8, 12]})
		class << n; attr_reader :subnodes; public :length, :keys; end
		
		assert_equal(4, n.length)
		assert_equal([0, 1, 2, 4], n.keys.sort)
		
		n_ = n.subnodes[2]
		class << n_; attr_reader :subnodes; public :keys; end
		
		assert_equal(SNMP::MibNodeTree, n_.class)
		assert_equal([0, 1, 2, 3], n_.keys.sort)
		assert_equal(4, n_.subnodes[2].value)
	end

	def test_now_with_added_plugin
		n = SNMP::MibNodeTree.new
		class << n; public :length, :keys; end
		assert_equal(0, n.length)
		
		n.add_node([2], SNMP::MibNodePlugin.new { 42 })

		assert_equal(1, n.length)
		assert_equal([2], n.keys)
		n_ = n.get_node([2])
		assert_equal SNMP::MibNodeValue, n_.class
		assert_equal(42, n_.value)

		n = SNMP::MibNodeTree.new({2 => SNMP::MibNodePlugin.new {[42]}})
		class << n; attr_reader :subnodes; end
		
		assert_equal(SNMP::MibNodeTree, n.get_node([2]).class)
		assert_equal(SNMP::MibNodePlugin, n.subnodes[2].class)
		assert_equal(42, n.get_node('2.0').value)
		assert_equal(nil, n.get_node('2.1').value)
	end
	
	def test_with_noninteger_keys
		assert_raise(ArgumentError) { SNMP::MibNodeTree.new({'xyzzy' => 42}) }
	end

	def test_get_node
		n = SNMP::MibNodeTree.new(1 => {2 => {3 => [0, 1, 2, 3, 4]}})
		
		n_ = n.get_node(SNMP::ObjectId.new('1.2'))
		class << n_; attr_reader :subnodes; public :keys; end
		
		assert_equal(SNMP::MibNodeTree, n_.class)
		assert_equal([3], n_.keys)
		n__ = n_.subnodes[3]
		class << n__; public :keys; end
		assert_equal(SNMP::MibNodeTree, n__.class)
		assert_equal([0, 1, 2, 3, 4], n__.keys)
	end
	
	def test_get_node_through_proc
		n = SNMP::MibNodeTree.new(1 => {2 => {3 => SNMP::MibNodePlugin.new {[[0, 1, 2], [10, 11, 12], [20, 21, 22]]}}})
		
		n_ = n.get_node(SNMP::ObjectId.new('1.2.3.1'))
		class << n_; attr_reader :subnodes; public :keys; end
		assert_equal(SNMP::MibNodeTree, n_.class)
		assert_equal([0, 1, 2], n_.keys)
		assert_equal(11, n_.subnodes[1].value)
	end

	def test_get_exception_raising_node
		n = SNMP::MibNodeTree.new(1 => {2 => {3 => SNMP::MibNodePlugin.new { raise "Broooooken!" }}})

		n_ = n.get_node(SNMP::ObjectId.new('1.2.3.1'))
		assert_equal(SNMP::MibNodeTree, n_.class)
		assert_equal(0, n_.instance_eval("@subnodes.length"))
	end

	def test_left_path
		n = SNMP::MibNodeTree.new(1 => {2 => {3 => [0, 1, 2, 3]}, 3 => {2 => [4, 5, 6, 7]}})
		
		assert_equal([1,2,3,0], n.left_path)
		assert_equal([2,0], n.get_node('1.3').left_path)
	end

	def test_provide_a_logger
		SNMP::MibNode.class_eval("attr_reader :log")
		SNMP::MibNodePlugin.class_eval("attr_reader :log")
		
		n = SNMP::MibNodeTree.new(1 => {2 => {3 => 42}}, :logger => Logger.new('/dev/null'))
		assert_equal Logger, n.log.class

		n = SNMP::MibNodePlugin.new(:logger => Logger.new('/dev/null')) { 42 }
		assert_equal Logger, n.log.class
	end

	def test_implicit_logger
		SNMP::MibNode.class_eval("attr_reader :log")
		SNMP::MibNodePlugin.class_eval("attr_reader :log")
		
		n = SNMP::MibNodeTree.new(1 => {2 => {3 => 42}})
		assert_equal Logger, n.log.class

		n = SNMP::MibNodePlugin.new { 42 }
		assert_equal Logger, n.log.class
	end

	def test_value
		n = SNMP::MibNodeTree.new([0, 1, 2])
		
		assert_equal nil, n.value
		assert_equal SNMP::MibNodeValue, n.get_node([0]).class
		assert_equal 0, n.get_node([0]).value
	end
end
