'''
 Copyright 2022 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 '''

#Import PySpark packages
from pyspark.sql import SparkSession
from pyspark.ml.feature import StopWordsRemover
from pyspark.sql import functions as F

#Building Spark Session
spark = SparkSession.builder \
.appName('Test')\
.getOrCreate()

table = "bigquery-public-data.wikipedia.pageviews_2019"

#Reading data from BigQuery public dataset table containing Wikipedia pageviews for 2019
df_wiki_pageviews = spark.read \
.format("bigquery") \
.option("table", table) \
.option("filter", "datehour >= '2019-01-01' ") \
.load()

#Filtering data to view top 20 pages with more than 10 views
df_wiki_all = df_wiki_pageviews \
.select("title", "wiki", "views") \
.where("views > 10")

df_wiki_all.cache()

df_wiki_en = df_wiki_all \
.where("wiki in ('en', 'en.m')")
df_wiki_en_totals = df_wiki_en \
.groupBy("title") \
.agg(F.sum('views').alias('total_views'))

df_wiki_en_totals.orderBy('total_views', ascending=False).show(20)
