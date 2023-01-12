#!/usr/bin/env python
# coding: utf-8

import os

default_spark_master = "local[*]"
app_name = "data-summary"
default_input_file = "churn-etl"
default_output_prefix = ""
default_input_kind = "parquet"

import argparse
import pyspark
import pyspark.sql.types as T
import pyspark.sql.functions as F

parser = parser = argparse.ArgumentParser()
parser.add_argument('--input-file', help='supplied input data (default="%s")' % default_input_file, default=default_input_file)
parser.add_argument('--input-kind', help='supplied input data (default="%s")' % default_input_kind, default=default_input_kind)
parser.add_argument('--output-prefix', help='text to prepend to every output file; the default is empty)', default=default_output_prefix)

def isnumeric(data_type):
    numeric_types = [T.ByteType, T.ShortType, T.IntegerType, T.LongType, T.FloatType, T.DoubleType, T.DecimalType]
    return any([isinstance(data_type, t) for t in numeric_types])


def percent_true(df, cols):
    denominator = df.count()
    return {col : df.where(F.col(col) == True).count() / denominator for col in cols}


def approx_cardinalities(df, cols):
    from functools import reduce
    
    counts = df.groupBy(
        F.lit(True).alias("drop_me")
    ).agg(
        F.count('*').alias("total"),
        *[F.approx_count_distinct(F.col(c)).alias(c) for c in cols]
    ).drop("drop_me").cache()
    
    result = reduce(lambda l, r: l.unionAll(r), [counts.select(F.lit(c).alias("field"), F.col(c).alias("approx_count")) for c in counts.columns]).collect()
    counts.unpersist()
    
    return dict([(r[0],r[1]) for r in result])


def likely_unique(counts):
    total = counts["total"]
    return [k for (k, v) in counts.items() if k != "total" and abs(total - v) < total * 0.15]


def likely_categoricals(counts):
    total = counts["total"]
    return [k for (k, v) in counts.items() if v < total * 0.15 or v < 128]

def unique_values(df, cols):
    from functools import reduce
    
    counts = df.groupBy(
        F.lit(True).alias("drop_me")
    ).agg(
        *[F.array_sort(F.collect_set(F.col(c))).alias(c) for c in cols]
    ).drop("drop_me").cache()
    
    result = reduce(lambda l, r: l.unionAll(r), [counts.select(F.lit(c).alias("field"), F.col(c).alias("unique_vals")) for c in counts.columns]).collect()
    counts.unpersist()
    
    return dict([(r[0],r[1]) for r in result])


def approx_ecdf(df, cols):
    from functools import reduce
    
    quantiles = [0.0, 0.01, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99, 1.0]

    qs = df.approxQuantile(cols, quantiles, 0.01)
    
    result = dict(zip(cols, qs))
    return {c: dict(zip(quantiles, vs)) for (c, vs) in result.items()}


def gen_summary(df):
    summary = {}
    
    string_cols = []
    boolean_cols = []
    numeric_cols = []
    other_cols = []

    
    for field in df.schema.fields:
        if isinstance(field.dataType, T.StringType):
            string_cols.append(field.name)
        elif isinstance(field.dataType, T.BooleanType):
            boolean_cols.append(field.name)
        elif isnumeric(field.dataType):
            numeric_cols.append(field.name)
        else:
            other_cols.append(field.name)
    
    cardinalities = approx_cardinalities(df, string_cols)
    uniques = likely_unique(cardinalities)
    categoricals = unique_values(df, likely_categoricals(cardinalities))
    
    encoding_struct = {
        "categorical" : categoricals,
        "numeric" : numeric_cols + boolean_cols,
        "unique": uniques
    }
    
    summary["schema"] = df.schema.jsonValue()
    summary["ecdfs"] = approx_ecdf(df, numeric_cols)
    summary["true_percentage"] = percent_true(df, boolean_cols)
    summary["encoding"] = encoding_struct
    
    return summary



if __name__ == "__main__":
    import json

    args = parser.parse_args()
    session = pyspark.sql.SparkSession.builder.appName(app_name).getOrCreate()
    df = session.read.parquet("%s.%s" % (args.input_file, args.input_kind))

    summary = gen_summary(df)

    with open("%ssummary.json" % args.output_prefix, "w") as sf:
        json.dump(summary, sf)
    
    with open("%sencodings.json" % args.output_prefix, "w") as ef:
        json.dump(summary["encoding"], ef)
