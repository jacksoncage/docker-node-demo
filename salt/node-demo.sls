{% set name           = 'node-demo'   %}
{% set registryname   = 'jacksoncage' %}
{% set tag            = salt['pillar.get']('imagetag', "latest") %}
{% set containerid    = salt['grains.get']('id') %}
{% set hostport       = '808' %}
{% set hostip         = grains['ip_interfaces']['eth0'][0] %}
{% set noofcontainers = range(0,5) %}

{{ name }}-image:
  docker.pulled:
    - name: {{ registryname }}/{{ name }}
    - tag: {{ tag }}
    - force: True

{% for no in noofcontainers %}
{{ name }}-stop-if-old-{{ no }}:
  cmd.run:
    - name: docker stop {{ containerid }}-{{ name }}-{{ no }}
    - unless: docker inspect --format '{% raw %}{{ .Image }}{% endraw %}' {{ containerid }}-{{ name }}-{{ no }} | grep $(docker images --no-trunc | grep "{{ registryname }}/{{ name }}" | awk '{ print $3 }')
    - require:
      - docker: {{ name }}-image

{{ name }}-remove-if-old-{{ no }}:
  cmd.run:
    - name: docker rm {{ containerid }}-{{ name }}-{{ no }}
    - unless: docker inspect --format '{% raw %}{{ .Image }}{% endraw %}' {{ containerid }}-{{ name }}-{{ no }} | grep $(docker images --no-trunc | grep "{{ registryname }}/{{ name }}" | awk '{ print $3 }')
    - require:
      - cmd: {{ name }}-stop-if-old-{{ no }}

{{ name }}-container-{{ no }}:
  docker.installed:
    - name: {{ containerid }}-{{ name }}-{{ no }}
    - hostname: {{ containerid }}-{{ name }}-{{ no }}
    - image: {{ registryname }}/{{ name }}:{{ tag }}
    - ports:
        - "8080/tcp"
    - environment:
        - EXECUTER: "node"
        - APP: "index.js"
    - require_in: {{ name }}-{{ no }}
    - require:
      - docker: {{ name }}-image

{{ name }}-{{ no }}:
  docker.running:
    - container: {{ containerid }}-{{ name }}-{{ no }}
    - port_bindings:
        "8080/tcp":
            HostIp: "{{ hostip }}"
            HostPort: "{{ hostport }}{{ no }}"
{%- endfor %}
