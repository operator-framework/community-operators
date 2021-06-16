from datetime import datetime
import pprint
from graphql_handler import get_pr_data


# list of 
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


def main():
    pr_data = get_pr_data(rate_limit=True)
    processed_pr_data = process_pr_data(pr_data)

    pp = pprint.PrettyPrinter()
    pp.pprint(processed_pr_data)
    print(f'{len(pr_data)} PRs queried')


if __name__ == '__main__':
    main()
