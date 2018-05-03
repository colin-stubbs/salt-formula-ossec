{% from "ossec/map.jinja" import ossec_map with context %}

include:
{% if ossec_map.role == 'server' %}
  - ossec.server
{% else %}
  - ossec.agent
{% endif %}
