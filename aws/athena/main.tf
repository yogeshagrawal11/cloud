variable region {}
variable gluedatabase {}
variable gluetable {} 
variable s3inputfolder {} 


data "aws_ssm_parameter" "s3bucket" {
  name = "s3bucket"
}

/*
data "aws_iam_policy" "AWSLambdaBasicExecutionRole-pol" {
  arn = "arn:aws:iam:::policy/AWSLambdaBasicExecutionRole"
}
data "aws_iam_policy" "AWSXRayDaemonWriteAccess-pol" {
  arn = "arn:aws:iam:::policy/AWSXRayDaemonWriteAccess"
}
*/
#-------  Provider Information  ------------
provider "aws" {
  version = "~> 2.0"
  region  = var.region
  profile = "ya"
  #access_key = "my-access-key"
  #secret_key = "my-secret-key"
}


#----------       ETL process 


resource "aws_glue_catalog_database" "app_glue_catalog_database" {
  name = var.gluedatabase
}



resource "aws_glue_catalog_table" "app_glue_catalog_table" {
  name          = var.gluetable
  database_name = aws_glue_catalog_database.app_glue_catalog_database.name
  depends_on = [aws_glue_catalog_database.app_glue_catalog_database]
    storage_descriptor {
      location      = "${data.aws_ssm_parameter.s3bucket.value}/${var.s3inputfolder}"  #### Add Source bucket folder 
      input_format  = "org.apache.hadoop.mapred.TextInputFormat"
      output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
      #org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe
      ser_de_info  {
          name = "serial"
          serialization_library  = "org.apache.hadoop.hive.serde2.OpenCSVSerde"
          parameters = {
              "quoteChar" = "'"
              "separatorChar" = ","
              "escapeChar" = "\\"
        }
      }
      columns {
      name = "name"
      type = "string"
      }
      columns {
      name = "latitude"
      type = "double"
      }
      columns {
      name = "longitude"
      type = "double"
      }
      columns {
      name = "state"
      type = "string"
      }
      columns {
      name = "est_year"
      type = "bigint"
      }
      columns {
      name = "est_day"
      type = "string"
      }
      columns {
      name = "sq-mi"
      type = "bigint"
      }
      columns {
      name = "sq_km"
      type = "bigint"
      }
      columns {
      name = "maxelev_ft"
      type = "bigint"
      }
      columns {
      name = "minelev_ft"
      type = "bigint"
      }
      columns {
      name = "bigint"
      type = "string"
      }
    
  } 
  parameters = {
    "skip.header.line.count" = 1 
  }
}

/*
resource "aws_glue_crawler" "app_glue_crawler" {
  database_name = aws_glue_catalog_database.app_glue_catalog_database.name
  name          = "crawler-name"
  role          = "arn:aws:iam::476929884197:role/service-role/AWSGlueServiceRole-s3pull"
  classifiers = [aws_glue_classifier.csv.name]

  s3_target {
    path = "s3://yogeshagrawal/source/nps/"
  }
  depends_on = [aws_glue_catalog_database.app_glue_catalog_database]
}


resource "aws_glue_classifier" "csv" {
  name = "csv"

  csv_classifier {
    allow_single_column    = false
    contains_header        = "PRESENT"
    delimiter              = ","
    disable_value_trimming = false
    #header                 = ["example1", "example2"]
    quote_symbol           = "'"
  }
}


*/
