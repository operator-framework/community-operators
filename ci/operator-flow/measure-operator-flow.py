#!/usr/bin/env python

import sys
import getopt
from datetime import datetime
import pprint

from requests.api import options
from graphql_handler import get_pr_data


# list of repo maintainers
maintainers = set([
    'maintainer'
    'J0zi',
    'mvalarh',
])


def compute_duration(created_at, merged_at):
    """Compute duration that a merged PR was open (in seconds)"""
    format_str = r"%Y-%m-%dT%H:%M:%SZ"
    date_created = datetime.strptime(created_at, format_str)
    date_merged = datetime.strptime(merged_at, format_str)
    time_diff = (date_merged - date_created).total_seconds()
    return int(time_diff)


def process_pr_data(pr_data):
    processed_pr_data = []

    for number, pr in pr_data.items():
        time_to_merge = compute_duration(pr['created_at'], pr['merged_at'])

        if pr['labeler'] in maintainers:
            authorizer = 'maintainer'
        else:
            authorizer = 'bot'

        if maintainers & pr['commentors']:
            interaction = 'comment by maintainer'
        elif authorizer == 'maintainer':
            interaction = 'maintainer set `authorized-changes`'
        else:
            interaction = 'none'

        processed_pr_data.append({
            'number': number,
            'date created': pr['created_at'],
            'time to merge': time_to_merge,
            'authorizer': authorizer,
            'interaction': interaction
        })
    
    return processed_pr_data


def parse_args(argv):
    # output when script is run with [-h, --help] option
    help_str = ('usage: python3 measure-operator-flow.py [options]\n'
    '\n'
    'measure pull request performance on '
    'https://github.com/operator-framework/community-operators\n'
    '\n'
    'you will require a GitHub API token set to the environment variable '
    'GH_TOKEN\n'
    '\n'
    '''options:
    [-l, --last] <n>       requests only last n pull requests
    [-p, --page-size] <k>  requests k pull requests per GraphQL page
    [-c, pr-cursor] <c>    startCursor for GraphQL page
    --show-pr-cursor       log startCursor of each GraphQL page requested
    --show-rate-limit      log rate limit data during each page request
    ''')

    options = 'hl:p:c:r'
    long_options = [
        'help',
        'last=',
        'page-size=',
        'pr-cursor=',
        'show-pr-cursor',
        'show-rate-limit'
    ]
    args = {}

    try:
        arg_opts, opts = getopt.getopt(argv, options, long_options)

        for arg, opt in arg_opts:
            if arg in ('-h', '--help'):
                print(help_str)
                return
            
            elif arg in ('-l', '--last'):
                args['last'] = int(opt)

            elif arg in ('-p', '--page-size'):
                args['page_size'] = int(opt)

            elif arg in ('-c', '--pr-cursor'):
                args['pr_cursor'] = opt

            elif arg == '--show-pr-cursor':
                args['show_pr_cursor'] = True

            elif arg == '--show-rate-limit':
                args['show_rate_limit'] = True

    except getopt.error as err:
        raise Exception(str(err) + '\n' + help_str)

    return args


def main(argv):
    args = parse_args(argv)
    if args is None:
        return
    
    last = args.get('last', None)
    page_size = args.get('page_size', 100)
    pr_cursor = args.get('pr_cursor', None)
    show_pr_cursor = args.get('show_pr_cursor', False)
    show_rate_limit = args.get('show_rate_limit', False)

    pr_data = get_pr_data(last, page_size, pr_cursor, show_pr_cursor,
                          show_rate_limit)
    processed_pr_data = process_pr_data(pr_data)

    pp = pprint.PrettyPrinter()
    pp.pprint(processed_pr_data)
    print(f'{len(pr_data)} PRs queried')


if __name__ == '__main__':
    main(sys.argv[1:])
