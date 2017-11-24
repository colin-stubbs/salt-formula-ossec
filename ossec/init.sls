{% from "ossec/map.jinja" import ossec_map with context %}

{% if ossec_map.manage_repo == True %}
ossec-repo-gpg-key-art:
  file.managed:
    - name: /etc/pki/rpm-gpg/RPM-GPG-KEY.art.txt
    - source: https://www.atomicorp.com/RPM-GPG-KEY.art.txt
    - user: root
    - group: root
    - mode: 0644
    - source_hash: aa3e90664cdc10525e49df92b5dc10b575f9dae8ce5c551ef44800db613b936a

ossec-repo-gpg-key-atomicorp:
  file.managed:
    - name: /etc/pki/rpm-gpg/RPM-GPG-KEY.atomicorp.txt
    - source: https://www.atomicorp.com/RPM-GPG-KEY.atomicorp.txt
    - user: root
    - group: root
    - mode: 0644
    - source_hash: dddb2820b3a18101ec74c0f11ca21ce0726c5382dcbdf583160df41796e52488

ossec-repo:
  pkgrepo.managed:
    - humanname: ossec
{% if salt['grains.get']('os', 'UNKNOWN') == 'Fedora' %}
    - mirrorlist: 'http://updates.atomicorp.com/channels/mirrorlist/atomic/fedora-$releasever-$basearch'
{% else %}
    - mirrorlist: 'http://updates.atomicorp.com/channels/mirrorlist/atomic/centos-$releasever-$basearch'
{% endif %}
    - enabled: 1
    - protect: 0
    - gpgkey: 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY.art.txt file:///etc/pki/rpm-gpg/RPM-GPG-KEY.atomicorp.txt'
    - gpgcheck: 1
    - includepkgs: ossec*
    - require:
      - file: ossec-repo-gpg-key-art
      - file: ossec-repo-gpg-key-atomicorp
{% endif %}

include:
{% if ossec_map.role == 'server' %}
  - ossec.server
{% else %}
  - ossec.agent
{% endif %}
