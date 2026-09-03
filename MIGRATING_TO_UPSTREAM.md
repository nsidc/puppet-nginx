# Migrating to Upstream `voxpupuli/puppet-nginx`

This fork is outdated and we strongly encourage users to migrate to the upstream
[voxpupuli/puppet-nginx](https://github.com/voxpupuli/puppet-nginx).

The main differences between this fork and upstream are:

* `nginx::resource::vhost` resource is renamed to `nginx::resource::server`
* `format_log` is not set to `combined` by default
* `proxy_connect_timeout` is not set to the default value of '90'.
* The `cors` boolean option on `nginx::resource::vhost` is not available on
  the upstream's `nginx::resource::server`.


## Step 1: update your `Puppetfile`

Update your project `Puppetfile` so that `puppet-nginx` no longer references
this fork. Instead of:

```
mod "nsidc/puppet-nginx",
    :git => 'https://github.com/nsidc/puppet-nginx',
    :ref => 'latest'
```

It should look like this:

```
mod 'puppet-nginx', '8.2.0'
```


## Step 2: update the `nginx::resource::vhost` resource

Rename `nginx::resource::vhost` to `nginx::resource::server`.

Add `format_log => 'combined'` if desired.

Add `proxy_connect_timeout => '90'` if desired.

E.g.,

```
nginx::resource::server { $machine_hostname:
  ensure                => present,
  format_log            => 'combined',
  server_name           => [$machine_hostname],
  listen_port           => 80,
  proxy                 => 'http://127.0.0.1:9292',
  proxy_connect_timeout => '90',
}
```

## Step 3: configure CORs

If you use `cors => true` to confgiure [Cross-Origin Resource Sharing
(CORS)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS)
[preflight](https://developer.mozilla.org/en-US/docs/Glossary/Preflight_request)
options, you will need to update your configuration to add the headers yourself.

Note that the fork's `cors => true` **ONLY** setup CORS headers for preflight
`OPTIONS` requests (see
<https://developer.mozilla.org/en-US/docs/Glossary/Preflight_request>).

To replicate `cors => true`, you will need to separate out the proxy
config into a `nginx::resource::location` resource and add some extra logic via
`raw_prepend` to setup the pre-flight options. It will look something like this:

```
nginx::resource::server { $machine_hostname:
  ensure               => present,
  use_default_location => false,
  format_log           => 'combined',
  server_name          => [$machine_hostname],
  listen_port          => 80,
}

nginx::resource::location { 'root':
  ensure                => present,
  location              => '/',
  server                => $machine_hostname,
  proxy                 => 'http://127.0.0.1:9292',
  proxy_read_timeout    => '180',
  proxy_connect_timeout => '90',
  raw_prepend           => [
      'if ($request_method = \'OPTIONS\') {',
      '  add_header Access-Control-Allow-Origin \'*\';',
      '  add_header Access-Control-Allow-Methods \'GET, POST, PUT, OPTIONS, DELETE\';',
      '  add_header Access-Control-Allow-Headers \'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type\';',
      '  add_header Content-Type \'text/plain charset=UTF-8\';',
      '  add_header Content-Length 0;',
      '  return 204;',
      '}',
  ],
}
```

> [!NOTE] 
> Be sure to add `use_default_location => false` to the
> `nginx::resource::server` block so that you can setup the root location in
> `nginx::resource::location`. If you don't do this, you will get errors from
> puppet about duplicate resource definitions.

The `cors => true` option was a convenience to quickly setup preflight CORS for
NSIDC applications, but users are encouraged to consider what is actually
necessary for their specific app. For example, if your application only defines
endpoints that support `GET` CORS requests (not e.g., `POST`), then consider
updating the `Access-Control-Allow-Methods` to only specify those CORS
operations your app is defined for (`GET`).

Note that you still may still need to add CORS header(s) for other operations
(e.g., `GET`).

For example, the `vadr` nginx configuration looks like this (note the
`add_header` directive in `nginx::resource::server`):

```
nginx::resource::server { $machine_hostname:
  ensure               => present,
  format_log           => 'combined',
  use_default_location => false,
  server_name          => [$machine_hostname],
  listen_port          => 80,
  add_header           => {
    'Access-Control-Allow-Origin'  => '*',
    'Access-Control-Allow-Methods' => 'OPTIONS,HEAD,GET,PUT,POST,DELETE',
    'Access-Control-Allow-Headers' => 'Origin, X-Requested-With, Content-Type, Accept, Range'
  },
}

nginx::resource::location { 'root':
  ensure                => present,
  location              => '/',
  server                => $machine_hostname,
  proxy                 => 'http://127.0.0.1:9292',
  proxy_read_timeout    => '180',
  proxy_connect_timeout => '90',
  raw_prepend           => [
      'if ($request_method = \'OPTIONS\') {',
      '  add_header \'Access-Control-Allow-Origin\' \'*\';',
      '  add_header \'Access-Control-Allow-Methods\' \'GET, POST, PUT, OPTIONS, DELETE\';',
      '  add_header \'Access-Control-Allow-Headers\' \'DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type\';',
      '  add_header \'Content-Type\' \'text/plain charset=UTF-8\';',
      '  add_header \'Content-Length\' 0;',
      '  return 204;',
      '}',
  ],
}
```

## Step 4: ??

At this time, there is no step 4 - try creating a new VM and confirm the server
works as expected! If you find any differences that are not documented here,
please consider updating this document to help out others that might run into
the same issue.
