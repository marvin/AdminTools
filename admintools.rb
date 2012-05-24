##############################
# AdminTools
# written by david noelte 2011
# dnoelte@gmail.com
###############################
# requirements
require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'time'
require 'haml'
require 'whois'
require 'mongo_mapper'

# mongo stuff

MongoMapper.connection = Mongo::Connection.new('localhost',27017, :pool_size => 5, :timeout => 5)
MongoMapper.database = 'admintools'

class Whoisrequest
   include MongoMapper::Document
   key :domain,         String,         :required => true
   key :result,    	String
   timestamps!
end

class Logrequest
   include MongoMapper::Document
   key :data,         	String,         :required => true
   timestamps!
end

class Switchconfiguration
   include MongoMapper::Document

   key :vlanid,		String,		:required => true,	:unique => true
   key :vlanname, 	String,		:required => true
   key :vrid,		String,		:required => true
   key :network,	String
   key :netmask,	String
   key :ownerip,	String
   key :backupip,	String
   key :tagged,		String
   key :ownerconfig,	String
   key :backupconfig,	String
   timestamps!
end

# configurations
configure do
  set :version, 'v0.1 alpha'
  set :postfix_config_path, ''
  set :postfix_bin, ''
  set :postmap_bin, ''
end

# datamapper settings
# DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/db/retailadmin.db")

class Domain
  include DataMapper::Resource

  property :id,		Serial
  property :domain,	String, :required => true, :unique => true
  property :created_at,	DateTime

  belongs_to :relayserver, :required => false
  belongs_to :mxgateway, :required => false
end

class Relayserver
  include DataMapper::Resource

  property :id,         Serial
  property :hostname,   String, :required => true, :unique => true
  property :ip,		String
  property :created_at, DateTime

  has n, :domains
end

class Mxgateway
  include DataMapper::Resource

  property :id,         Serial
  property :hostname,   String, :required => true, :unique => true
  property :ip,		String
  property :username,   String
  property :password,   String
  property :created_at, DateTime

  has n, :domains
end

#DataMapper.finalize
DataMapper.auto_upgrade!
#DataMapper.auto_migrate!

# basic authentication
use Rack::Auth::Basic do |username, password|
  username == 'admin' && password == 'secret'
end

# controllers
get '/' do
  haml :index
end

get '/about' do
  haml :about
end

get '/help' do
  haml :help
end

get '/mxtools' do
  @domains = Domain.all	:order => [:domain.asc]
  @relayservers = Relayserver.all :order => [:hostname.asc]
  @mxgateways = Mxgateway.all :order => [:hostname.asc]

  lastactionfile = "tmp/lastactionrun"

  if File.exists?(lastactionfile)
    f = File.open(lastactionfile,"r")  
    @actionrunfile = f.readline
  else
    @actionrunfile = "Not run yet"
  end 

  haml :mxtools
end

get '/adddomain' do
  @mxgateways = Mxgateway.all
  @relayservers = Relayserver.all

  haml :adddomain
end

post '/adddomain' do
  @domain = Domain.new 	:domain     => params[:domain]

  if @domain.save
    redirect "/mxtools"
  else
    redirect "/adddomain"
  end
end

get '/deletedomain/:id' do
  Domain.get(params[:id]).destroy
  redirect '/mxtools'
end 

get '/addrelayserver' do
  haml :addrelayserver
end

post '/addrelayserver' do
  @relayserver = Relayserver.new  	:hostname     	=> params[:hostname],
			     		:ip	   	=> params[:ip]

  if @relayserver.save
    redirect "/mxtools"
  else
    redirect "/addrelayserver"
  end
end

get '/deleterelayserver/:id' do
  Relayserver.get(params[:id]).destroy
  redirect '/mxtools'
end


get '/addmxgateway' do
  haml :addmxgateway
end

post '/addmxgateway' do
  @mxgateway = Mxgateway.new :hostname     => params[:hostname],
                             :ip           => params[:ip]

  if @mxgateway.save
    redirect "/mxtools"
  else
    redirect "/addmxgateway"
  end
end

get '/deletemxgateway/:id' do
  Mxgateway.get(params[:id]).destroy
  redirect '/mxtools'
end

get '/updatefiles' do
  @domains = Domain.all

  haml :updatefiles
end

get '/updatefiles/now' do
  if writefiles
    redirect '/mxtools'
  else
    redirect '/updatefiles'
  end
end

get '/whois' do
  haml :whois
end

get '/cscm' do
  @switchconfigs = Switchconfiguration.all
  haml :cscm
end

get '/addswitchconfig' do
  haml :addswitchconfig
end

post '/addswitchconfig' do

  @ownerconfig = "vlan #{params[:vlanid]}\n" \
		 "name #{params[:vlanname]} \n" \
		 "ip address #{params[:ownerip]}/#{params[:netmask]} \n" \
		 "vrrp vrid #{params[:vrid]} \n" \
                 "owner \n" \
	         "virtual-ip-address #{params[:ownerip]}/#{params[:netmask]} \n" \
		 "enable \n" \
		 "vlan #{params[:vlanid]} tagged A1"

  @backupconfig = "vlan #{params[:vlanid]}\n" \
                 "name #{params[:vlanname]} \n" \
                 "ip address #{params[:backupip]}/#{params[:netmask]} \n" \
                 "vrrp vrid #{params[:vrid]} \n" \
                 "owner \n" \
                 "virtual-ip-address #{params[:ownerip]}/#{params[:netmask]} \n" \
                 "enable \n" \
                 "vlan #{params[:vlanid]} tagged A1"



  @switchconfig = Switchconfiguration.new 	:vlanid		=> params[:vlanid],
						:vlanname	=> params[:vlanname],
						:vrid		=> params[:vrid],
                                                :network        => params[:network],
                                                :netmask        => params[:netmask],
                                                :ownerip        => params[:ownerip],
                                                :backupip       => params[:backupip],
						:ownerconfig	=> @ownerconfig,
						:backupconfig	=> @backupconfig

  
  if @switchconfig.save
    redirect "/cscm"
  else
    redirect "/addswitchconfig"
  end
end

get '/deleteswitchconfig/:id' do
  Switchconfiguration.find(params[:id]).destroy
  redirect '/cscm'
end


get '/eventlogs' do
  @logs_last50 = Logrequest.all(:limit => 50, :order => "created_at DESC")
  @logs_count = Logrequest.count
  @logs_10min = Logrequest.count( :created_at => { '$gt' => 10.minutes.ago, '$lt' => Time.now } )
  # @logs = Logrequest.all(:limit => 50)

  haml :eventlogs
end

get '/eventlogs/all' do
  @logs = Logrequest.all( :order => "created_at DESC")
  @logs_count = Logrequest.count

  haml :eventlogs_all
end


post '/whois' do

  if params[:host].empty?
    @results = "Please specify domain!"
    haml :whois
  else
    @host = params[:host]
    @results = Whois.whois(@host)

    request = Whoisrequest.new
    request.domain = @host
    request.result = @results
    request.save

    haml :whois
  end
end

# helpers
helpers do
  def testme
    puts "background-color:red"
  end

  def writefiles
    @domains = Domain.all
    
    transport = 	"tmp/transport"
    relay_domains =	"tmp/relay_domains"

    current_time = Time.now.to_i

    # check if transport file exists and rename it
    if File.exist?(transport)
      transport_new = transport + "_" + current_time.to_s
      File.rename(transport,transport_new)
      File.new(transport,"w+")
    end

    # check if relay_domain file exists and rename it
    if File.exist?(relay_domains)
      relay_domains_new = relay_domains + "_" + current_time.to_s
      File.rename(relay_domains,relay_domains_new)
      File.new(relay_domains,"w+")
    end

    Thread.new do
      @domains.each do |domain|
        File.open(transport,"a") do |transfile|
          transfile.puts(domain[:domain])
        end
        File.open(relay_domains,"a") do |relayfile|
          relayfile.puts(domain[:domain] + " OK")
        end
      end    

      File.open("tmp/lastactionrun","w+") do |file|
        file.puts(Time.now)
      end
    end

  end
end
