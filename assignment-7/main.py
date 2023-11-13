import argparse
import re

import apache_beam as beam
from apache_beam.io import fileio

parser = argparse.ArgumentParser()
parser.add_argument(
    "--input",
    dest="input",
    default="files/*.html",
    help="Input file to process.",
)
parser.add_argument(
    "--output",
    dest="output",
    default="output.txt",
    help="Output file to write results to.",
)
known_args, pipeline_args = parser.parse_known_args()


with beam.Pipeline(argv=pipeline_args) as pipeline:
    files = (
        pipeline
        | fileio.MatchFiles(known_args.input)
        | fileio.ReadMatches()
        | beam.Reshuffle()
    )

    filesWithContents = files | "Read files" >> beam.Map(
        lambda x: (x.metadata.path, x.read().decode("utf-8"))
    )

    incoming = (
        filesWithContents
        | "Make list of all HREF refs"
        >> beam.FlatMap(
            lambda line: [int(x) for x in re.findall(r'HREF="(\d*).html"', line[1])]
        )
        | "Count instances of each file" >> beam.combiners.Count.PerElement()
        | "Grab the top 5 IL" >> beam.combiners.Top.Of(5, key=lambda x: x[1])
    )

    outgoing = (
        filesWithContents
        | "Count the number of HREFs within each file"
        >> beam.Map(
            lambda line: (
                int(line[0].split("/")[-1].split(".")[0]),
                len(re.findall(r'HREF="(\d*).html"', line[1])),
            )
        )
        | "Grab the top 5 OL" >> beam.combiners.Top.Of(5, key=lambda x: x[1])
    )

    # Write incoming and outgoing to the same file
    (
        (incoming, outgoing)
        | "Merge the two PCollections" >> beam.Flatten()
        | "Write to file" >> beam.io.WriteToText(known_args.output)
    )
