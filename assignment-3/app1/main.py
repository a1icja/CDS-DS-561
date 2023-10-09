import ast
import concurrent.futures
import json
from typing import TypedDict

import flask
import functions_framework
from google.cloud import pubsub_v1, storage

PROJECT_ID = "ds561-amahr"
TOPIC_ID = "banned-countries"


class BannedCountyMessage(TypedDict):
    country: str


@functions_framework.http
def bucket_file_get(request: flask.request) -> flask.Response:
    if request.method != "GET":
        print(f"Invalid method requested: {request.method}")
        return "Method not implemented", 501

    request_path_split = request.path.split("/")
    bucket_name = request_path_split[1]
    web_path = "/".join(request_path_split[2:])

    storage_client = storage.Client.create_anonymous_client()
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)

    banned_countries = [
        "North Korea",
        "Iran",
        "Cuba",
        "Myanmar",
        "Iraq",
        "Libya",
        "Sudan",
        "Zimbabwe",
        "Syria",
    ]

    if request.headers.get("X-country") in banned_countries:
        message: BannedCountyMessage = {"country": request.headers.get("X-country")}
        msg_json = ast.literal_eval(json.dumps(message))

        print(f"Received request from banned country: {message['country']}")

        try:
            future = publisher.publish(
                topic_path, data=json.dumps(msg_json).encode("utf-8")
            )
            future.result()
        except concurrent.futures.TimeoutError as e:
            print(f"Error publishing message to topic - timeout: {e}")

        # 400 seems odd, but it's in the instructions, so...
        return "Forbidden", 400

    try:
        bucket = storage_client.bucket(bucket_name)
    except Exception as e:
        err_str = f"Bucket does not exist or is inaccessible: {bucket_name}"
        print(err_str)
        return err_str, 404

    blob = bucket.get_blob(web_path)
    if blob is None:
        err_str = f"Blob does not exist or is inaccessible: {bucket_name}/{web_path}"
        print(err_str)
        return err_str, 404

    return blob.download_as_string()
