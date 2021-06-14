from datetime import datetime
from string import Template
import os
import json
from python_graphql_client import GraphqlClient


def build_comment_query(cursor):
    return Template("""
        comments(first: 100, after: $cursor) {
            nodes {
                author { login }
            }
            pageInfo {
                hasNextPage
                endCursor
            }
        }
    """).substitute({'cursor': cursor})


def build_timeline_query(cursor):
    return Template("""
        timelineItems(itemTypes: LABELED_EVENT, first: 100, after: $cursor) {
            nodes {
                ... on LabeledEvent {
                    actor { login }
                    label { name }
                }
            }
            pageInfo {
                hasNextPage
                endCursor
            }
        }
    """).substitute({'cursor': cursor})


def build_query(pr_cursor, comment_cursor, timeline_cursor):
    """Build query for a single call to GitHub API

    Parameters:
        pr_cursor (int): Cursor of last requested Pull-Request
        comment_cursor (int): Cursor of last requested Comment
        timeline_cursor (int): Cursor of last requested Timeline
    """
    comment_query = build_comment_query(comment_cursor)
    timeline_query = build_timeline_query(timeline_cursor)

    query = Template("""query PRQuery($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
            pullRequests(states: MERGED, last: 1, before: $cursor) {
                nodes {
                    number
                    createdAt
                    mergedAt
                    author { login }
                    $comment_query
                    $timeline_query
                }
                pageInfo {
                    hasPreviousPage
                    startCursor
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
    """).safe_substitute({'cursor': pr_cursor,
                     'comment_query': comment_query,
                     'timeline_query': timeline_query})

    return query


def compute_duration(created_at, merged_at):
    """Compute duration that a merged PR was open (in seconds)"""
    format_str = r"%Y-%m-%dT%H:%M:%SZ"
    date_created = datetime.strptime(created_at, format_str)
    date_merged = datetime.strptime(merged_at, format_str)
    time_diff = (date_merged - date_created).total_seconds()
    return int(time_diff)


def get_pr_data():
    client = GraphqlClient(endpoint='https://api.github.com/graphql')

    pr_cursor = "null"
    comment_cursor = "null"
    timeline_cursor = "null"

    data = client.execute(
        query=build_query(pr_cursor, comment_cursor, timeline_cursor),
        variables={"owner": "operator-framework", "name": "community-operators"},
        headers={'Authorization': f"Bearer {os.environ['GH_TOKEN']}"}
    )

    return json.dumps(data, indent=2)


if __name__ == '__main__':
    print(get_pr_data())
