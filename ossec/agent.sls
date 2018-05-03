{% from "ossec/map.jinja" import ossec_map with context %}

{% if 'role' in ossec_map and ossec_map.role == 'agent' %}
ossec_packages:
  pkg.installed:
    - pkgs: {{ ossec_map.lookup.packages.agent }}

{# Use events/reactor system to start up the ossec-authd process on the OSSEC master #}
server-auth:
  cmd.run:
    - name: salt-call event.fire_master 'ossec-auth-start' 'ossec'
    - unless: stat {{ ossec_map.lookup.locations.client_keys }}
    - require:
      - pkg: ossec_packages

{# OSSEC authd agent connects to master and registers its key #}
agent-auth:
  cmd.wait:
    - name: sleep 1 && {{ ossec_map.lookup.locations.base_dir }}/bin/agent-auth -m {{ ossec_map.server_ip }} -p {{ ossec_map.server_port }}
    - unless: stat {{ ossec_map.lookup.locations.client_keys }}
    - watch:
      - cmd: server-auth

{# We are done creating our key so lets shut down the ossec-auth process on the master using reactor #}
server-auth-shutdown:
  cmd.wait:
    - name: salt-call event.fire_master 'ossec-auth-stop' 'ossec'
    - watch:
      - cmd: agent-auth

{{ ossec_map.lookup.locations.agent_config }}:
  file.managed:
{% if ossec_map.config.ossec_agent_conf.source|default('pillar') == 'pillar' %}
    - source: salt://ossec/files/ossec-agent.conf.jinja
    - template: jinja
{% elif 'source_file' in ossec_map.config.ossec_agent_conf %}
    - source: {{ ossec_map.config.ossec_agent_conf.source_file }}
{% endif %}
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: ossec_packages

{# Start the OSSEC services on the agent #}
ossec-service:
  service.running:
    - name: {{ ossec_map.lookup.service_name }}
    - enable: True
    - sig: ossec-syscheckd
    - watch:
      - pkg: ossec_packages
      - file: {{ ossec_map.lookup.locations.agent_config }}
    - require:
      - pkg: ossec_packages
      - file: {{ ossec_map.lookup.locations.agent_config }}
      - cmd: agent-auth
{% endif %}

{# EOF #}
