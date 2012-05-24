require 'socket'
require 'mongo_mapper'

# mongo stuff
# needs to be the same configuration as in admintools.rb so the logviewer can read the data
MongoMapper.connection = Mongo::Connection.new('localhost',27017, :pool_size => 5, :timeout => 5)
MongoMapper.database = 'admintools'

class Logrequest
   include MongoMapper::Document
   key :data,        	String,         :required => true
   key :source,		String
   key :priority, 	String
   key :facility,	String
   key :facility_name,	String
   key :severity,	String
   key :severity_name,	String
   key :message,	String
   timestamps!
end

class Convert
  def severity_to_name(severity)
    case
      when severity == 0 then severity_name = "Emergency"
      when severity == 1 then severity_name = "Alert"
      when severity == 2 then severity_name = "Critical"
      when severity == 3 then severity_name = "Error"
      when severity == 4 then severity_name = "Warning"
      when severity == 5 then severity_name = "Notice"
      when severity == 6 then severity_name = "Info"
      when severity == 7 then severity_name = "Debug"
      else severity_name = "Unknown"
    end
  end

  def facility_to_name(facility)
    case
      when facility == 0 then facility_name 	= "Kernel"
      when facility == 1 then facility_name 	= "User-Lvl"
      when facility == 2 then facility_name 	= "Mail"
      when facility == 3 then facility_name 	= "System"
      when facility == 4 then facility_name 	= "Security"
      when facility == 5 then facility_name 	= "Message"
      when facility == 6 then facility_name 	= "LP"
      when facility == 7 then facility_name 	= "News"
      when facility == 8 then facility_name 	= "UUCP"
      when facility == 9 then facility_name 	= "Clock"
      when facility == 10 then facility_name 	= "Security"
      when facility == 11 then facility_name	= "FTP"
      when facility == 12 then facility_name	= "NTP"
      when facility == 13 then facility_name	= "LogAudit"
      when facility == 14 then facility_name	= "LogAlert"
      when facility == 15 then facility_name	= "Clock"
      when facility == 16 then facility_name 	= "Local0"
      when facility == 17 then facility_name    = "Local1"
      when facility == 18 then facility_name    = "Local2"
      when facility == 19 then facility_name    = "Local3"
      when facility == 20 then facility_name    = "Local4"
      when facility == 21 then facility_name    = "Local5"
      when facility == 22 then facility_name    = "Local6"
      when facility == 23 then facility_name    = "Local7"
      else facility_name = "Unknown"
    end
  end  
end


class UDPServer
  def initialize(port)
    @port = port
  end

  def start
    @socket = UDPSocket.new
    @socket.bind('', @port)
      udp_thread = Thread.new do
        while true
          packet = @socket.recvfrom(8096)

          priopart = packet[0]
          priority = priopart[/\A<(.*?)>/, 1]
          facility = priority.to_i / 8
          severity = priority.to_i - ( facility.to_i * 8 )
          message = priopart.split(' ')[3..-1].join(' ')

	  message.force_encoding("Windows-1252")
	  message.encode!('UTF-8')

	  packet[0].force_encoding("Windows-1252")
	  packet[0].encode!('UTF-8')

          logrequest = Logrequest.new
          logrequest.data = packet[0]
          logrequest.source = packet[1][3]
	  logrequest.priority = priority
	  logrequest.facility = facility
          logrequest.facility_name = Convert.new.facility_to_name(facility)
	  logrequest.severity = severity
	  logrequest.severity_name = Convert.new.severity_to_name(severity)
          logrequest.message = message
          logrequest.save
        end
      end
      udp_thread.join
  end
end

server = UDPServer.new(514)
server.start

