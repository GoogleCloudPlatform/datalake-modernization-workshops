#!/usr/bin/env python
# coding: utf-8

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
from churn.etl import cast_and_coalesce_wide_data
import os
import sys
import re
import json

app_name = "churn-etl"
default_input_files = dict(
    billing="billing_events", 
    account_features="customer_account_features", 
    internet_features="customer_internet_features", 
    meta="customer_meta", 
    phone_features="customer_phone_features"
)

default_output_file = "churn-etl"
default_output_prefix = ""
default_input_prefix = ""
default_output_mode = "overwrite"
default_output_kind = "parquet"
default_input_kind = "parquet"

parser = parser = argparse.ArgumentParser()
parser.add_argument('--output-file', help='location for denormalized output data (default="%s")' % default_output_file, default=default_output_file)
parser.add_argument('--output-mode', help='Spark data source output mode for the result (default: overwrite)', default=default_output_mode)
parser.add_argument('--input-prefix', help='text to prepend to every input file path (e.g., "hdfs:///churn-raw-data/"; the default is empty)', default=default_input_prefix)
parser.add_argument('--output-prefix', help='text to prepend to every output file (e.g., "hdfs:///churn-data-etl/"; the default is empty)', default=default_output_prefix)
parser.add_argument('--output-kind', help='output Spark data source type for the result (default: parquet)', default=default_output_kind)
parser.add_argument('--input-kind', help='Spark data source type for the input (default: parquet)', default=default_input_kind)
parser.add_argument('--summary-prefix', help='text to prepend to analytic reports (e.g., "reports/"; default is empty)', default='')
parser.add_argument('--report-file', help='location in which to store a performance report', default='report.txt')
parser.add_argument('--log-level', help='set log level (default: OFF)', default="OFF")
parser.add_argument('--coalesce-output', help='coalesce output to NUM partitions', default=0, type=int)
parser.add_argument('--use-calendar-arithmetic', help='use add_months() function (default: False)', action='store_const', const=True, default=False)
parser.add_argument('--skip-eda', help='skip analytic reporting; federate only (default: False)', action='store_const', const=True, default=False)
parser.add_argument('--debug-nulls', help='print out records containing NULLs as JSON objects (default: False)', action='store_const', const=True, default=False)

if __name__ == '__main__':
    import pyspark
    import os

    failed = False
    
    args = parser.parse_args()

    session = pyspark.sql.SparkSession.builder \
        .appName(app_name) \
        .getOrCreate()

    session.sparkContext.setLogLevel(args.log_level)

    session

    import churn.etl
    import churn.eda

    input_files = {k: "%s%s" % (args.input_prefix, v) for k, v in default_input_files.items()}

    churn.etl.register_options(
        app_name = app_name,
        input_files = input_files,
        output_prefix = args.output_prefix,
        output_mode = args.output_mode,
        output_kind = args.output_kind,
        input_kind = args.input_kind,
        output_file = args.output_file,
        coalesce_output = args.coalesce_output,
        use_calendar_arithmetic = args.use_calendar_arithmetic
    )

    from churn.etl import read_df
    billing_events = read_df(session, input_files["billing"])

    from churn.etl import join_billing_data
    customer_billing = join_billing_data(billing_events)

    from churn.etl import customers as get_customers
    customers = get_customers()

    phone_features = read_df(session, input_files["phone_features"])

    from churn.etl import join_phone_features
    customer_phone_features = join_phone_features(phone_features)

    internet_features = read_df(session, input_files["internet_features"])
    from churn.etl import join_internet_features
    customer_internet_features = join_internet_features(internet_features)

    account_features = read_df(session, input_files["account_features"])

    from churn.etl import join_account_features
    customer_account_features = join_account_features(account_features)

    account_meta = read_df(session, input_files["meta"])

    from churn.etl import process_account_meta
    customer_account_meta = process_account_meta(account_meta)

    from churn.etl import join_wide_table

    wide_data = join_wide_table(customer_billing, customer_phone_features, customer_internet_features, customer_account_features, customer_account_meta)

    from churn.etl import write_df
    import timeit
    
    temp_output_file = "intermediate-" + churn.etl.options['output_file']
    output_file = churn.etl.options['output_file']
    output_kind = churn.etl.options['output_kind']
    output_prefix = churn.etl.options['output_prefix']

    federation_time = timeit.timeit(lambda: write_df(wide_data, temp_output_file), number=1)

    # prepare data for training by casting decimals to floats and coalescing
    coalesce_time = timeit.timeit(lambda: write_df(cast_and_coalesce_wide_data(session.read.parquet(output_prefix + temp_output_file + "." + output_kind)), output_file), number=1)
    records = session.read.parquet(output_prefix + output_file + "." + output_kind)
    record_count = records.count()
    record_nonnull_count = records.dropna().count()

    if not args.skip_eda:
        analysis_time = timeit.timeit(lambda: churn.eda.output_reports(records, billing_events, args.summary_prefix), number=1)

    first_line = "Completed analytics pipeline (version %s)\n" % churn.etl.ETL_VERSION

    if not args.skip_eda:
        first_line += 'Total time was %.02f to generate and process %d records\n' % (analysis_time + federation_time + coalesce_time, record_count)
        first_line += 'Analytics and reporting took %.02f seconds\n' % analysis_time
    else:
        first_line += 'We ran with --skip-eda; not reporting analytics time\n'
    first_line += 'Coalescing and casting data for reporting and ML took %.02f seconds\n' % coalesce_time
    first_line += 'Federation took %.02f seconds; configuration follows:\n\n' % federation_time
    print(first_line)

    if record_nonnull_count != record_count:
        nulls = record_count - record_nonnull_count
        null_percent = (float(nulls) / record_count) * 100
        print('ERROR: analytics job generated %d records with nulls (%.02f%% of total)' % (nulls, null_percent))
        failed = True
        if args.debug_nulls:
            for row in records.subtract(records.dropna()).collect():
                print(json.dumps(row.asDict()))

    with open(args.report_file, "w") as report:
        report.write(first_line + "\n")
        for conf in session.sparkContext.getConf().getAll():
            report.write(str(conf) + "\n")
            print(conf)
    
    session.stop()

    if failed:
        print("Job failed (most likely due to nulls in output); check logs for lines beginning with ERROR")
        sys.exit(1)
    