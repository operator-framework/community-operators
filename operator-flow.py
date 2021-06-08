import requests
from datetime import datetime


def _get_pull_requests(owner, repo, page, per_page=100):
    url = f'https://api.github.com/repos/{owner}/{repo}/pulls'

    # only querying closed pull requests
    params = {'state': 'closed', 'per_page': per_page, 'page': page}
    headers = {
        'Accept': 'application/vnd.github.v3+json'
    }

    response = requests.request("GET", url, headers=headers, params=params)
    return response.json()


def get_pull_requests(owner='operator-framework', repo='community-operators',
                      lim=1):
    data = []
    page = 1

    while (batch := _get_pull_requests(owner, repo, page)) and page <= lim:
        for pr in batch:
            merged_at = pr['merged_at']

            if merged_at is not None:
                number = pr['number']

                format_str = r"%Y-%m-%dT%H:%M:%SZ"
                date_created = datetime.strptime(pr['created_at'], format_str)
                date_merged = datetime.strptime(merged_at, format_str)
                time_diff = (date_merged - date_created).total_seconds()

                data.append({'number': number,
                             'time': f'{int(time_diff)} (in seconds)'})

        page += 1

    return data


if __name__ == '__main__':
    print(get_pull_requests())
