# define: nginx::resource::streamhost
#
# This definition creates a virtual host
#
# Parameters:
#   [*ensure*]              - Enables or disables the specified streamhost
#     (present|absent)
#   [*listen_ip*]           - Default IP Address for NGINX to listen with this
#     streamhost on. Defaults to all interfaces (*)
#   [*listen_port*]         - Default IP Port for NGINX to listen with this
#     streamhost on. Defaults to TCP 80
#   [*listen_options*]      - Extra options for listen directive like
#     'default' to catchall. Undef by default.
#   [*ipv6_enable*]         - BOOL value to enable/disable IPv6 support
#     (false|true). Module will check to see if IPv6 support exists on your
#     system before enabling.
#   [*ipv6_listen_ip*]      - Default IPv6 Address for NGINX to listen with
#     this streamhost on. Defaults to all interfaces (::)
#   [*ipv6_listen_port*]    - Default IPv6 Port for NGINX to listen with this
#     streamhost on. Defaults to TCP 80
#   [*ipv6_listen_options*] - Extra options for listen directive like 'default'
#     to catchall. Template will allways add ipv6only=on. While issue
#     jfryman/puppet-nginx#30 is discussed, default value is 'default'.
#   [*proxy*]               - Proxy server(s) for the root location to connect
#     to.  Accepts a single value, can be used in conjunction with
#     nginx::resource::upstream
#   [*proxy_read_timeout*]  - Override the default the proxy read timeout value
#     of 90 seconds
#   [*resolver*]            - Array: Configures name servers used to resolve
#     names of upstream servers into addresses.
#   [*server_name*]         - List of streamhost names for which this streamhost will
#     respond. Default [$name].
#   [*raw_prepend*]            - A single string, or an array of strings to
#     prepend to the server directive (after cfg prepend directives). NOTE:
#     YOU are responsible for a semicolon on each line that requires one.
#   [*raw_append*]             - A single string, or an array of strings to
#     append to the server directive (after cfg append directives). NOTE:
#     YOU are responsible for a semicolon on each line that requires one.
#   [*owner*]                   - Defines owner of the .conf file
#   [*group*]                   - Defines group of the .conf file
#   [*mode*]                    - Defines mode of the .conf file
#                                 Default to return 503
# Actions:
#
# Requires:
#
# Sample Usage:
#  nginx::resource::streamhost { 'test2.local':
#    ensure   => present,
#  }
define nginx::resource::streamhost (
  Enum['present', 'absent'] $ensure             = 'present',
  Variant[Array, String] $listen_ip             = '*',
  Integer $listen_port                          = 80,
  Optional[String] $listen_options              = undef,
  Boolean $ipv6_enable                          = false,
  Variant[Array, String] $ipv6_listen_ip        = '::',
  Integer $ipv6_listen_port                     = 80,
  String $ipv6_listen_options                   = 'default ipv6only=on',
  Optional[String] $proxy                       = undef,
  String $proxy_read_timeout                    = $::nginx::config::proxy_read_timeout,
  $proxy_connect_timeout                        = $::nginx::config::proxy_connect_timeout,
  Array $resolver                               = [],
  Array $server_name                            = [$name],
  Optional[Variant[Array, String]] $raw_prepend = undef,
  Optional[Variant[Array, String]] $raw_append  = undef,
  String $owner                                 = $::nginx::config::global_owner,
  String $group                                 = $::nginx::config::global_group,
  String $mode                                  = $::nginx::config::global_mode,
) {

    if $mode !~ /^\d{4}$/ {
    fail("${mode} is not valid. It should be 4 digits (0644 by default).")
  }

  # Variables
  $streamhost_dir = "${::nginx::config::conf_dir}/streams-available"
  $streamhost_enable_dir = "${::nginx::config::conf_dir}/streams-enabled"
  $streamhost_symlink_ensure = $ensure ? {
    'absent' => absent,
    default  => 'link',
  }

  $name_sanitized = regsubst($name, ' ', '_', 'G')
  $config_file = "${streamhost_dir}/${name_sanitized}.conf"

  File {
    ensure => $ensure ? {
      'absent' => absent,
      default  => 'file',
    },
    notify => Class['nginx::service'],
    owner  => $owner,
    group  => $group,
    mode   => $mode,
  }

  # Add IPv6 Logic Check - Nginx service will not start if ipv6 is enabled
  # and support does not exist for it in the kernel.
  if ($ipv6_enable == true) and (!$facts['networking']['ip6']) {
    warning('nginx: IPv6 support is not enabled or configured properly')
  }

  concat { $config_file:
    owner  => $owner,
    group  => $group,
    mode   => $mode,
    notify => Class['nginx::service'],
  }

  concat::fragment { "${name_sanitized}-header":
    target  => $config_file,
    content => template('nginx/streamhost/streamhost.erb'),
    order   => '001',
  }

  file{ "${name_sanitized}.conf symlink":
    ensure  => $streamhost_symlink_ensure,
    path    => "${streamhost_enable_dir}/${name_sanitized}.conf",
    target  => $config_file,
    require => Concat[$config_file],
    notify  => Class['nginx::service'],
  }

}
