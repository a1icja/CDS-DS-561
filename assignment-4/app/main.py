import ast
import concurrent.futures
import json
from os import environ
from typing import TypedDict

import flask
from google.cloud import logging, pubsub_v1, storage
from waitress import serve

PROJECT_ID = environ.get("PROJECT_ID")
TOPIC_ID = environ.get("TOPIC_ID")
PORT = environ.get("PORT", 80)
HTTP_METHODS = [
    "GET",
    "HEAD",
    "POST",
    "PUT",
    "DELETE",
    "CONNECT",
    "OPTIONS",
    "TRACE",
    "PATCH",
]

if PROJECT_ID is None:
    raise Exception("PROJECT_ID environment variable not set")
if TOPIC_ID is None:
    raise Exception("TOPIC_ID environment variable not set")


class BannedCountyMessage(TypedDict):
    country: str


app = flask.Flask(__name__)
log_client = logging.Client()


@app.route("/<bucket_name>/<path:web_path>", methods=HTTP_METHODS)
def bucket_file_get(bucket_name, web_path) -> flask.Response:
    if flask.request.method != "GET":
        log_client.logger(PROJECT_ID).log_text(
            f"[501] Invalid method requested: {flask.request.method}"
        )
        return "Method not implemented", 501

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

    if flask.request.headers.get("X-country") in banned_countries:
        message: BannedCountyMessage = {"country": flask.request.headers.get("X-country")}
        msg_json = ast.literal_eval(json.dumps(message))

        log_client.logger(PROJECT_ID).log_text(
            f"[400] Received request from banned country: {message['country']}"
        )

        try:
            future = publisher.publish(
                topic_path, data=json.dumps(msg_json).encode("utf-8")
            )
            future.result()
        except concurrent.futures.TimeoutError as e:
            log_client.logger(PROJECT_ID).log_text(
                f"Error publishing message to topic - timeout: {e}"
            )

        # 400 seems odd, but it's in the instructions, so...
        return "Forbidden", 400

    try:
        bucket = storage_client.bucket(bucket_name)
    except Exception as e:
        err_str = f"[404] Bucket does not exist or is inaccessible: {bucket_name}"
        log_client.logger(PROJECT_ID).log_text(err_str)
        return err_str, 404

    blob = bucket.get_blob(web_path)
    if blob is None:
        err_str = (
            f"[404] Blob does not exist or is inaccessible: {bucket_name}/{web_path}"
        )
        log_client.logger(PROJECT_ID).log_text(err_str)
        return err_str, 404

    return blob.download_as_string()


if __name__ == "__main__":
    serve(app, host="0.0.0.0", port=PORT)
