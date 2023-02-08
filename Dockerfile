FROM docker.elastic.co/logstash/logstash:7.17.8

# Following installs allow disabling SSL verification
RUN logstash-plugin uninstall logstash-input-elasticsearch
RUN logstash-plugin uninstall logstash-output-elasticsearch
RUN logstash-plugin install logstash-input-elasticsearch
RUN logstash-plugin install logstash-output-elasticsearch
