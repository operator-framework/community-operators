FROM quay.io/operator-framework/ansible-operator:v0.17.0

USER 0

RUN pip3 install kafka-python==1.4.4 kazoo==2.6.1 pure-sasl==0.5.1

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY watches.yaml ${HOME}/watches.yaml

COPY roles/ ${HOME}/roles/
