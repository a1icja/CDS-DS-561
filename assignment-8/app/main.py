import ast
import json
from os import environ
from typing import TypedDict

import flask
from google.cloud import storage
from waitress import serve

ZONE = environ.get("ZONE")
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

if ZONE is None:
    raise Exception("ZONE environment variable must be set")


class BannedCountyMessage(TypedDict):
    country: str


app = flask.Flask(__name__)


@app.route("/healthz", methods=["GET"])
def healthz():
    return "OK", 200


@app.route("/<bucket_name>/<path:web_path>", methods=HTTP_METHODS)
def bucket_file_get(bucket_name, web_path) -> flask.Response:
    if flask.request.method != "GET":
        return "Method not implemented", 501

    storage_client = storage.Client.create_anonymous_client()

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
        # 400 seems odd, but it's in the instructions, so...
        return "Forbidden", 400

    try:
        bucket = storage_client.bucket(bucket_name)
    except Exception as e:
        err_str = f"[404] Bucket does not exist or is inaccessible: {bucket_name}"
        return err_str, 404

    blob = bucket.get_blob(web_path)
    if blob is None:
        err_str = (
            f"[404] Blob does not exist or is inaccessible: {bucket_name}/{web_path}"
        )
        return err_str, 404

    return blob.download_as_string()


@app.after_request
def add_header(response):
    response.headers["X-zone"] = ZONE
    return response


if __name__ == "__main__":
    serve(app, host="0.0.0.0", port=PORT)
