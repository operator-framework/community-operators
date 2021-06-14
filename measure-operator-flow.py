from datetime import datetime
from graphql_handler import get_pr_data


def compute_duration(created_at, merged_at):
    """Compute duration that a merged PR was open (in seconds)"""
    format_str = r"%Y-%m-%dT%H:%M:%SZ"
    date_created = datetime.strptime(created_at, format_str)
    date_merged = datetime.strptime(merged_at, format_str)
    time_diff = (date_merged - date_created).total_seconds()
    return int(time_diff)


def main():
    pr_data = get_pr_data(last=5)
    print(len(pr_data))
    return [pr_data]


if __name__ == '__main__':
    print(main())
