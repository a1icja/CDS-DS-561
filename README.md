# GCP Bucket PageRank

[GitHub](https://github.com/braxton/GCP-Bucket-PageRank)

Implementation of PageRank across files on a GCP Bucket

Made for CDS DS 561: Cloud Computing  
Professor: [Leonidas Kontothanassis](https://www.bu.edu/cds-faculty/profile/kthanasi/)

---

[Overview](#overview)

[Arguments](#arguments)

[Usage](#usage)

## Overview

This project can be broken into its individual components:

1. [Load data from GCP bucket](#load-data-from-gcp-bucket)
2. [Create adjacency matrix](#create-adjacency-matrix)
3. [Calculate statistics](#calculate-statistics)
4. [Calculate PageRank](#calculate-pagerank)

As well as two optional components:

1. [Load data from local file](#load-data-from-local-file)
2. [Calculate PageRank with NetworkX](#calculate-pagerank-with-networkx)

### Load data from GCP bucket

The `read_files_from_gcp_bucket` function reads all the files from a specified directory in a Google Cloud Platform (GCP) bucket. It does this by first creating an anonymous instance of the storage.Client class, which allows access to the GCP Storage service. It then attempts to get a reference to the specified bucket, raising an exception if the bucket does not exist. Next, it lists the blobs (files) in the bucket, filtering by the specified directory. An empty list of files is created to store the downloaded file contents, and a thread pool executor is created to parallelize the download process. The code then maps the blobs to a function that downloads them, and stores the downloaded files in the appropriate slot in the files list based on the file number. Finally, the list of files is reduced to a single string list, concatenating all the downloaded file contents, and the list of strings is returned.

### Create adjacency matrix

The `create_adjacency_matrix` function creates an adjacency matrix based on the hyperlinks in a list of file contents. It does this by first defining a regular expression to match HTML anchor tags (href tags) that contain a file number. Then, it creates a 2D numpy array to store the adjacency matrix, initially filling it with zeros. It uses the trange function to iterate over the file contents, and for each file, it finds all matches of the regular expression using the re.finditer function. It extracts the file number from the match object and subtracts 1 to get the index of the target file, and sets the corresponding entry in the adjacency matrix to 1 to indicate an edge between the two files. Finally, the adjacency matrix is returned.

### Calculate statistics

The `calculate_stats` function performs statistical analysis on an adjacency matrix representing a network of hyperlinks between files. It calculates various statistics related to the matrix, such as the sum of each row and column, the mean, median, maximum, and minimum values of each row and column, and the quintiles of each row and column. The statistics are calculated for both the incoming and outgoing links and then printed.

### Calculate PageRank

The `calculate_pagerank` function calculates the PageRank of a network represented by an adjacency matrix. It starts by initializing the pagerank variable to be a vector of ones, with the same length as the number of pages. The pagerank value for each page is initially set to `1/num_pages`, where num_pages is the number of pages in the network. It then defines an error tolerance and a variable to store the previous sum of pagerank values. Next, it iterates through each page in the network, and for each page, it calculates the incoming links and outgoing links. The code then calculates the new pagerank value for the current page using the formula: `new_pagerank = 0.15 + 0.85 * sum(old_pagerank[incoming_links] / num_outgoing_links[incoming_links])`, where `old_pagerank` is the current pagerank values, `incoming_links` is the set of pages that link to the current page, and `num_outgoing_links[incoming_links]` is the number of outgoing links for each page in the `incoming_links`` set. It then updates the pagerank values and the sum of pagerank values after the iteration. The code checks if the difference between the sum of pagerank values and the previous sum of pagerank values is less than the error tolerance. If it is, the loop stops. Finally, the code prints the calculated pagerank values. It sorts the pages based on their pagerank values in descending order and stores the top n pages. The code then prints the top n pages and their pagerank values.

### Load data from local file

The `read_files_from_local_fs` function reads all the files from a specified directory on a local file system. For each file, it extracts the file number from the file name using a regular expression, and then reads the file content using the open function. The file content is stored in a list of file contents, and the list is returned.

### Calculate PageRank with NetworkX

The `calculate_pagerank_nx` function calculates the PageRank of a network represented by an adjacency matrix using the NetworkX library. It starts by creating a directed graph from the adjacency matrix using the nx.from_numpy_array function. It then calculates the PageRank of the graph using the nx.pagerank function, with an alpha value of 0.85. The code sorts the PageRank values in descending order using the sorted function and the key argument, and extracts the top n pages based on the sorted PageRank values using the [:top_n] slice. Next, it prints the position and PageRank of each of the top n pages using the print function, and prints a newline using the print function to separate the output.

## Arguments

The program takes the following arguments:

#### GCP

- `--bucket <str>`: The name of the GCP bucket to read files from.
- `--bucket-dir <str>`: The name of the directory in the GCP bucket to read files from.

#### Local

- `--local`: A flag indicating whether to read files from the local file system.
- `--local-dir <str>`: The name of the directory on the local file system to read files from.

#### Both

- `--top <int>`: The number of top pages to print.

#### Optional

- `--pagerank-nx`: A flag indicating whether to calculate PageRank using NetworkX.

## Usage

To run the program, use the following command:

```bash
python3 main.py --bucket ds561-amahr-hw2 --bucket-dir files/ --top 5
```

To run the program with local files, use the following command:

```bash
python3 main.py --local --local-dir [file-dir] --top 5
```

To run the program with GCP and NetworkX, use the following command:

```bash
python3 main.py --bucket ds561-amahr-hw2 --bucket-dir files/ --top 5 --pagerank-nx
```
