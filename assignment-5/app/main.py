import ast
import concurrent.futures
import json
from os import environ
from typing import TypedDict

import flask
import sqlalchemy
from google.cloud import logging, pubsub_v1, storage
from google.cloud.sql.connector import Connector
from sqlalchemy.orm import declarative_base
from waitress import serve

# ------ ENVIRONMENT VARIABLES ------

PROJECT_ID = environ.get("PROJECT_ID")
TOPIC_ID = environ.get("TOPIC_ID")
PORT = environ.get("PORT", 80)

DB_USER = environ.get("DB_USER")
DB_PASS = environ.get("DB_PASS")
DB_NAME = environ.get("DB_NAME")
DB_INSTANCE_CONN_NAME = environ.get("DB_INSTANCE_CONN_NAME")

if PROJECT_ID is None:
    raise Exception("PROJECT_ID environment variable not set")
if TOPIC_ID is None:
    raise Exception("TOPIC_ID environment variable not set")

# ------ CONSTANTS ------

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

BANNED_COUNTRIES = [
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

# ------ Class Instances ------

app = flask.Flask(__name__)
log_client = logging.Client()
db_connector = Connector()

storage_client = storage.Client.create_anonymous_client()
publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)

# ------ Database Setup ------


def get_db_conn():
    conn = db_connector.connect(
        DB_INSTANCE_CONN_NAME,
        "pymysql",
        user=DB_USER,
        password=DB_PASS,
        db=DB_NAME,
    )
    return conn


db_pool = sqlalchemy.create_engine(
    "mysql+pymysql://",
    creator=get_db_conn,
)

Base = declarative_base()

with db_pool.connect() as conn:
    create_req_table_query = sqlalchemy.text(
        'CREATE TABLE IF NOT EXISTS requests( request_id INT AUTO_INCREMENT PRIMARY KEY, request_time TIMESTAMP, requested_file VARCHAR(255), is_banned BOOLEAN, client_country VARCHAR(255), client_ip VARCHAR(15), gender ENUM("Male", "Female"), age ENUM( "0-16", "17-25", "26-35", "36-45", "46-55", "56-65", "66-75", "76+"), income ENUM( "0-10k", "10k-20k", "20k-40k", "40k-60k", "60k-100k", "100k-150k", "150k-250k", "250k+" ) );'
    )
    conn.execute(create_req_table_query)

    create_failed_req_table_query = sqlalchemy.text(
        "CREATE TABLE IF NOT EXISTS failed_requests( failed_request_id INT AUTO_INCREMENT PRIMARY KEY, request_time TIMESTAMP NOT NULL, requested_file VARCHAR(255) NOT NULL, error_code INT NOT NULL)"
    )
    conn.execute(create_failed_req_table_query)

    conn.commit()

# ------ Classes ------


class BannedCountyMessage(TypedDict):
    country: str


class Requests(Base):
    __table__ = sqlalchemy.Table("requests", Base.metadata, autoload_with=db_pool)


class FailedRequests(Base):
    __table__ = sqlalchemy.Table("failed_requests", Base.metadata, autoload_with=db_pool)


# ------ Helper Functions ------


def insert_failed_req_into_db(req_time, req_file, err_code):
    with db_pool.connect() as conn:
        insert_query = sqlalchemy.insert(FailedRequests).values(
            request_time=req_time,
            requested_file=req_file,
            error_code=err_code,
        )

        conn.execute(insert_query)
        conn.commit()


# ------ Routes ------


@app.route("/<bucket_name>/<path:web_path>", methods=HTTP_METHODS)
def bucket_file_get(bucket_name, web_path) -> flask.Response:
    if flask.request.method != "GET":
        log_client.logger(PROJECT_ID).log_text(
            f"[501] Invalid method requested: {flask.request.method}"
        )
        return "Method not implemented", 501

    # ------ Headers and State ------

    req_country = flask.request.headers.get("X-country")
    req_ip = flask.request.headers.get("X-client-IP")
    req_gender = flask.request.headers.get("X-gender")
    req_age = flask.request.headers.get("X-age")
    req_income = flask.request.headers.get("X-income")
    req_time = flask.request.headers.get("X-time")

    is_banned = req_country in BANNED_COUNTRIES

    # ------ Logging ------

    with db_pool.connect() as conn:
        insert_query = sqlalchemy.insert(Requests).values(
            request_time=req_time,
            requested_file=web_path,
            is_banned=is_banned,
            client_country=req_country,
            client_ip=req_ip,
            gender=req_gender,
            age=req_age,
            income=req_income,
        )

        conn.execute(insert_query)
        conn.commit()

    # ------ Banned Country Check ------

    if req_country in BANNED_COUNTRIES:
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

        return_code = 400
        insert_failed_req_into_db(req_time, web_path, return_code)
        return "Forbidden", return_code

    # ------ Bucket Fetching ------

    try:
        bucket = storage_client.bucket(bucket_name)
    except Exception as e:
        err_str = f"[404] Bucket does not exist or is inaccessible: {bucket_name}"
        log_client.logger(PROJECT_ID).log_text(err_str)
        return_code = 404
        insert_failed_req_into_db(req_time, web_path, return_code)
        return err_str, return_code

    # ------ Blob Fetching ------

    blob = bucket.get_blob(web_path)
    if blob is None:
        err_str = (
            f"[404] Blob does not exist or is inaccessible: {bucket_name}/{web_path}"
        )
        log_client.logger(PROJECT_ID).log_text(err_str)
        return_code = 404
        insert_failed_req_into_db(req_time, web_path, return_code)
        return err_str, return_code

    return blob.download_as_string()


if __name__ == "__main__":
    serve(app, host="0.0.0.0", port=PORT)
