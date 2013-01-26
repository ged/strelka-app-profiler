# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

	srcdir = basedir.parent
	strelkadir = srcdir + 'Strelka/lib'

	$LOAD_PATH.unshift( strelkadir.to_s ) unless $LOAD_PATH.include?( strelkadir.to_s )
	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
}

require 'rspec'

require 'strelka'
require 'strelka/plugins'
require 'strelka/app/profiler'

require 'mongrel2/testing'
require 'strelka/testing'
require 'strelka/behavior/plugin'
require 'loggability/spechelpers'

### Mock with RSpec
RSpec.configure do |c|
	c.mock_with( :rspec )

	c.include( Loggability::SpecHelpers )
	c.include( Mongrel2::SpecHelpers )
	c.include( Strelka::Testing )

	include Mongrel2::Constants
end


#####################################################################
###	C O N T E X T S
#####################################################################

describe Strelka::App::Profiler do

	# 0mq socket specifications for Handlers
	TEST_SEND_SPEC = 'tcp://127.0.0.1:9998'
	TEST_RECV_SPEC = 'tcp://127.0.0.1:9997'


	before( :all ) do
		setup_logging()
		@request_factory = Mongrel2::RequestFactory.new( route: '' )
	end

	after( :all ) do
		reset_logging()
	end


	it_should_behave_like( "A Strelka::App Plugin" )


	describe "an including App" do

		before( :each ) do
			@app = Class.new( Strelka::App ) do
				plugin :profiler

				def initialize( appid='profiler-test', sspec=TEST_SEND_SPEC, rspec=TEST_RECV_SPEC )
					super
				end
				def set_signal_handlers; end
				def start_accepting_requests; end
				def restore_signal_handlers; end

				def handle_request( req, &block )
					super do
						res = req.response
						res.puts "Normal output"
						res
					end
				end
			end
		end


		it "doesn't touch the response if the profile parameter is not present" do
			request = @request_factory.get( '/foo' )
			response = @app.new.handle( request )
			response.status_line.should =~ /200 OK/

			response.to_s.should =~ /content-length: 14/i
			response.to_s.should =~ /Normal output\n/i
		end

		it "responds with profile HTML if the profile parameter is present" do
			request = @request_factory.get( '/foo?profile=1' )
			response = @app.new.handle( request )
			response.status_line.should =~ /200 OK/

			response.to_s.should_not =~ /content-length: 14\r\n/i
			response.to_s.should =~ %r{<title>ruby-prof call tree</title>}i
		end
			
	end

end

