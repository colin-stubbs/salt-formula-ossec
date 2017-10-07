{% from "ossec/map.jinja" import ossec_map with context %}

include:
  - ossec

ossec-server-packages:
  pkg.installed:
    - pkgs:
      - ossec-hids-server
      - ossec-hids

ssl-key:
  cmd.run:
    - name: openssl genrsa -out {{ ossec_map.userdir }}/etc/sslmanager.key 2048
    - unless: stat {{ ossec_map.userdir }}/etc/sslmanager.key
    - require:
      - pkg: ossec-server-packages

ssl-cert:
  cmd.run:
    - name: openssl req -subj 
            '/CN={{ grains['id'] }}/C={{ salt['pillar.get']('openssl:countrynamedefault', 'US') -}}
            /ST={{ salt['pillar.get']('openssl:stateorprovincenamedefault', 'AK') -}}
            /O={{ salt['pillar.get']('openssl:orgnamedefault', 'Example Org') }}'
            -new -x509 -key {{ ossec_map.userdir }}/etc/sslmanager.key 
            -out {{ ossec_map.userdir }}/etc/sslmanager.cert 
            -days 730
    - unless: stat {{ ossec_map.userdir }}/etc/sslmanager.cert 
    - onlyif: stat {{ ossec_map.userdir }}/etc/sslmanager.key
    - require:
      - cmd: ssl-key

ossec-local_rules:
  file.managed:
    - name: /var/ossec/rules/local_rules.xml
    - source: salt://ossec/files/local_rules.xml
    - template: jinja
    - user: root
    - group: root
    - mode: 0644

ossec-service:
  service.running:
    - name: ossec-hids
    - enable: True
    - require:
      - cmd: ssl-cert
      - file: ossec-local_rules
    - watch:
      - pkg: ossec-server-packages
      - cmd: ssl-cert
      - file: ossec-local_rules

{# Since OSSEC does not recommend keeping authd running my workaround so far is to run a cron job
   to shut it off after a period of time. I need to figure out a better way of doing this in the 
   future as this may require more than one highstate to add keys for a client and it is cheesy #}

cron-kill-ossec-authd:
  cron.present:
    - name: 'pkill ossec-authd >/dev/null 2>&1'
    - user: root
    - minute: '*/5'
