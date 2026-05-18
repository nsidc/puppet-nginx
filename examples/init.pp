# The notify before should always come BEFORE all resources
# managed by the nginx class
# and the notify last should always come AFTER all resources
# managed by the nginx class.
node default {
  notify { 'before': }
  notify { 'last': }

  class { 'nginx': }

  Notify['before'] -> Class['nginx'] -> Notify['last']
}
