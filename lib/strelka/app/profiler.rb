# -*- ruby -*-
# vim: set nosta noet ts=4 sw=4:
# encoding: utf-8

require 'ruby-prof'
require 'forwardable'
require 'strelka' unless defined?( Strelka )
require 'strelka/app' unless defined?( Strelka::App )


# Strelka::App plugin module for Profiling requests.
module Strelka::App::Profiler
	extend Strelka::Plugin,
	       Configurability


	# Library version constant
	VERSION = '0.0.1'

	# Version-control revision constant
	REVISION = %q$Revision$


	### Set up the profiler if the request includes a 'profile' parameter.
	def fixup_request( request )
		if request.params['profile']
			RubyProf.start
			request.notes[:profiling] = true
		end

		super
	end

	### Replace the body of the response with the profile body if profiling is enabled.
	def fixup_response( response )
		if RubyProf.running?
			profile = RubyProf.stop

			response.body.truncate( 0 )
			printer = RubyProf::CallStackPrinter.new( profile )
			printer.print( response.body, min_percent: 2 )
			response.content_type = 'text/html'
		end

		super
	end

end # module Strelka::App::Profiler


