---
# these come from project.yml
project:
  name: <%= projectName %>
ansible:
  remote: <%= wunderMachina %>
  branch: <%= wunderMachina_branch %>
  revision:
buildsh:
  enabled: <%= buildSh_enabled %>
  branch: <%= buildSh_branch %>
  revision:
# these come from vagrant_local.yml
name : <%= projectName %>
hostname : <%= projectLocalURL%>
mem : 2000
cpus : 2
ip : <%= projectLocalIP %>
box : <%= projectLocalBox %>
# these come from variables.yml
# Databases
databases:
  drupal:
    user: drupal
    pass: password

drush: {
  version: "6.*",
}
drupal_files: drupal/files
# PHP
php_package: php56u

# Sections APC and suhosin are only for php53u
# OPCACHE is for php55u, PHP section is shared

php:
 - section: PHP
   options:
    - key: sendmail_path
      val: "/usr/sbin/ssmtp -t"
    - key: memory_limit
      val: 512M
    - key: realpath_cache_size
      val: 1M
    - key: realpath_cache_ttl
      val: 7200
    - key: max_execution_time
      val: 60
    - key: max_input_time
      val: 60
    - key: post_max_size
      val: 24M
    - key: upload_max_filesize
      val: 50M
    - key: max_file_uploads
      val: 20
    - key: allow_url_fopen
      val: On
    - key: display_errors
      val: Off
    - key: html_errors
      val: Off
    - key: display_errors
      val: On
    - key: html_errors
      val: On
 - section: DATE
   options:
    - key: date.timezone
      val: Europe/Helsinki
 - section: OPCACHE
   options:
    - key: opcache.memory
      val: 256
    - key: opcache.validate
      val: 1
    - key: opcache.revalidate_freq
      val: 0

# MariaDB
mysql_root_password: 1asirjg9834t35t
server_hostname: localhost
innodb_log_file_size: '128MB'
innodb_buffer_pool_size: '512MB'
wait_timeout: '3600'

# Varnish
varnish_port: '80'
varnish_memory: '512M'

varnish_backends:
  - name: web1
    host: localhost
    port: 8080
ssl_ip_fix: false

#Docs
docs:
  hostname : 'docs.<%= projectLocalURL%>'
  dir : '/vagrant/docs'

# Nginx
worker_processes: '1'
nginx_sites:
  - hostname: '<%= projectLocalURL%> *.<%= projectLocalURL%>'
    port: '8080 default_server'
    docroot: '/vagrant/drupal/current'
    accesslog: true
    accesslog_params: 'main buffer=32k'
    errorlog: true
    logprefix: '<%= projectLocalURL%>'
    ssl: false
    sslproxy: false
    ssl_certificate: default.crt
    ssl_certificate_key: default.key
    include_drupal: true
    cdn: false
    nocdnhostname: 'www.wunder.io'
    redirect: false
    redirecthost: 'https://www.wunder.io'
  - hostname: "{{ docs.hostname }}"
    port: '8080'
    docroot: "{{ docs.dir }}"
    accesslog: true
    accesslog_params: 'main buffer=32k'
    errorlog: true
    logprefix: "{{ docs.hostname }}"
    ssl: false
    sslproxy: false
    ssl_certificate: default.crt
    ssl_certificate_key: default.key
    include_drupal: false
    include_wiki: true
    cdn: false
    nocdnhostname: 'www.wunder.io'
    redirect: false
    redirecthost: 'https://www.wunder.io'

solr_collection_name: 'ansibleref'