#!/bin/env ruby

# > Environment setup <
# sudo dnf install git wget gcc bzip2 openssl-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel
# wget -q https://raw.githubusercontent.com/rbenv/rbenv-installer/main/bin/rbenv-installer -O- | bash
# echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
# echo 'eval "$(rbenv init -)"' >> ~/.bashrc
# source ~/.bashrc
# rbenv -v
# rbenv install -l
# rbenv install 3.0.2
# rbenv global 3.0.2
# gem install puppetdb-ruby

require 'puppetdb'
require 'json'

client = PuppetDB::Client.new({
  :server => 'https://master.puppetdomain:8081',
  :pem    => {
    'key'     => "/etc/puppetlabs/puppet/ssl/private_keys/#{ENV['HOSTNAME']}.pem",
    'cert'    => "/etc/puppetlabs/puppet/ssl/certs/#{ENV['HOSTNAME']}.pem",
    'ca_file' => "/etc/puppetlabs/puppet/ssl/certs/ca.pem"
    }})

#query_string = 'fact_contents { path ~> ["networking","interfaces",".*","mac"] }'
#query_string = 'nodes { certname = "master.puppetdomain" }'
#query_string = 'facts[name, value] {certname = "master.puppetdomain"}'
#response = client.request(
#  '',
#  "#{query_string}",
#  {:limit => 1000}
#)

#limit will be used everywhere for the most part
limit = 1000
myobject = Hash.new

request_type = ''
request_parameters = 'nodes {}'

nodes_response = client.request(
  "#{request_type}",
  request_parameters,
  {:limit => limit}
)

nodes_response.data.each do |nodes|

  request_type = 'resources'
  request_parameters = [:and,
      [:'=', 'type', 'Class'],
      [:'=', 'certname', nodes['certname']]
    ]

  response = client.request(
    "#{request_type}",
    request_parameters,
    {:limit => limit}
  )

  resources = response.data
  myobject[nodes['certname']] = { 'resources' => resources }

end
