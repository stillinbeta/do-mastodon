/etc/nginx/conf.d/mastodon.conf:
  file.managed:
    - source: salt://nginx.conf.jinja
    - template: jinja
    - context:
        domain:  "{{ salt['pillar.get']('mastodon:config:domain') }}"
