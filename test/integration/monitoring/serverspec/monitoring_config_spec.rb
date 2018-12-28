# Copyright 2014, Abiquo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "#{ENV['BUSSER_ROOT']}/../kitchen/roles/ansible-abiquo/test/integration/serverspec_helper"

describe 'Monitoring configuration' do
  include_examples 'common::config'

  it 'kairosdb is configured to use cassandra' do
    expect(file('/opt/kairosdb/conf/kairosdb.properties')).to contain('^kairosdb.jetty.port=8080')
    expect(file('/opt/kairosdb/conf/kairosdb.properties')).to contain('^kairosdb.service.datastore=org.kairosdb.datastore.cassandra.CassandraModule')
    expect(file('/opt/kairosdb/conf/kairosdb.properties')).to contain("^kairosdb.datastore.cassandra.host_list=#{host_inventory['facter']['ipaddress']}:9160")
  end

  it 'java 8 is the default one' do
    expect(command('java -version').stderr).to contain('version "1.8')
  end

  it 'has delorean properly configured' do
    expect(file('/etc/abiquo/watchtower/delorean.properties')).to exist
    expect(file('/etc/abiquo/watchtower/delorean.properties')).to contain('delorean.database.url = jdbc:mysql://localhost:3306/watchtower')
    expect(file('/etc/abiquo/watchtower/delorean.properties')).to contain('abiquo.rabbitmq.username = guest')
    expect(file('/etc/abiquo/watchtower/delorean.properties')).to contain('abiquo.rabbitmq.addresses = localhost:5671')
    expect(file('/etc/abiquo/watchtower/delorean.properties')).to contain('abiquo.rabbitmq.tls = true')
    expect(file('/etc/abiquo/watchtower/delorean.properties')).to contain('abiquo.rabbitmq.tls.trustallcertificates = true')
  end

  it 'has emmett properly configured' do
    expect(file('/etc/abiquo/watchtower/emmett.properties')).to exist
    expect(file('/etc/abiquo/watchtower/emmett.properties')).to contain('emmett.database.url = jdbc:mysql://localhost:3306/watchtower')
    expect(file('/etc/abiquo/watchtower/emmett.properties')).to contain('emmett.service.ssl = true')
    expect(file('/etc/abiquo/watchtower/emmett.properties')).to contain("emmett.service.certfile = /etc/pki/abiquo/#{host_inventory[:fqdn]}.crt")
    expect(file('/etc/abiquo/watchtower/emmett.properties')).to contain("emmett.service.keyfile = /etc/pki/abiquo/#{host_inventory[:fqdn]}.key.pkcs8")
    expect(file('/etc/abiquo/watchtower/emmett.properties')).to contain('abiquo.rabbitmq.username = guest')
    expect(file('/etc/abiquo/watchtower/emmett.properties')).to contain('abiquo.rabbitmq.addresses = localhost:5671')
    expect(file('/etc/abiquo/watchtower/emmett.properties')).to contain('abiquo.rabbitmq.tls = true')
    expect(file('/etc/abiquo/watchtower/emmett.properties')).to contain('abiquo.rabbitmq.tls.trustallcertificates = true')
  end

  it 'has the ssl certificates installed' do
    expect(file("/etc/pki/abiquo/#{host_inventory[:fqdn]}.crt")).to exist
    expect(file("/etc/pki/abiquo/#{host_inventory[:fqdn]}.key")).to exist
  end

  it 'has executed liquibase' do
    expect(command('mysql -N -B -e "select count(*) from information_schema.tables '\
                                   'where table_schema=\'watchtower\' '\
                                     'and table_name=\'DATABASECHANGELOG\'"').stdout).to eq "1\n"
  end
end
