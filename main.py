import argparse
import os
import re
import time
from concurrent.futures import ThreadPoolExecutor
from functools import reduce
from math import ceil, floor

import google.api_core.exceptions
import networkx as nx
import numpy as np
from google.cloud import storage
from tqdm import tqdm, trange

parser = argparse.ArgumentParser(description="ds561-amahr-hw2")
parser.add_argument(
    "--local",
    dest="local",
    action="store_true",
    help="Read files from local filesystem",
)
parser.add_argument(
    "--local-dir",
    dest="local_dir",
    type=str,
    help="Local filesystem directory",
)
parser.add_argument(
    "--bucket",
    dest="bucket",
    type=str,
    help="GCP bucket name",
)
parser.add_argument(
    "--bucket-dir",
    dest="dir",
    type=str,
    help="GCP bucket directory",
)
parser.add_argument(
    "--top",
    dest="top",
    type=int,
    default=5,
    help="Top N pages to display",
    required=True,
)
parser.add_argument(
    "--pagerank-nx",
    dest="pagerank_nx",
    action="store_true",
    help="Display networkx pagerank algorithm results",
)
args = parser.parse_args()


def read_files_from_local_fs(directory: str) -> list[str]:
    dir_files = os.listdir(directory)
    files = [None] * len(dir_files)

    for file in tqdm(dir_files):
        file_num_regex = r"(\d+).html"
        file_num = int(re.search(file_num_regex, file).group(1)) - 1

        with open(f"{directory}/{file}", "r") as f:
            files[file_num] = f.read()
    return files


def read_files_from_gcp_bucket(bucket_name: str, dir: str) -> list[str]:
    gcp_storage_client = storage.Client.create_anonymous_client()

    try:
        bucket = gcp_storage_client.bucket(bucket_name)
    except google.api_core.exceptions.NotFound:
        raise Exception(f"Bucket {bucket_name} does not exist")

    blob_list = list(bucket.list_blobs(prefix=dir))
    files = [None] * len(blob_list)

    def download_blob(blob: storage.Blob) -> str:
        return {"name": blob.name, "content": blob.download_as_string()}

    with ThreadPoolExecutor() as executor:
        for blob in tqdm(executor.map(download_blob, blob_list), total=len(blob_list)):
            file_num_regex = r"(\d+).html"
            file_num = int(re.search(file_num_regex, blob["name"]).group(1)) - 1
            files[file_num] = blob["content"]

    files = reduce(lambda a, b: a + [str(b)], files, [])
    return files


def create_adjacency_matrix(file_contents: list[str]) -> np.ndarray:
    href_regex = r"HREF=\"(\d+).html\""
    adj_matrix = np.zeros((len(file_contents), len(file_contents)))
    for i in trange(len(file_contents)):
        matches = re.finditer(href_regex, file_contents[i])
        for match in matches:
            adj_matrix[i, int(match.group(1)) - 1] = 1
    return adj_matrix


def calculate_stats(adj_matrix: np.ndarray) -> None:
    adj_matrix_sum_0 = adj_matrix.sum(axis=0)
    adj_matrix_sum_1 = adj_matrix.sum(axis=1)

    average_incoming_links = np.mean(adj_matrix_sum_0)
    median_incoming_links = np.median(adj_matrix_sum_0)
    max_incoming_links = max(adj_matrix_sum_0)
    min_incoming_links = min(adj_matrix_sum_0)
    quintiles_incoming_links = np.quantile(adj_matrix_sum_0, [0.2, 0.4, 0.6, 0.8, 1])

    average_outgoing_links = np.mean(adj_matrix_sum_1)
    median_outgoing_links = np.median(adj_matrix_sum_1)
    max_outgoing_links = max(adj_matrix_sum_1)
    min_outgoing_links = min(adj_matrix_sum_1)
    quintiles_outgoing_links = np.quantile(adj_matrix_sum_1, [0.2, 0.4, 0.6, 0.8, 1])

    print("Incoming Links:")
    print(f"    Average: {average_incoming_links}")
    print(f"    Median: {median_incoming_links}")
    print(f"    Max: {max_incoming_links}")
    print(f"    Min: {min_incoming_links}")
    print(f"    Quintiles: {quintiles_incoming_links}")
    print()
    print("Outgoing Links:")
    print(f"    Average: {average_outgoing_links}")
    print(f"    Median: {median_outgoing_links}")
    print(f"    Max: {max_outgoing_links}")
    print(f"    Min: {min_outgoing_links}")
    print(f"    Quintiles: {quintiles_outgoing_links}")
    print()


def calculate_pagerank(adj_matrix: np.ndarray, top_n: int) -> None:
    pagerank = np.ones(adj_matrix.shape[0]) / adj_matrix.shape[0]

    err = 1.0
    while err > 0.005:
        prev_pagerank_sum = pagerank.sum()
        for i in trange(adj_matrix.shape[0]):
            incoming_links = np.where(adj_matrix[:, i] == 1)[0]
            outgoing_links = adj_matrix[incoming_links, :]

            pagerank[i] = 0.15 + 0.85 * np.sum(
                pagerank[incoming_links] / outgoing_links.sum(axis=1)
            )
        pagerank_sum = pagerank.sum()
        err = np.sum(pagerank_sum - prev_pagerank_sum) / prev_pagerank_sum
    print()  # tqdm spacing
    # pagerank /= pagerank.sum()
    top_pages = np.argsort(pagerank)[::-1][:top_n]
    print("Unnormalised PageRank:")
    for i in range(top_n):
        print(
            f"Pos {i+1} = Page: {top_pages[i] + 1} | PageRank: {pagerank[top_pages[i]]}"
        )
    print()
    print("Normalized PageRank:")
    normalised_pagerank = pagerank / pagerank.sum()
    for i in range(top_n):
        print(
            f"Pos {i+1} = Page: {top_pages[i] + 1} | PageRank: {normalised_pagerank[top_pages[i]]}"
        )
    print()


def calculate_pagerank_nx(adj_matrix: np.ndarray, top_n: int) -> None:
    G = nx.from_numpy_array(adj_matrix, create_using=nx.DiGraph)
    pagerank = nx.pagerank(G, alpha=0.85)
    top_pages = sorted(pagerank, key=pagerank.get, reverse=True)[:top_n]
    print("NetworkX (Normalised) PageRank:")
    for i in range(top_n):
        print(
            f"Pos {i+1} = Page: {top_pages[i] + 1} | PageRank: {pagerank[top_pages[i]]}"
        )
    print()


if __name__ == "__main__":
    start_time = time.time()

    if args.local:
        print("Reading files from local filesystem")
        if args.local_dir is None:
            raise Exception("Local directory must be specified")
        file_contents = read_files_from_local_fs(args.local_dir)
    else:
        print("Reading files from GCP bucket")
        if args.bucket is None:
            raise Exception("Bucket name must be specified when reading from GCP bucket")
        if args.dir is None:
            raise Exception(
                "Bucket directory must be specified when reading from GCP bucket"
            )
        file_contents = read_files_from_gcp_bucket(args.bucket, args.dir)

    adj_matrix = create_adjacency_matrix(file_contents)

    calculate_stats(adj_matrix)
    calculate_pagerank(adj_matrix, args.top)

    if args.pagerank_nx:
        calculate_pagerank_nx(adj_matrix, args.top)

    end_time = time.time()
    print(f"Elapsed time: about {ceil(end_time) - floor(start_time)} seconds")
