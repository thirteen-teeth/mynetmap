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

def client_request(server, request_type, request_parameters)
  limit = 1000
  client = PuppetDB::Client.new({
    :server => server,
    :pem    => {
      'key'     => "/etc/puppetlabs/puppet/ssl/private_keys/#{ENV['HOSTNAME']}.pem",
      'cert'    => "/etc/puppetlabs/puppet/ssl/certs/#{ENV['HOSTNAME']}.pem",
      'ca_file' => "/etc/puppetlabs/puppet/ssl/certs/ca.pem"
      }})
  response = client.request(
    "#{request_type}",
    request_parameters,
    {:limit => limit}
  )
  client_request_data = response.data
  return client_request_data
end

def get_client_list()
  nodes_request_type = ''
  nodes_request_parameters = 'nodes {}'
  nodes_response = client_request($puppetdb_server, nodes_request_type, nodes_request_parameters)
  clients = []
  nodes_response.each do |node_response|
    clients.push(node_response['certname'])
  end
  return clients
end

def get_class_data(nodes_response)
  per_node_classes = {}
  nodes_response.each do |nodes|
    classes_array = []
    request_type = 'resources'
    request_parameters = [:and,
        [:'=', 'type', 'Class'],
        [:'=', 'certname', nodes]
      ]
    class_response = client_request($puppetdb_server, request_type, request_parameters)
    sorted_classes = class_response.sort_by{|my_class| my_class['title'] }
    sorted_classes.each do |sorted_class|
      classes_array.push(sorted_class['title'])
    end
    per_node_classes[nodes] = { 'classes' => classes_array }
  end
  return per_node_classes
end

$puppetdb_server = 'https://master.puppetdomain:8081'

client_array = get_client_list()
class_data = get_class_data(client_array)
puts JSON.pretty_generate(class_data)
