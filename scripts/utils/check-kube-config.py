import yaml
import re
from sys import exit
from lib import pick
from os import path, environ, system, WEXITSTATUS
from pathlib import Path


class bcolors:
    OK = "\033[0;32m"
    WARN = "\033[0;33m"
    ERR = "\033[0;31m"
    NC = "\033[0m"


class messages:
    CONFIG = 'Find kube config \t [ %s %s %s ]'
    CLUSTER = 'Find kube cluster \t [ %s %s %s ]'
    CONTEXT = 'Find kube context \t [%s %s %s ]'
    MASTER = 'Try kube master \t [ %s %s %s ]'


def get_kube_config(config_path):

    if path.isfile(config_path):
        with open(config_path, 'r') as stream:
            try:
                kube_config = yaml.safe_load(stream)
                print((messages.CONFIG % (bcolors.OK, config_path, bcolors.NC)).expandtabs(49))
                return kube_config
            except yaml.YAMLError as exc:
                print(exc)
                raise Exception('Failed to parse YAML')
    print((messages.CONFIG % (bcolors.WARN, 'Not found', bcolors.NC)).expandtabs(49))


def parse_current_context(kube_config):
    current_context = kube_config.get('current-context')
    contexts = kube_config.get('contexts')
    options = []
    selected = 0
    cluster = ''

    for i in range(len(contexts)):
        context = contexts[i]
        options.append(context.get('name'))
        if context.get('name') == current_context:
            selected = i
            cluster = context.get('context').get('cluster')

    if len(contexts) > 1:
        title = 'Please choose your context for testing: '

        option, index = pick(options, title, indicator='=>', default_index=selected)
        current_context = option

        for i in range(len(contexts)):
            context = contexts[i]
            if context.get('name') == current_context:
                cluster = context.get('context').get('cluster')

    if cluster == '':
        print((messages.CLUSTER % (bcolors.ERR, 'Not found', bcolors.NC)).expandtabs(49))
        raise Exception('Not found')

    if current_context:
        print((messages.CONTEXT % (bcolors.OK, current_context, bcolors.NC)).expandtabs(49))
        return current_context, cluster

    print((messages.CONTEXT % (bcolors.WARN, 'Not found', bcolors.NC)).expandtabs(49))
    raise Exception('Not found')


def write_context_to_config_file(config_path, kube_context, kube_config):
    if kube_context != kube_config.get('current-context'):
        f = open(config_path, "w+")
        kube_config['current-context'] = kube_context
        f.write(yaml.safe_dump(kube_config))
        f.close()


def check_availability_of_cluster(cluster_name, config):
    clusters = config.get('clusters')
    server = ''

    for i in range(len(clusters)):
        cluster = clusters[i]
        if cluster.get('name') == cluster_name:
            server = cluster.get('cluster').get('server')
            server = re.split('^.+://', server)[1]
            server = server.split(':')
    print((messages.MASTER % (bcolors.WARN, '%s:%s' % (server[0], server[1]), bcolors.NC)).expandtabs(49))

    command = 'nc -zvw3 -G 3 %s %s 2> /dev/null' % (server[0], server[1])
    exit_code = system(command)
    if exit_code > 0:
        print((messages.MASTER % (bcolors.ERR, 'Not responding on %s:%s' % (server[0], server[1]), bcolors.NC)).expandtabs(49))
        raise Exception('Not found')


def main():
    try:
        env_kube_config = environ.get('KUBECONFIG', '')
        config_path = env_kube_config if env_kube_config != '' else path.join(Path.home(), '.kube/config')
        kube_config = get_kube_config(config_path)
        kube_context, cluster_name = parse_current_context(kube_config)
        check_availability_of_cluster(cluster_name, kube_config)
        write_context_to_config_file(config_path, kube_context, kube_config)
    except Exception as e:
        system('make kind.start')
        exit(0)


if __name__ == "__main__":
    main()