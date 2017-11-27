{% from "ossec/map.jinja" import ossec_map with context %}

include:
  - ossec

{% if 'role' in ossec_map and ossec_map.role == 'agent' %}
ossec-agent-packages:
  pkg.installed:
    - pkgs: {{ ossec_map.lookup.agent.pkgs }}

{# Use events/reactor system to start up the ossec-authd process on the OSSEC master #}
server-auth:
  cmd.run:
    - name: salt-call event.fire_master 'ossec-auth-start' 'ossec'
    - unless: stat {{ ossec_map.lookup.locations.base_dir }}/etc/client.keys
    - require:
      - pkg: ossec-agent-packages

{# OSSEC authd agent connects to master and registers its key #}
agent-auth:
  cmd.wait:
    - name: sleep 1 && {{ ossec_map.lookup.locations.base_dir }}/bin/agent-auth -m {{ ossec_map.server_ip }} -p {{ ossec_map.server_port }}
    - unless: stat {{ ossec_map.lookup.locations.base_dir }}/etc/client.keys
    - watch:
      - cmd: server-auth

{# We are done creating our key so lets shut down the ossec-auth process on the master using reactor #}
server-auth-shutdown:
  cmd.wait:
    - name: salt-call event.fire_master 'ossec-auth-stop' 'ossec'
    - watch:
      - cmd: agent-auth

{{ ossec_map.lookup.locations.base_dir }}/etc/ossec-agent.conf:
  file.managed:
{% if ossec_map.config.ossec_agent_conf.source|default('pillar') == 'pillar' %}
    - source: salt://ossec/files/ossec-agent.conf.jinja
    - template: jinja
    - context:
      ossec_map: {{ ossec_map }}
{% elif 'source_file' in ossec_map.config.ossec_agent_conf %}
    - source: {{ ossec_map.config.ossec_agent_conf.source_file }}
{% endif %}
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: ossec-agent-packages

{# Start the OSSEC services on the agent #}
ossec-service:
  service.running:
    - name: {{ ossec_map.lookup.service_name }}
    - enable: True
    - sig: ossec-syscheckd
    - watch:
      - pkg: ossec-agent-packages
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/ossec-agent.conf
    - require:
      - pkg: ossec-agent-packages
      - file: {{ ossec_map.lookup.locations.base_dir }}/etc/ossec-agent.conf
      - cmd: agent-auth
{% endif %}
