import requests
from datetime import datetime
from string import Template


def build_comment_query(cursor):
    return Template("""
        comments(first: 100, after: $cursor) {
            pageInfo {
                hasNextPage
                endCursor
            }
            nodes {
                author { login }
            }
        }
    """).substitute({'cursor': cursor})


def build_timeline_query(cursor):
    return Template("""
        timelineItems(itemTypes: LABELED_EVENT, first: 100, after: $cursor) {
            pageInfo {
                hasNextPage
                endCursor
            }
            nodes {
                ... on LabeledEvent {
                    actor { login }
                    label { name }
                }
            }
        }
    """).substitute({'cursor': cursor})


def build_query(pr_cursor=0, comment_cursor=0, timeline_cursor=0):
    """Build query for a single call to GitHub API

    Parameters:
        pr_cursor (int): Cursor of last requested Pull-Request
        comment_cursor (int): Cursor of last requested Comment
        timeline_cursor (int): Cursor of last requested Timeline
    """
    comment_query = build_comment_query(comment_cursor)
    timeline_query = build_timeline_query(timeline_cursor)

    query = Template("""query {
        repository(owner: “operator-framework”, name: “community-operators”) {
            pullRequests(states: MERGED, first: 100, after: $cursor) {
                pageInfo {
                    hasNextPage
                    endCursor
                }
                nodes {
                    number
                    createdAt
                    mergedAt
                    author { login }
                    $comment_query
                    $timeline_query
                }
            }
        }
        rateLimit {
            limit
            cost
            remaining
            resetAt
        }
    }
    """).substitute({'cursor': pr_cursor,
                     'comment_query': comment_query,
                     'timeline_query': timeline_query})
    
    return query


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
    print(build_query())
