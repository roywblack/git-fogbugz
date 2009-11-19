#!/usr/bin/env ruby 

# == Synopsis 
#   git post-receive hook for integration with FogBugz 
#
# == Examples
#   This command takes standard input from git's post-receive hook
#     git-fogbugz foo.txt
#
#   Other examples:
#     git-fogbugz --passthrough
#
# == Usage 
#   git-fogbugz [options] source_file
#
#   For help use: git-fogbugz -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose
#   -V, --verbose       Verbose output
#   -p, --passthrough   Push stdtin to stdout for chaining
#
# == Author
#   Roy W. Black
#
# == Copyright
#   Copyright (c) 2007 Roy W. Black. Licensed under the MIT License:
#   http://www.opensource.org/licenses/mit-license.php


require 'optparse' 
require 'ostruct'
require 'date'
require 'net/https'
require 'uri'
require 'grit'
include Grit

class App
  VERSION = '0.0.1'
  
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false
    @options.quiet = false
    @options.passthrough = false
    @options.repo = "C:/clients/MattMuresan/source/scenengine"
    # TO DO - add additional defaults
    @options.host = "https://onebrave.fogbugz.com"
    @options.port = 443
    @options.repo_id = 4
    
  end

  # Parse options, check arguments, then process the command
  def run
    
    if parsed_options? && arguments_valid? 
      
      $stderr.puts "Start at #{DateTime.now}\n\n" if @options.verbose
      
      output_options if @options.verbose # [Optional]
      
      process_arguments            
      process_command
      
      $stderr.puts "\nFinished at #{DateTime.now}" if @options.verbose
      
    else
      output_usage
    end
    
  end
  
  protected
  
  def parsed_options?
    opts = OptionParser.new do |opts|
      opts.banner = <<BANNER
Usage: git-fogbugz [options]

Options are:
BANNER
      opts.separator ""
      opts.on_tail('-r', '--repo=REPO')    {|repo| @options.repo = repo }
      opts.on_tail('-v', '--version')    { output_version ; exit 0 }
      opts.on_tail('-V', '--verbose')    { @options.verbose = true }  
      opts.on_tail('-q', '--quiet')      { @options.quiet = true }
      opts.on('-p', '--passthrough'){ @options.passthrough = true }

      opts.on_tail('-h', '--help')       { output_version; puts opts }
    end
    opts.parse!(@arguments) rescue return false
    process_options
    true

  end

  # Performs post-parse processing on options
  def process_options
    @options.verbose = false if @options.quiet
  end
  
  def output_options
    $stderr.puts "Options:\n"
    
    @options.marshal_dump.each do |name, val|        
      $stderr.puts "  #{name} = #{val}"
    end
  end

  # True if required arguments were provided
  def arguments_valid?
    # TO DO - implement your real logic here
    #true if @arguments.length == 1
    true
  end
  
  # Setup the arguments
  def process_arguments
    # TO DO - place in local vars, etc
  end
  
  def output_help
    output_version
    #RDoc::usage() #exits app
  end
  
  def output_usage
    puts @options
    #RDoc::usage('usage') # gets usage from comments above
  end
  
  def output_version
    puts "#{File.basename(__FILE__)} version #{VERSION}"
  end
  
  def process_command
    # TO DO - do whatever this app does
    
    process_standard_input # [Optional]
  end

  def process_standard_input
    repo = Repo.new(@options.repo)
    #input = @stdin.read      
    # TO DO - process input
    # [Optional]
    @stdin.each do |line| 
      old, new, ref = line.split
      repo.commits_between(old, new).each do |commit|
        process_commit(commit)
      end
      $stdout.puts line if @options.passthrough
      # TO DO - process each line
    end
  end

  private
  def process_commit(commit)
    uri = URI.parse(@options.host)
    fogbugz = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == "https"
      fogbugz.use_ssl=true
      fogbugz.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    if commit.message =~ /(bugzid|case|issue)[:\s]+(\d+)/i
      id = commit.id[0,7]
      files = commit.diffs.each do |d| 
        resp = fogbugz.get(make_url($2, '00000', id, d.a_path))
        #puts resp.body
      end
    end
    return
  end

  def make_url(bug_id, old, new, file)
    "/cvsSubmit.asp?ixBug=#{bug_id}&sFile=#{file}&sPrev=#{old}&sNew=#{new}&ixRepository=#{@options.repo_id}"
  end
end


# TO DO - Add your Modules, Classes, etc


