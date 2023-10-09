import argparse
import json
from typing import TypedDict

from google.cloud import pubsub_v1
from google.oauth2 import service_account


class BannedCountyMessage(TypedDict):
    country: str


def main(project_id, subscription_id, service_acct_json):
    # load credentials from file
    credentials = service_account.Credentials.from_service_account_file(
        filename=service_acct_json
    )

    subscriber = pubsub_v1.SubscriberClient(credentials=credentials)
    subscription_path = subscriber.subscription_path(project_id, subscription_id)

    # Listen for messages on the subscription
    def callback(message: pubsub_v1.subscriber.message.Message):
        message.ack()
        msg_json: BannedCountyMessage = json.loads(message.data.decode("utf-8"))
        print(f"Request received from banned country: {msg_json['country']}")

    # Block the thread until an exception is raised
    future = subscriber.subscribe(subscription_path, callback=callback)
    print("Listening for messages on subscription...")
    future.result()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--project_id",
        help="The ID of the project that owns the subscription",
        required=True,
    )
    parser.add_argument(
        "--subscription_id",
        help="The ID of the Pub/Sub subscription",
        required=True,
    )
    parser.add_argument(
        "--service_acct_json",
        help="The path to the service account json file",
        required=True,
    )
    args = parser.parse_args()

    main(args.project_id, args.subscription_id, args.service_acct_json)
