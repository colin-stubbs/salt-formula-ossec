{# ossec.server #}

{% from "ossec/map.jinja" import ossec_map with context %}

include:
  - ossec

{% if 'role' in ossec_map and ossec_map.role == 'server' %}
ossec-server-packages:
  pkg.installed:
    - pkgs: {{ ossec_map.lookup.server.pkgs }}

{% if ossec_map.manage_internal_options == True %}
{{ ossec_map.lookup.locations.base_dir }}/etc/internal_options.conf:
  file.managed:
    - source: {{ ossec_map.config.internal_options.source_file }}
    - user: root
    - group: root
    - mode: 0644
{% endif %}

{% if ossec_map.config.ossec_server_conf.source|default('pillar') == 'pillar' %}
{{ ossec_map.lookup.locations.base_dir }}/etc/ossec-server.conf:
  file.managed:
    - source: salt://ossec/files/ossec-server.conf.jinja
    - template: jinja
    - context:
      ossec_map: {{ ossec_map }}
    - user: root
    - group: root
    - mode: 0644
{% elif 'source_file' in ossec_map.config.ossec_server_conf %}
{{ ossec_map.lookup.locations.base_dir }}/etc/ossec-server.conf:
  file.managed:
    - source: {{ ossec_map.config.ossec_server_conf.source_file }}
    - user: root
    - group: root
    - mode: 0644
{% endif %}

{% if 'templates' in ossec_map.config and 'source_dir' in ossec_map.config.templates %}
{{ ossec_map.lookup.locations.base_dir }}/etc/templates:
  file.directory:
    - source: {{ ossec_map.config.templates.source_dir }}
    - user: root
    - group: root
    - mode: 0755
{% endif %}

{% if 'shared' in ossec_map.config and 'source_dir' in ossec_map.config.shared %}
{{ ossec_map.lookup.locations.base_dir }}/etc/shared:
  file.directory:
    - source: {{ ossec_map.config.shared.source_dir }}
    - user: root
    - group: root
    - mode: 0755
{% endif %}

{% if 'decoders_d' in ossec_map.config and 'source_dir' in ossec_map.config.decoders_d %}
{{ ossec_map.lookup.locations.base_dir }}/etc/decoders.d:
  file.directory:
    - source: {{ ossec_map.config.decoders_d.source_dir }}
    - user: root
    - group: root
    - mode: 0755
{% endif %}

{% if 'rules_d' in ossec_map.config and 'source_dir' in ossec_map.config.rules_d %}
{{ ossec_map.lookup.locations.base_dir }}/etc/rules.d:
  file.directory:
    - source: {{ ossec_map.config.rules_d.source_dir }}
    - user: root
    - group: root
    - mode: 0755
{% endif %}

ossec-service:
  service.running:
    - name: {{ ossec_map.lookup.service_name }}
    - enable: True
    - require:
      - pkg: ossec-server-packages
      {% if ossec_map.manage_internal_options == True %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/internal_options.conf:
      {% endif %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/ossec-server.conf
      {% if 'templates' in ossec_map.config and 'source_dir' in ossec_map.config.templates %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/templates
      {% endif %}
      {% if 'shared' in ossec_map.config and 'source_dir' in ossec_map.config.shared %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/shared
      {% endif %}
      {% if 'decoders_d' in ossec_map.config and 'source_dir' in ossec_map.config.decoders_d %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/decoders.d
      {% endif %}
      {% if 'rules_d' in ossec_map.config and 'source_dir' in ossec_map.config.rules_d %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/rules.d
      {% endif %}
    - watch:
      - pkg: ossec-server-packages
      {% if ossec_map.manage_internal_options == True %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/internal_options.conf:
      {% endif %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/ossec-server.conf
      {% if 'templates' in ossec_map.config and 'source_dir' in ossec_map.config.templates %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/templates
      {% endif %}
      {% if 'shared' in ossec_map.config and 'source_dir' in ossec_map.config.shared %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/shared
      {% endif %}
      {% if 'decoders_d' in ossec_map.config and 'source_dir' in ossec_map.config.decoders_d %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/decoders.d
      {% endif %}
      {% if 'rules_d' in ossec_map.config and 'source_dir' in ossec_map.config.rules_d %}
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/rules.d
      {% endif %}

{# Since OSSEC does not recommend keeping authd running my workaround so far is to run a cron job
   to shut it off after a period of time. I need to figure out a better way of doing this in the
   future as this may require more than one highstate to add keys for a client and it is cheesy #}

cron-kill-ossec-authd:
  cron.present:
    - name: 'pkill ossec-authd >/dev/null 2>&1'
    - user: root
    - minute: '*/5'
{% endif %}

{# EOF #}
