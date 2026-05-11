# Class: nginx::config
#
# This module manages NGINX bootstrap and configuration
#
# Parameters:
#
# There are no default parameters for this class.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# This class file is not called directly
class nginx::config(
  ### START Module/App Configuration ###
  $client_body_temp_path          = $::nginx::params::client_body_temp_path,
  Boolean $confd_purge                    = false,
  $conf_dir                       = $::nginx::params::conf_dir,
  $daemon_user                    = $::nginx::params::daemon_user,
  $global_owner                   = $::nginx::params::global_owner,
  $global_group                   = $::nginx::params::global_group,
  $global_mode                    = $::nginx::params::global_mode,
  $log_dir                        = $::nginx::params::log_dir,
  String $http_access_log                = $::nginx::params::http_access_log,
  String $nginx_error_log                = $::nginx::params::nginx_error_log,
  Enum['debug', 'info', 'notice', 'warn', 'error', 'crit', 'alert', 'emerg'] $nginx_error_log_severity       = 'error',
  $pid                            = $::nginx::params::pid,
  $proxy_temp_path                = $::nginx::params::proxy_temp_path,
  $root_group                     = $::nginx::params::root_group,
  $run_dir                        = $::nginx::params::run_dir,
  $sites_available_owner          = $::nginx::params::sites_available_owner,
  $sites_available_group          = $::nginx::params::sites_available_group,
  $sites_available_mode           = $::nginx::params::sites_available_mode,
  Boolean $super_user                     = $::nginx::params::super_user,
  $temp_dir                       = $::nginx::params::temp_dir,
  Boolean $vhost_purge                    = false,

  # Primary Templates
  $conf_template                  = 'nginx/conf.d/nginx.conf.erb',
  Optional[String] $proxy_conf_template            = undef,
  ### END Module/App Configuration ###

  ### START Nginx Configuration ###
  $accept_mutex                   = 'on',
  $accept_mutex_delay             = '500ms',
  $client_body_buffer_size        = '128k',
  String $client_max_body_size           = '10m',
  $events_use                     = false,
  String $fastcgi_cache_inactive         = '20m',
  Variant[Boolean, String] $fastcgi_cache_key              = false,
  String $fastcgi_cache_keys_zone        = 'd3:100m',
  $fastcgi_cache_levels           = '1',
  String $fastcgi_cache_max_size         = '500m',
  Variant[Boolean, String] $fastcgi_cache_path             = false,
  Variant[Boolean, String] $fastcgi_cache_use_stale        = false,
  $gzip                           = 'on',
  $gzip_buffers                   = undef,
  $gzip_comp_level                = 1,
  $gzip_disable                   = 'msie6',
  $gzip_min_length                = 20,
  $gzip_http_version              = 1.1,
  $gzip_proxied                   = 'off',
  $gzip_types                     = undef,
  $gzip_vary                      = 'off',
  Variant[Boolean, Hash, Array] $http_cfg_append                = false,
  $http_tcp_nodelay               = 'on',
  $http_tcp_nopush                = 'off',
  $keepalive_timeout              = '65',
  $log_format                     = {},
  Boolean $mail                           = false,
  $stream                         = false,
  String $multi_accept                   = 'off',
  Variant[Integer, String] $names_hash_bucket_size         = '64',
  Variant[Integer, String] $names_hash_max_size            = '512',
  Variant[Boolean, Hash, Array] $nginx_cfg_prepend              = false,
  String $proxy_buffers                  = '32 4k',
  String $proxy_buffer_size              = '8k',
  String $proxy_cache_inactive           = '20m',
  String $proxy_cache_keys_zone          = 'd2:100m',
  String $proxy_cache_levels             = '1',
  String $proxy_cache_max_size           = '500m',
  Variant[Boolean, Hash, String] $proxy_cache_path               = false,
  Variant[Boolean, Enum['on', 'off']] $proxy_use_temp_path            = false,
  $proxy_connect_timeout          = '90',
  String $proxy_headers_hash_bucket_size = '64',
  Optional[String] $proxy_http_version             = undef,
  $proxy_read_timeout             = '90',
  $proxy_redirect                 = 'off',
  $proxy_send_timeout             = '90',
  Array $proxy_set_header               = [
    'Host $host',
    'X-Real-IP $remote_addr',
    'X-Forwarded-For $proxy_add_x_forwarded_for',
    'Proxy ""',
  ],
  Array $proxy_hide_header              = [],
  $sendfile                       = 'on',
  String $server_tokens                  = 'on',
  $spdy                           = 'off',
  $http2                          = 'off',
  $ssl_stapling                   = 'off',
  Variant[Integer, String] $types_hash_bucket_size         = '512',
  Variant[Integer, String] $types_hash_max_size            = '1024',
  Variant[Integer, String] $worker_connections             = '1024',
  Variant[Integer, String] $worker_processes               = '1',
  Variant[Integer, String] $worker_rlimit_nofile           = '1024',
  ### END Nginx Configuration ###
) inherits nginx::params {

  ### Validations ###
  if ($worker_processes != 'auto') and (!nginx::is_integer($worker_processes)) {
    fail('$worker_processes must be an integer or have value "auto".')
  }
  if (!nginx::is_integer($worker_connections)) {
    fail('$worker_connections must be an integer.')
  }
  if (!nginx::is_integer($worker_rlimit_nofile)) {
    fail('$worker_rlimit_nofile must be an integer.')
  }
  if (!$events_use =~ String) and ($events_use != false) {
    fail('$events_use must be a string or false.')
  }
  # validate_string($multi_accept)
  # validate_array($proxy_set_header)
  # validate_array($proxy_hide_header)
  # if ($proxy_http_version != undef) {
  #   validate_string($proxy_http_version)
  # }
  if ($proxy_conf_template != undef) {
    warning('The $proxy_conf_template parameter is deprecated and has no effect.')
  }
  # validate_bool($confd_purge)
  # # validate_bool($vhost_purge)
  # if ( $proxy_cache_path != false) {
  #   if ( $proxy_cache_path =~ String or $proxy_cache_path =~ Hash ) {}
  #   else {
  #     fail('proxy_cache_path must be a string or a hash')
  #   }
  # }
  if ($proxy_cache_path =~ Boolean and $proxy_cache_path == true) {
    fail('proxy_cache_path must be false or a string or a hash')
  }
  if $proxy_cache_levels !~ /^[12](:[12])*$/ {
    fail('Proxy Cache Levels has an invalid value')
  }
  # validate_string($proxy_cache_keys_zone)
  # validate_string($proxy_cache_max_size)
  # validate_string($proxy_cache_inactive)

  # if ($proxy_use_temp_path != false) {
  #       if $proxy_use_temp_path !~ /^(on|off)$/ {
  #         fail('Proxy Use Cache Levels should be false, or have the value "on" or "off"')
  #       }
  # }
  if ($proxy_use_temp_path =~ Boolean and $proxy_use_temp_path == true) {
    fail('Proxy Use Temp Path should be false, or have the value "on" or "off"')
  }

  # if ($fastcgi_cache_path != false) {
  #       validate_string($fastcgi_cache_path)
  # }
  if $fastcgi_cache_levels !~ /^[12](:[12])*$/ {
    fail('Proxy Cache Levels has an invalid value')
  }
  # validate_string($fastcgi_cache_keys_zone)
  # validate_string($fastcgi_cache_max_size)
  # validate_string($fastcgi_cache_inactive)
  # if ($fastcgi_cache_key != false) {
  #   validate_string($fastcgi_cache_key)
  # }
  # if ($fastcgi_cache_use_stale != false) {
  #   validate_string($fastcgi_cache_use_stale)
  # }

  # validate_bool($mail)
  # validate_string($server_tokens)
  # validate_string($client_max_body_size)
  if (!nginx::is_integer($names_hash_bucket_size)) {
    fail('$names_hash_bucket_size must be an integer.')
  }
  if (!nginx::is_integer($names_hash_max_size)) {
    fail('$names_hash_max_size must be an integer.')
  }
  # validate_string($proxy_buffers)
  # validate_string($proxy_buffer_size)
  # if ($http_cfg_append != false) {
  #   # if !(is_hash($http_cfg_append) or is_array($http_cfg_append)) {
  #   if !($http_cfg_append =~ Hash or $http_cfg_append =~ Array) {
  #     fail('$http_cfg_append must be either a hash or array')
  #   }
  # }
  if ($http_cfg_append =~ Boolean and $http_cfg_append == true) {
    fail('$http_cfg_append must either be false, or a hash or array')
  }

  # if ($nginx_cfg_prepend != false) {
  #   # if !(is_hash($nginx_cfg_prepend) or is_array($nginx_cfg_prepend)) {
  #   if !($nginx_cfg_prepend =~ Hash or $nginx_cfg_prepend =~ Array) {
  #     fail('$nginx_cfg_prepend must be either a hash or array')
  #   }
  # }
  if ($nginx_cfg_prepend =~ Boolean and $nginx_cfg_prepend == true) {
    fail('$nginx_cfg_prepend must either be false, or a hash or array')
  }

  # validate_string($nginx_error_log)
  # validate_re($nginx_error_log_severity,['debug','info','notice','warn','error','crit','alert','emerg'],
  #   '$nginx_error_log_severity must be debug, info, notice, warn, error, crit, alert or emerg')
  # if $nginx_error_log_severity !~ /^(debug|info|notice|warn|error|crit|alert|emerg)$/ {
  #   fail('$nginx_error_log_severity must be debug, info, notice, warn, error, crit, alert or emerg')
  # }
  # validate_string($http_access_log)
  # validate_string($proxy_headers_hash_bucket_size)
  # validate_bool($super_user)
  ### END VALIDATIONS ###


  ### CONFIGURATION ###
  File {
    owner => $global_owner,
    group => $global_group,
    mode  => $global_mode,
  }

  file { $conf_dir:
    ensure => directory,
  }

  file { "${conf_dir}/conf.stream.d":
    ensure => directory,
  }
  if $confd_purge == true {
    File["${conf_dir}/conf.stream.d"] {
      purge   => true,
      recurse => true,
    }
  }

  file { "${conf_dir}/conf.d":
    ensure => directory,
  }
  if $confd_purge == true {
    File["${conf_dir}/conf.d"] {
      purge   => true,
      recurse => true,
      notify  => Class['nginx::service'],
    }
  }

  file { "${conf_dir}/conf.mail.d":
    ensure => directory,
  }
  if $confd_purge == true {
    File["${conf_dir}/conf.mail.d"] {
      purge   => true,
      recurse => true,
    }
  }

  file { "${conf_dir}/conf.d/vhost_autogen.conf":
    ensure => absent,
  }

  file { "${conf_dir}/conf.mail.d/vhost_autogen.conf":
    ensure => absent,
  }

  file {$run_dir:
    ensure => directory,
  }

  file { $log_dir:
    ensure => directory,
  }

  file {$client_body_temp_path:
    ensure => directory,
    owner  => $daemon_user,
  }

  file {$proxy_temp_path:
    ensure => directory,
    owner  => $daemon_user,
  }

  file { "${conf_dir}/sites-available":
    ensure => directory,
    owner  => $sites_available_owner,
    group  => $sites_available_group,
    mode   => $sites_available_mode,
  }

  if $vhost_purge == true {
    File["${conf_dir}/sites-available"] {
      purge   => true,
      recurse => true,
    }
  }

  file { "${conf_dir}/sites-enabled":
    ensure => directory,
  }

  if $vhost_purge == true {
    File["${conf_dir}/sites-enabled"] {
      purge   => true,
      recurse => true,
    }
  }

  file { "${conf_dir}/sites-enabled/default":
    ensure => absent,
  }

  file { "${conf_dir}/nginx.conf":
    ensure  => file,
    content => template($conf_template),
  }

  file { "${conf_dir}/conf.d/proxy.conf":
    ensure => absent,
  }

  file { "${conf_dir}/conf.d/default.conf":
    ensure => absent,
  }

  file { "${conf_dir}/conf.d/example_ssl.conf":
    ensure => absent,
  }

  file { "${temp_dir}/nginx.d":
    ensure  => absent,
    purge   => true,
    recurse => true,
    force   => true,
  }

  file { "${temp_dir}/nginx.mail.d":
    ensure  => absent,
    purge   => true,
    recurse => true,
    force   => true,
  }
}
