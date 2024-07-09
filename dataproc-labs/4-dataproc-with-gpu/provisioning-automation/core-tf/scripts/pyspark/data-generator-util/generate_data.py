# Copyright (c) 2020–2021, NVIDIA Corporation.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import os
import sys
import re

default_app_name = "augment"
default_input_file = os.path.join("data", "WA_Fn-UseC_-Telco-Customer-Churn-.csv")
default_output_prefix = ""
default_output_mode = "overwrite"
default_output_kind = "parquet"

default_dup_times = 100

parser = parser = argparse.ArgumentParser()
parser.add_argument('--input-file', help='supplied input data (default="%s")' % default_input_file, default=default_input_file)
parser.add_argument('--output-mode', help='Spark data source output mode for the result (default: overwrite)', default=default_output_mode)
parser.add_argument('--output-prefix', help='text to prepend to every output file (e.g., "hdfs:///churn_utils.data/"; the default is empty)', default=default_output_prefix)
parser.add_argument('--output-kind', help='output Spark data source type for the result (default: parquet)', default=default_output_kind)
parser.add_argument('--dup-times', help='scale factor for augmented results (default: 100)', default=default_dup_times, type=int)
parser.add_argument('--use-decimal', help='use DecimalType for currencies (default: True)', default=True, type=bool)
parser.add_argument('--decimal-precision', help='set currency precision (default: 8; minimum: 6)', default=8, type=int)
parser.add_argument('--log-level', help='set log level (default: OFF)', default="OFF")

if __name__ == '__main__':
    import pyspark
    
    args = parser.parse_args()

    import churn_utils.augment

    churn_utils.augment.register_options(
        app_name = default_app_name,
        input_file = args.input_file,
        output_prefix = args.output_prefix,
        output_mode = args.output_mode,
        output_kind = args.output_kind,
        dup_times = args.dup_times,
        use_decimal = args.use_decimal,
        decimal_precision = args.decimal_precision
    )

    session = pyspark.sql.SparkSession.builder.\
        appName(churn_utils.augment.options['app_name']).\
        getOrCreate()

    session.sparkContext.setLogLevel(args.log_level)

    from churn_utils.augment import load_supplied_data

    df = load_supplied_data(session, args.input_file)

    from churn_utils.augment import billing_events
    billingEvents = billing_events(df)

    from churn_utils.augment import customer_meta
    customerMeta = customer_meta(df)

    from churn_utils.augment import phone_features
    customerPhoneFeatures = phone_features(df)

    from churn_utils.augment import internet_features
    customerInternetFeatures = internet_features(df)

    from churn_utils.augment import account_features
    customerAccountFeatures = account_features(df)

    from churn_utils.augment import write_df
    write_df(billingEvents, "billing_events", partition_by="month")
    write_df(customerMeta, "customer_meta", skip_replication=True)
    write_df(customerPhoneFeatures, "customer_phone_features")
    write_df(customerInternetFeatures.orderBy("customerID"), "customer_internet_features")
    write_df(customerAccountFeatures, "customer_account_features")

    print("sanity-checking outputs")

    import pyspark.sql.functions as F
    from functools import reduce

    output_dfs = []

    for f in ["billing_events", "customer_meta", "customer_phone_features", "customer_internet_features", "customer_account_features"]:
        output_dfs.append(
            session.read.parquet(churn_utils.augment.resolve_path(f)).select(
                F.lit(f).alias("table"),
                "customerID"
            )
        )

    all_customers = reduce(lambda l, r: l.unionAll(r), output_dfs)

    each_table = all_customers.groupBy("table").agg(F.approx_count_distinct("customerID").alias("approx_unique_customers"))
    overall = all_customers.groupBy(F.lit("all").alias("table")).agg(F.approx_count_distinct("customerID").alias("approx_unique_customers"))

    counts = dict([(row[0], row[1]) for row in each_table.union(overall).collect()])
    if counts['billing_events'] != counts['all']:
        print("warning:  approximate customer counts for billing events and union of all tables differ") 
        print("warning:  counts were as follows: ")
        for k,v in counts.items():
            print("  - %s -> %d" % (k, v))
        print("warning: doing precise counts now")

        all_customers = each_table.select("customerID").distinct().count()
        billing_customers = each_table.where(F.col("table") == "billing_events").select("customerID").distinct().count()

        assert all_customers == billing_customers, "precise counts of customers differ from the billing_events table and the union of all tables; this indicates spurious customer IDs in some table.  Please file an issue."
    else:
        print("info:  approximate counts seem okay!")
