<?php

// Database

$databases = array (
  'default' =>
  array (
    'default' =>
    array (
      'database' => 'drupal',
      'username' => 'drupal',
      'password' => 'password',
      'host'     => 'localhost',
      'port'     => '',
      'driver'   => 'mysql',
      'prefix'   => '',
    ),
  ),
);

// Memcache
$conf['cache_backends'][] = 'sites/all/modules/contrib/memcache/memcache.inc';
$conf['cache_class_cache_form'] = 'DrupalDatabaseCache';
$conf['cache_default_class'] = 'MemCacheDrupal';
$conf['memcache_key_prefix'] = 'wk';
// Use memcache as the system lock to avoid deadlock (which occur easily with semaphore in database)
$conf['lock_inc'] = 'sites/all/modules/contrib/memcache/memcache-lock.inc';

// Varnish reverse proxy on 127.0.01
$conf['reverse_proxy'] = TRUE;
$conf['reverse_proxy_addresses'] = array('127.0.0.1');
$conf['varnish_version'] = "4";
$conf['varnish_control_key'] = 'secret-key-here';
$conf['varnish_control_terminal'] = '127.0.0.1:6082';

// Environment indicator
$conf['simple_environment_indicator'] = '#88b700 Local';
