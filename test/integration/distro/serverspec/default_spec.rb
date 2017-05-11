# Encoding: utf-8

require_relative 'spec_helper'

%w(varnish varnishlog varnishncsa).each do |varnish_service|
  describe service(varnish_service) do
    it 'enabled' do
      expect(subject).to be_enabled
    end
    it 'running' do
      expect(subject).to be_running
    end
  end
end

describe port(6081) do
  it 'listens on the correct port' do
    expect(subject).to be_listening.on('0.0.0.0').with('tcp')
  end
end

describe port(6082) do
  it 'listens on the correct port' do
    expect(subject).to be_listening.on('127.0.0.1').with('tcp')
  end
end

describe 'Storage bin file exists' do
  it 'Should find the storage file' do
    binfile = Dir.glob('/var/lib/varnish/**/*').find { |e| /default_storage.bin/ =~ e }
    expect(binfile).to be_truthy
  end
end

describe file('/etc/logrotate.d/varnishlog') do
  it 'varnishlog exists' do
    expect(subject).to be_file
  end
end

auth_params = '-S /etc/varnish/secret -T 127.0.0.1:6082'
# Not all distro versions have the backend.list command
describe command("varnishadm #{auth_params} vcl.show $(varnishadm #{auth_params} vcl.list|sed '/^\s*$/d'|tail -n 1|awk '{print $NF}')") do
  it 'exits succusfully' do
    expect(subject.exit_status).to eq 0
  end
  its 'backend is 127.0.0.10:8080' do
    expect(subject.stdout).to match(/127.0.0.1/)
    expect(subject.stdout).to match(/8080/)
  end
end

describe command("varnishadm #{auth_params} param.show thread_pool_max") do
  it 'exits zero' do
    expect(subject.exit_status).to eq 0
  end
  it 'returns \'500\' as the content' do
    expect(subject.stdout).to match(/ 500 /)
  end
end

describe command('curl localhost:6081') do
  it 'exits zero' do
    expect(subject.exit_status).to eq 0
  end
end

# Sleep to give the previous test time to show up in the logs
describe command('sleep 2; grep "ncsa_format_string_test" /var/log/varnish/varnishncsa.log') do
  it 'exits zero' do
    expect(subject.exit_status).to eq 0
  end
end