docker:
  pkg.installed:
    - pkgs:
        - docker.io
        - python-docker
    - order: 1

internal_network:
  docker_network.present:
    - internal: True

external_network:
  docker_network.present: []

mount_volume:
  mount.mounted:
    - name: '/mnt/do_volume'
    - device: '/dev/disk/by-id/scsi-0DO_Volume_sdb'
    - fstype: 'ext4'
    - mkmnt: true

postgres_dir:
  file.directory:
    - name: /mnt/do_volume/postgres
    - require:
        - mount_volume

mastodon_postgres:
  docker_container.running:
    - restart_policy: 'always'
    - image: "{{ salt['pillar.get']('mastodon:docker:images:postgres') }}"
    - require:
      - postgres_dir
    - network_mode: 'internal_network'
    - restart_policy: always
    - environment:
        POSTGRES_PASSWORD: "{{ salt['pillar.get']('mastodon:postgres:password') }}"
        PGDATA: "/var/lib/postgres/data/pgdata"
    - binds:
        - '/mnt/sdb/postgres:/var/lib/postgres/data'

mastodon_redis:
  docker_container.running:
    - restart_policy: 'always'
    - image: "{{ salt['pillar.get']('mastodon:docker:images:redis') }}"
    # - require:
    #     - redis
    - network_mode: 'internal_network'
    - restart_policy: always

mastodon_assets_dir:
  file.directory:
    - name: /mnt/sdb/mastodon/assets
    - makedirs: true
    - require:
      - mount_volume

mastodon_system_dir:
  file.directory:
    - name: /mnt/sdb/mastodon/system
    - makedirs: true
    - require:
      - mount_volume

web:
  docker_container.running:
    - restart_policy: 'always'
    - require:
        - mastodon_postgres
        - mastodon_redis
        - mastodon_assets_dir
        - mastodon_system_dir
    - image: "{{ salt['pillar.get']('mastodon:docker:images:mastodon') }}"
    - environment: {{ salt['pillar.get']('mastodon:docker:environment') }}
    - command: bash -c "rm -f /mastodon/tmp/pids/server.pid; bundle exec rails s -p 3000 -b '0.0.0.0'"
    - binds:
        - '/mnt/sdb/mastodon/system:/mastodon/public/system'
        - '/mnt/sdb/mastodon/assets:/mastodon/public/assets'
    - network_mode: 'internal_network'
    - links:
        - redis:mastodon_redis
        - postgres:mastodon_postgres

streaming:
  docker_container.running:
    - restart_policy: 'always'
    - require:
        - mastodon_postgres
        - mastodon_redis
    - image: "{{ salt['pillar.get']('mastodon:docker:images:mastodon') }}"
    - environment: {{ salt['pillar.get']('mastodon:docker:environment') }}
    - command: "yarn start"
    - network_mode: 'internal_network'
    - links:
        - redis:mastodon_redis
        - postgres:mastodon_postgres

sidekiq:
  docker_container.running:
    - restart_policy: 'always'
    - require:
        - mastodon_postgres
        - mastodon_redis
        - mastodon_system_dir
    - image: "{{ salt['pillar.get']('mastodon:docker:images:mastodon') }}"
    - environment: {{ salt['pillar.get']('mastodon:docker:environment') }}
    - command: "bundle exec sidekiq -q default -q push -q mailers -q pull"
    - binds:
        - '/mnt/sdb/mastodon/system:/mastodon/public/system'
    - network_mode: 'internal_network'
    - links:
        - redis:mastodon_redis
        - postgres:mastodon_postgres

mastodon_nginx:
  docker_image.present:
  - base: "stillinbeta/docker-nginx-certbot:latest"
  - sls: nginx_certbot
  - tag: latest

nginx:
  docker_container.running:
    - restart_policy: 'always'
    - watch:
        - mastodon_nginx
    - require:
        - streaming
        - web
        - internal_network
        - external_network
    - image: "mastodon_nginx:latest"
    - command:
        - "/bin/bash"
        - "/scripts/entrypoint.sh"
    - network_mode: 'internal_network'
    - publish:
        - 0.0.0.0:80:80
        - 0.0.0.0:443:443
    - networks:
        - internal_network
        - external_network
    - environment:
        CERTBOT_EMAIL: "{{ salt['pillar.get']('mastodon:config:email') }}"
    - links:
        - web:web
        - streaming:streaming
