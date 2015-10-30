# encoding: UTF-8
#
# Cookbook Name:: openstack-common
# Attributes:: default
#
# Copyright 2012-2013, AT&T Services, Inc.
# Copyright 2013-2014, SUSE Linux GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Set to some text value if you want templated config files
# to contain a custom banner at the top of the written file
default['openstack']['common']['custom_template_banner'] = '
# This file autogenerated by Chef
# Do not edit, changes will be overwritten
'

# OpenStack services and their project names
default['openstack']['common']['services'] = {
  'bare-metal' => 'ironic',
  'block-storage' => 'cinder',
  'compute' => 'nova',
  'dashboard' => 'horizon',
  'database' => 'trove',
  'identity' => 'keystone',
  'image' => 'glance',
  'network' => 'neutron',
  'object-storage' => 'swift',
  'orchestration' => 'heat',
  'telemetry' => 'ceilometer'
}

# Setting this to True means that database passwords and service user
# passwords for Keystone will be easy-to-remember values -- they will be
# the same value as the key. For instance, if a cookbook calls the
# ::Openstack::secret routine like so:
#
# pass = secret "passwords", "nova"
#
# The value of pass will be "nova"
#

# Use data bags for storing passwords
# Set this to false in order to get the passwords from attributes like:
# node['openstack']['secret'][key][type]
default['openstack']['use_databags'] = true

# Set databag type
# acceptable values 'encrypted', 'standard', 'vault'
# Set this to 'standard' in order to use regular databags.
# this is not recommended for anything other than dev/CI
# type environments.  Storing real secrets in plaintext = craycray.
# In addition to the encrypted data_bags which are an included
# feature of the official chef project, you can use 'vault' to
# encrypt your secrets with the method provided in the chef-vault gem.
default['openstack']['databag_type'] = 'encrypted'
default['openstack']['vault_gem_version'] = '~> 2.3'

# Default attributes when not using data bags (use_databags = false)
node['openstack']['common']['services'].each_key do |service|
  %w(user service db token).each do |type|
    default['openstack']['secret'][service][type] = "#{service}-#{type}"
  end
end

# The type of token signing to use (uuid or pki)
default['openstack']['auth']['strategy'] = 'pki'

# Set to true where using self-signed certs (in testing environments)
default['openstack']['auth']['validate_certs'] = true

# ========================= Encrypted Databag Setup ===========================
#
# The openstack-common cookbook's default library contains a `secret`
# routine that looks up the value of encrypted databag values. This routine
# uses the secret key file located at the following location to decrypt the
# values in the data bag.
default['openstack']['secret']['key_path'] = '/etc/chef/openstack_data_bag_secret'

# The name of the encrypted data bag that stores openstack secrets
default['openstack']['secret']['secrets_data_bag'] = 'secrets'

# The name of the encrypted data bag that stores service user passwords, with
# each key in the data bag corresponding to a named OpenStack service, like
# "nova", "cinder", etc.
default['openstack']['secret']['service_passwords_data_bag'] = 'service_passwords'

# The name of the encrypted data bag that stores DB passwords, with
# each key in the data bag corresponding to a named OpenStack database, like
# "nova", "cinder", etc.
default['openstack']['secret']['db_passwords_data_bag'] = 'db_passwords'

# The name of the encrypted data bag that stores Keystone user passwords, with
# each key in the data bag corresponding to a user (Keystone or otherwise).
default['openstack']['secret']['user_passwords_data_bag'] = 'user_passwords'

# ========================= Package and Repository Setup ======================
#
# Various Linux distributions provide OpenStack packages and repositories.
# The provide some sensible defaults, but feel free to override per your
# needs.

# The coordinated release of OpenStack codename
default['openstack']['release'] = 'liberty'

# The Ubuntu Cloud Archive has packages for multiple Ubuntu releases. For
# more information, see: https://wiki.ubuntu.com/ServerTeam/CloudArchive.
# In the component strings, %codename% will be replaced by the value of
# the node['lsb']['codename'] Ohai value and %release% will be replaced
# by the value of node['openstack']['release']
#
# Change ['openstack']['apt']['update_apt_cache'] to true if you would like
# have the cache automaticly updated
default['openstack']['apt']['update_apt_cache'] = false
default['openstack']['apt']['live_updates_enabled'] = true
default['openstack']['apt']['uri'] = 'http://ubuntu-cloud.archive.canonical.com/ubuntu'
default['openstack']['apt']['components'] = ["#{node['lsb']['codename']}-updates/#{node['openstack']['release']}", 'main']
# For the SRU packaging, use this:
# default['openstack']['apt']['components'] = [ '%codename%-proposed/%release%', 'main' ]

default['openstack']['zypp']['repo-key'] = 'd85f9316'  # 32 bit key ID
default['openstack']['zypp']['uri'] = 'http://download.opensuse.org/repositories/Cloud:/OpenStack:/%release%/%suse-release%/'

default['openstack']['yum']['rdo_enabled'] = true
default['openstack']['yum']['uri'] = "http://mirror.centos.org/centos/$releasever/cloud/$basearch/openstack-#{node['openstack']['release']}"
default['openstack']['yum']['repo-key'] = 'https://raw.githubusercontent.com/redhat-openstack/rdo-release/master/RPM-GPG-KEY-CentOS-SIG-Cloud'
# Enforcing GnuPG signature check for RDO repo. Set this to false if you want to disable the check.
default['openstack']['yum']['gpgcheck'] = true
# ======================== OpenStack Endpoints ================================
#
# OpenStack recipes often need information about the various service
# endpoints in the deployment. For instance, the cookbook that deploys
# the Nova API service will need to set the glance_api_servers configuration
# option in the nova.conf, and the cookbook setting up the Glance image
# service might need information on the Swift proxy endpoint, etc. Having
# all of this related OpenStack endpoint information in a single set of
# common attributes in the openstack-common cookbook attributes means that
# instead of doing funky role-based lookups, a deployment zone's OpenStack
# endpoint information can simply be accessed by having the
# openstack-common::default recipe added to some base role definition file
# that all OpenStack nodes add to their run list.
#
# node['openstack']['endpoints'] is a hash of hashes, where each value hash
# contains one of more of the following keys:
#
#  - scheme
#  - uri
#  - host
#  - port
#  - path
#  - bind_interface
#
# If the uri key is set, its value is used as the full URI for the endpoint.
# If the uri key is not set, the endpoint's full URI is constructed from the
# component parts. This allows setups that use some standardized DNS names for
# OpenStack service endpoints in a deployment zone as well as setups that
# instead assign IP addresses (for an actual node or a load balanced virtual
# IP) in a network to a particular OpenStack service endpoint. If the
# bind_interface is set, it will set the host IP in the
# set_endpoints_by_interface recipe.
#
# If you wish to use different values for the admin, public, and internal
# URIs for a service, you can easily do so by putting that service's
# information within the node['openstack']['endpoints'][type][service] hash
# (where type is one of 'admin', 'public', or 'internal').
# For example, to use a special public URI for compute-api, it could be
# specified within...
# node['openstack']['endpoints']['public']['compute-api'] = ...
#
# If you have no need for separate URIs for any of the admin, public, or
# internal endpoints for compute-api, then you could just set the general
# service endpoint within...
# node['openstack']['endpoints']['compute-api'] = ...

# ******************** OpenStack Identity Endpoints ***************************
default['openstack']['endpoints']['host'] = '127.0.0.1'
default['openstack']['endpoints']['family'] = 'inet'
default['openstack']['endpoints']['scheme'] = 'http'

# Note: The ['<service-name>-bind'] for each service exist so that a user can
# have a service bind to a local IP per API node, that is different to the
# actual endpoint for that service, which may be a load balanced IP.
default['openstack']['endpoints']['bind-host'] = '127.0.0.1'
# Also allow a common bind interface for easier configuration.
default['openstack']['endpoints']['bind_interface'] = nil

# The OpenStack Identity (Keystone) API endpoint. This is commonly called
# the Keystone Service endpoint...

# NOTE(mancdaz): There is a single 'identity-bind' mash that is used
# by the identity cookbook, for both service and admin endpoint binds.
# This is because keystone presents two ports but only a single service,
# that can only be bound to a single IP.
default['openstack']['endpoints']['identity-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['identity-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['identity-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['identity-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['identity-api']['port'] = '5000'
default['openstack']['endpoints']['identity-api']['path'] = '/v2.0'
default['openstack']['endpoints']['identity-api']['bind_interface'] = nil

# The OpenStack Identity (Keystone) Internal API endpoint
# For a reference architecture this is a sensable default, however with a more
# complex network setup the public endpoint may not be reachable by internal
# systems, thus the ability to set this to something different must be present.
# Even if the public endpoint is reachable there may be other reasons to send
# interal communications to a different endpoint, for security or auditing
# purposes for example.
# Generally this listens on the same IP as the admin interface, but with the
# public pipeline(5000) instead of the admin pipeline(35357).
default['openstack']['endpoints']['identity-internal']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['identity-internal']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['identity-internal']['port'] = '5000'
default['openstack']['endpoints']['identity-internal']['path'] = '/v2.0'
default['openstack']['endpoints']['identity-internal']['bind_interface'] = nil

# The OpenStack Identity (Keystone) Admin API endpoint
default['openstack']['endpoints']['identity-admin-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['identity-admin-bind']['port'] = '35357'
default['openstack']['endpoints']['identity-admin-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['identity-admin']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['identity-admin']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['identity-admin']['port'] = '35357'
default['openstack']['endpoints']['identity-admin']['path'] = '/v2.0'
default['openstack']['endpoints']['identity-admin']['bind_interface'] = nil

# ****************** OpenStack Compute Endpoints ******************************

# The OpenStack Compute (Nova) Native API endpoint
default['openstack']['endpoints']['compute-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['compute-api-bind']['port'] = '8774'
default['openstack']['endpoints']['compute-api-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['compute-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['compute-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['compute-api']['port'] = '8774'
default['openstack']['endpoints']['compute-api']['path'] = '/v2/%(tenant_id)s'
default['openstack']['endpoints']['compute-api']['bind_interface'] = nil

# The OpenStack Compute (Nova) EC2 API endpoint
default['openstack']['endpoints']['compute-ec2-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['compute-ec2-api-bind']['port'] = '8773'
default['openstack']['endpoints']['compute-ec2-api-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['compute-ec2-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['compute-ec2-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['compute-ec2-api']['port'] = '8773'
default['openstack']['endpoints']['compute-ec2-api']['path'] = '/services/Cloud'
default['openstack']['endpoints']['compute-ec2-api']['bind_interface'] = nil

# The OpenStack Compute (Nova) EC2 Admin API endpoint
default['openstack']['endpoints']['compute-ec2-admin-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['compute-ec2-admin-bind']['port'] = '8773'
default['openstack']['endpoints']['compute-ec2-admin-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['compute-ec2-admin']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['compute-ec2-admin']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['compute-ec2-admin']['port'] = '8773'
default['openstack']['endpoints']['compute-ec2-admin']['path'] = '/services/Admin'
default['openstack']['endpoints']['compute-ec2-admin']['bind_interface'] = nil

# The OpenStack Compute (Nova) XVPvnc endpoint
default['openstack']['endpoints']['compute-xvpvnc-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['compute-xvpvnc-bind']['port'] = '6081'
default['openstack']['endpoints']['compute-xvpvnc-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['compute-xvpvnc']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['compute-xvpvnc']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['compute-xvpvnc']['port'] = '6081'
default['openstack']['endpoints']['compute-xvpvnc']['path'] = '/console'
default['openstack']['endpoints']['compute-xvpvnc']['bind_interface'] = nil

# The OpenStack Compute (Nova) novnc endpoint
default['openstack']['endpoints']['compute-novnc-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['compute-novnc-bind']['port'] = '6080'
default['openstack']['endpoints']['compute-novnc-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['compute-novnc']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['compute-novnc']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['compute-novnc']['port'] = '6080'
default['openstack']['endpoints']['compute-novnc']['path'] = '/vnc_auto.html'
default['openstack']['endpoints']['compute-novnc']['bind_interface'] = nil

# The OpenStack Compute (Nova) vnc endpoint
default['openstack']['endpoints']['compute-vnc-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['compute-vnc-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['compute-vnc']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['compute-vnc']['scheme'] = nil
default['openstack']['endpoints']['compute-vnc']['port'] = nil
default['openstack']['endpoints']['compute-vnc']['path'] = nil
default['openstack']['endpoints']['compute-vnc']['bind_interface'] = nil

# The OpenStack Compute (Nova) vnc proxy endpoint
default['openstack']['endpoints']['compute-vnc-proxy-bind']['host'] = node['openstack']['endpoints']['compute-vnc-bind']['host']
default['openstack']['endpoints']['compute-vnc-proxy-bind']['bind_interface'] = node['openstack']['endpoints']['compute-vnc-bind']['bind_interface']

# The OpenStack Compute (Nova) metadata API endpoint
default['openstack']['endpoints']['compute-metadata-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['compute-metadata-api-bind']['port'] = '8775'
default['openstack']['endpoints']['compute-metadata-api-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['compute-metadata-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['compute-metadata-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['compute-metadata-api']['port'] = '8775'
default['openstack']['endpoints']['compute-metadata-api']['path'] = nil
default['openstack']['endpoints']['compute-metadata-api']['bind_interface'] = nil

# The OpenStack Compute (Nova) serial console endpoint
default['openstack']['endpoints']['compute-serial-console-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['compute-serial-console-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

# The OpenStack Compute (Nova) serial proxy endpoint
default['openstack']['endpoints']['compute-serial-proxy']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['compute-serial-proxy']['scheme'] = 'ws'
default['openstack']['endpoints']['compute-serial-proxy']['port'] = '6083'
default['openstack']['endpoints']['compute-serial-proxy']['path'] = '/'
default['openstack']['endpoints']['compute-serial-proxy']['bind_interface'] = nil

# ******************** OpenStack Network Endpoints ****************************

# The OpenStack Network (Neutron) API endpoint.
default['openstack']['endpoints']['network-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['network-api-bind']['port'] = '9696'
default['openstack']['endpoints']['network-api-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['network-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['network-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['network-api']['port'] = '9696'
# neutronclient appends the protocol version to the endpoint URL, so the
# path needs to be empty
default['openstack']['endpoints']['network-api']['path'] = ''
default['openstack']['endpoints']['network-api']['bind_interface'] = nil

# The OpenStack Network Linux Bridge endpoint
default['openstack']['endpoints']['network-linuxbridge']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['network-linuxbridge']['scheme'] = nil
default['openstack']['endpoints']['network-linuxbridge']['port'] = nil
default['openstack']['endpoints']['network-linuxbridge']['path'] = nil
default['openstack']['endpoints']['network-linuxbridge']['bind_interface'] = nil

# The OpenStack Network Open vSwitch endpoint
default['openstack']['endpoints']['network-openvswitch']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['network-openvswitch']['scheme'] = nil
default['openstack']['endpoints']['network-openvswitch']['port'] = nil
default['openstack']['endpoints']['network-openvswitch']['path'] = nil
default['openstack']['endpoints']['network-openvswitch']['bind_interface'] = nil

# ******************** OpenStack Image Endpoints ******************************

# The OpenStack Image (Glance) API endpoint
default['openstack']['endpoints']['image-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['image-api-bind']['port'] = '9292'
default['openstack']['endpoints']['image-api-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['image-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['image-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['image-api']['port'] = '9292'
# The glance client appends the protocol version to the endpoint URL,
# so the path needs to be empty
default['openstack']['endpoints']['image-api']['path'] = ''
default['openstack']['endpoints']['image-api']['bind_interface'] = nil

# The OpenStack Image (Glance) Registry API endpoint
default['openstack']['endpoints']['image-registry-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['image-registry-bind']['port'] = '9191'
default['openstack']['endpoints']['image-registry-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['image-registry']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['image-registry']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['image-registry']['port'] = '9191'
default['openstack']['endpoints']['image-registry']['path'] = '/v2'
default['openstack']['endpoints']['image-registry']['bind_interface'] = nil

# ******************** OpenStack Volume Endpoints *****************************

# The OpenStack Volume (Cinder) API endpoint
default['openstack']['endpoints']['block-storage-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['block-storage-api-bind']['port'] = '8776'
default['openstack']['endpoints']['block-storage-api-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['block-storage-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['block-storage-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['block-storage-api']['port'] = '8776'
default['openstack']['endpoints']['block-storage-api']['path'] = '/v2/%(tenant_id)s'
default['openstack']['endpoints']['block-storage-api']['bind_interface'] = nil

# ******************** OpenStack Object Storage Endpoint *****************************

# The OpenStack Object Storage (Swift) API endpoint
default['openstack']['endpoints']['object-storage-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['object-storage-api-bind']['port'] = '8080'
default['openstack']['endpoints']['object-storage-api-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['object-storage-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['object-storage-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['object-storage-api']['port'] = '8080'
default['openstack']['endpoints']['object-storage-api']['path'] = '/v1/AUTH_%(tenant_id)s'
default['openstack']['endpoints']['object-storage-api']['bind_interface'] = nil

# ******************** OpenStack Metering Endpoints ***************************

# The OpenStack Metering (Ceilometer) API endpoint
default['openstack']['endpoints']['telemetry-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['telemetry-api-bind']['port'] = '8777'
default['openstack']['endpoints']['telemetry-api-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['telemetry-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['telemetry-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['telemetry-api']['port'] = '8777'
# The ceilometer client appends the protocol version to the endpoint URL,
# so the path needs to be empty
default['openstack']['endpoints']['telemetry-api']['path'] = ''
default['openstack']['endpoints']['telemetry-api']['bind_interface'] = nil

# ******************** OpenStack Orchestration Endpoints ***************************

# The OpenStack Orchestration (Heat) API endpoint
default['openstack']['endpoints']['orchestration-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['orchestration-api-bind']['port'] = '8004'
default['openstack']['endpoints']['orchestration-api-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['orchestration-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['orchestration-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['orchestration-api']['port'] = '8004'
default['openstack']['endpoints']['orchestration-api']['path'] = '/v1/%(tenant_id)s'
default['openstack']['endpoints']['orchestration-api']['bind_interface'] = nil

# The OpenStack Orchestration (Heat) CloudFormation API endpoint
default['openstack']['endpoints']['orchestration-api-cfn-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['orchestration-api-cfn-bind']['port'] = '8000'
default['openstack']['endpoints']['orchestration-api-cfn-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['orchestration-api-cfn']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['orchestration-api-cfn']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['orchestration-api-cfn']['port'] = '8000'
default['openstack']['endpoints']['orchestration-api-cfn']['path'] = '/v1'
default['openstack']['endpoints']['orchestration-api-cfn']['bind_interface'] = nil

# The OpenStack Orchestration (Heat) CloudWatch API endpoint
default['openstack']['endpoints']['orchestration-api-cloudwatch-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['orchestration-api-cloudwatch-bind']['port'] = '8003'
default['openstack']['endpoints']['orchestration-api-cloudwatch-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['orchestration-api-cloudwatch']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['orchestration-api-cloudwatch']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['orchestration-api-cloudwatch']['port'] = '8003'
default['openstack']['endpoints']['orchestration-api-cloudwatch']['path'] = '/v1'
default['openstack']['endpoints']['orchestration-api-cloudwatch']['bind_interface'] = nil

# ******************** OpenStack Database Endpoints ***************************

# The OpenStack Database (Trove) API endpoint
default['openstack']['endpoints']['database-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['database-api-bind']['port'] = '8779'
default['openstack']['endpoints']['database-api-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['database-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['database-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['database-api']['port'] = '8779'
default['openstack']['endpoints']['database-api']['path'] = '/v1.0/%(tenant_id)s'
default['openstack']['endpoints']['database-api']['bind_interface'] = nil

# ******************** OpenStack Bare Metal Endpoints *****************************

# The OpenStack Bare Metal (Ironic) API endpoint
default['openstack']['endpoints']['bare-metal-api-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['bare-metal-api-bind']['port'] = '6385'
default['openstack']['endpoints']['bare-metal-api-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

default['openstack']['endpoints']['bare-metal-api']['host'] = node['openstack']['endpoints']['host']
default['openstack']['endpoints']['bare-metal-api']['scheme'] = node['openstack']['endpoints']['scheme']
default['openstack']['endpoints']['bare-metal-api']['port'] = '6385'
default['openstack']['endpoints']['bare-metal-api']['path'] = ''
default['openstack']['endpoints']['bare-metal-api']['bind_interface'] = nil

# ****************** OpenStack Dashboard Endpoints ******************************

# The OpenStack Dashboard non-SSL endpoint
default['openstack']['endpoints']['dashboard-http-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['dashboard-http-bind']['port'] = '80'
default['openstack']['endpoints']['dashboard-http-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

# The OpenStack Dashboard SSL endpoint
default['openstack']['endpoints']['dashboard-https-bind']['host'] = node['openstack']['endpoints']['bind-host']
default['openstack']['endpoints']['dashboard-https-bind']['port'] = '443'
default['openstack']['endpoints']['dashboard-https-bind']['bind_interface'] = node['openstack']['endpoints']['bind_interface']

# ********************************************************************************

# Alternately, if you used some standardized DNS naming scheme, you could
# do something like this, which would override any part-wise specifications above.
#
# default['openstack']['endpoints']['identity-api']['uri']         = 'https://identity.example.com:35357/v2.0'
# default['openstack']['endpoints']['identity-admin']['uri']       = 'https://identity.example.com:5000/v2.0'
# default['openstack']['endpoints']['compute-api']['uri']          = 'https://compute.example.com:8774/v2/%(tenant_id)s'
# default['openstack']['endpoints']['compute-ec2-api']['uri']      = 'https://ec2.example.com:8773/services/Cloud'
# default['openstack']['endpoints']['compute-ec2-admin']['uri']    = 'https://ec2.example.com:8773/services/Admin'
# default['openstack']['endpoints']['compute-xvpvnc']['uri']       = 'https://xvpvnc.example.com:6081/console'
# default['openstack']['endpoints']['compute-novnc']['uri']        = 'https://novnc.example.com:6080/vnc_auto.html'
# default['openstack']['endpoints']['image-api']['uri']            = 'https://image.example.com:9292/v2'
# default['openstack']['endpoints']['image-registry']['uri']       = 'https://image.example.com:9191/v2'
# default['openstack']['endpoints']['block-storage-api']['uri']           = 'https://volume.example.com:8776/v1/%(tenant_id)s'
# default['openstack']['endpoints']['telemetry-api']['uri']        = 'https://telemetry.example.com:9000/v1'
# default['openstack']['endpoints']['orchestration-api']['uri']               = 'https://orchestration.example.com:8004//v1/%(tenant_id)s'
# default['openstack']['endpoints']['orchestration-api-cfn']['uri']           = 'https://orchestration.example.com:8000/v1'
# default['openstack']['endpoints']['orchestration-api-cloudwatch']['uri']    = 'https://orchestration.example.com:8003/v1'

# Set a default region that other regions are set to - such that changing the region for all services can be done in one place
default['openstack']['region'] = 'RegionOne'

# Set a default auth api version that other components use to interact with identity service.
# Allowed auth API versions: v2.0 or v3.0. By default, it is set to v2.0.
default['openstack']['api']['auth']['version'] = 'v2.0'

# Allow configured loggers in logging.conf
default['openstack']['logging']['loggers'] = {
  'root' => {
    'level' => 'NOTSET',
    'handlers' => 'devel'
  },
  'ceilometer' => {
    'level' => 'DEBUG',
    'handlers' => 'prod,debug',
    'qualname' => 'ceilometer'
  },
  'cinder' => {
    'level' => 'DEBUG',
    'handlers' => 'prod,debug',
    'qualname' => 'cinder'
  },
  'glance' => {
    'level' => 'DEBUG',
    'handlers' => 'prod,debug',
    'qualname' => 'glance'
  },
  'horizon' => {
    'level' => 'DEBUG',
    'handlers' => 'prod,debug',
    'qualname' => 'horizon'
  },
  'keystone' => {
    'level' => 'DEBUG',
    'handlers' => 'prod,debug',
    'qualname' => 'keystone'
  },
  'nova' => {
    'level' => 'DEBUG',
    'handlers' => 'prod,debug',
    'qualname' => 'nova'
  },
  'neutron' => {
    'level' => 'DEBUG',
    'handlers' => 'prod,debug',
    'qualname' => 'neutron'
  },
  'trove' => {
    'level' => 'DEBUG',
    'handlers' => 'prod,debug',
    'qualname' => 'trove'
  },
  'amqplib' => {
    'level' => 'WARNING',
    'handlers' => 'stderr',
    'qualname' => 'amqplib'
  },
  'sqlalchemy' => {
    'level' => 'WARNING',
    # "level' => 'INFO" logs SQL queries.
    # "level' => 'DEBUG" logs SQL queries and results.
    # "level' => 'WARNING" logs neither.  (Recommended for production systems.)
    'handlers' => 'stderr',
    'qualname' => 'sqlalchemy'
  },
  'boto' => {
    'level' => 'WARNING',
    'handlers' => 'stderr',
    'qualname' => 'boto'
  },
  'suds' => {
    'level' => 'INFO',
    'handlers' => 'stderr',
    'qualname' => 'suds'
  },
  'eventletwsgi' => {
    'level' => 'WARNING',
    'handlers' => 'stderr',
    'qualname' => 'eventlet.wsgi.server'
  },
  'nova_api_openstack_wsgi' => {
    'level' => 'WARNING',
    'handlers' => 'prod,debug',
    'qualname' => 'nova.api.openstack.wsgi'
  },
  'nova_osapi_compute_wsgi_server' => {
    'level' => 'WARNING',
    'handlers' => 'prod,debug',
    'qualname' => 'nova.osapi_compute.wsgi.server'
  }
}

# Allow configured formatters in logging.conf
default['openstack']['logging']['formatters'] = {
  'normal' => {
    'format' => '%(asctime)s %(levelname)s %(message)s'
  },
  'normal_with_name' => {
    'format' => '[%(name)s]: %(asctime)s %(levelname)s %(message)s'
  },
  'debug' => {
    'format' => '[%(name)s]: %(asctime)s %(levelname)s %(module)s.%(funcName)s %(message)s'
  },
  'syslog_with_name' => {
    'format' => '%(name)s: %(levelname)s %(message)s'
  },
  'syslog_debug' => {
    'format' => '%(name)s: %(levelname)s %(module)s.%(funcName)s %(message)s'
  }
}

# Allow configured logging handlers in logging.conf
default['openstack']['logging']['handlers'] = {
  'stderr' => {
    'args' => '(sys.stderr,)',
    'class' => 'StreamHandler',
    'formatter' => 'debug'
  },
  'devel' => {
    'args' => '(sys.stdout,)',
    'class' => 'StreamHandler',
    'formatter' => 'debug',
    'level' => 'NOTSET'
  },
  'prod' => {
    'args' => '((\'/dev/log\'), handlers.SysLogHandler.LOG_LOCAL0)',
    'class' => 'handlers.SysLogHandler',
    'formatter' => 'syslog_with_name',
    'level' => 'INFO'
  },
  'debug' => {
    'args' => '((\'/dev/log\'), handlers.SysLogHandler.LOG_LOCAL1)',
    'class' => 'handlers.SysLogHandler',
    'formatter' => 'syslog_debug',
    'level' => 'DEBUG'
  }
}

default['openstack']['memcached_servers'] = nil

# Default sysctl settings
default['openstack']['sysctl']['net.ipv4.conf.all.rp_filter'] = 0
default['openstack']['sysctl']['net.ipv4.conf.default.rp_filter'] = 0

# Default OpenStack Network Type: nova (optional: neutron)
default['openstack']['compute']['network']['service_type'] = 'nova'

case node['platform_family']
when 'rhel', 'suse'
  default['openstack']['common']['platform'] = {
    'common_client_packages' => ['python-openstackclient'],
    'package_overrides' => ''
  }
when 'debian'
  default['openstack']['common']['platform'] = {
    'common_client_packages' => ['python-openstackclient'],
    'package_overrides' => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end

# The name of the Chef role that installs the Keystone Service API
default['openstack']['identity_service_chef_role'] = 'os-identity'

# The name of the Chef role that sets up the compute worker
default['openstack']['compute_worker_chef_role'] = 'os-compute-worker'

# Array of bare options for openrc (e.g. 'option=value')
default['openstack']['misc_openrc'] = nil

# openrc location and owner
default['openstack']['openrc']['path'] = '/root'
default['openstack']['openrc']['file'] = 'openrc'
default['openstack']['openrc']['user'] = 'root'
default['openstack']['openrc']['group'] = 'root'
default['openstack']['openrc']['file_mode'] = '0600'
default['openstack']['openrc']['path_mode'] = '0700'
