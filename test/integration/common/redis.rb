# Copyright 2014,
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

shared_examples 'common::redis' do
  it 'has the redis package installed' do
    expect(package('redis')).to be_installed
  end

  it 'has redis running' do
    expect(service("redis")).to be_enabled
    expect(service("redis")).to be_running
    expect(service("redis")).to be_running.under('systemd') if os[:release].to_i >= 7
    expect(port(6379)).to be_listening
  end
end
