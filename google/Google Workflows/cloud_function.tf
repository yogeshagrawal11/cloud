


#-------  Provider Information  ------------


variable localip {
  default = "73.53.79.47/32"
}

variable gcpprojectid {
  default = "yagrawal999"

}

#-------  Provider Information  ------------


provider "google" {
  region  = "us-west3"
  zone    = "us-west3-a"
  project = var.gcpprojectid

}

##############    Google network connectivity 

variable bucketname {
  default = "yogeshagrawal"
}



#### Add function

resource "google_storage_bucket_object" "cl_funct_add_file" {
  name   = "cl_funct_add_code.zip"
  bucket = var.bucketname
  source = "./cl_funct_add_code.zip"
}


resource "google_cloudfunctions_function" "cl_funct_add" {
  name        = "cl_funct_add"
  description = "ADD function"
  runtime     = "python37"


  available_memory_mb   = 128
  source_archive_bucket = var.bucketname
  source_archive_object = google_storage_bucket_object.cl_funct_add_file.name
  trigger_http          = true
  entry_point           = "add_function"
}



resource "google_cloudfunctions_function_iam_member" "add_invoker" {
  cloud_function = google_cloudfunctions_function.cl_funct_add.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}


### subtract function


resource "google_storage_bucket_object" "cl_funct_subtract_file" {
  name   = "cl_funct_subtract_code.zip"
  bucket = var.bucketname
  source = "./cl_funct_subtract_code.zip"
}


resource "google_cloudfunctions_function" "cl_funct_subtract" {
  name        = "cl_funct_subtract"
  description = "subtract function"
  runtime     = "python37"


  available_memory_mb   = 128
  source_archive_bucket = var.bucketname
  source_archive_object = google_storage_bucket_object.cl_funct_subtract_file.name
  trigger_http          = true
  entry_point           = "subtract_function"
}



resource "google_cloudfunctions_function_iam_member" "subtract_invoker" {
  cloud_function = google_cloudfunctions_function.cl_funct_subtract.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}



#### multiple function 



resource "google_storage_bucket_object" "cl_funct_multi_file" {
  name   = "cl_funct_multi_code.zip"
  bucket = var.bucketname
  source = "./cl_funct_multi_code.zip"
}


resource "google_cloudfunctions_function" "cl_funct_multi" {
  name        = "cl_funct_multi"
  description = "multi function"
  runtime     = "python37"


  available_memory_mb   = 128
  source_archive_bucket = var.bucketname
  source_archive_object = google_storage_bucket_object.cl_funct_multi_file.name
  trigger_http          = true
  entry_point           = "multi_function"
}



resource "google_cloudfunctions_function_iam_member" "multi_invoker" {
  cloud_function = google_cloudfunctions_function.cl_funct_multi.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}


##### Sq function


resource "google_storage_bucket_object" "cl_funct_sq_file" {
  name   = "cl_funct_sq_code.zip"
  bucket = var.bucketname
  source = "./cl_funct_sq_code.zip"
}


resource "google_cloudfunctions_function" "cl_funct_sq" {
  name        = "cl_funct_sq"
  description = "sq function"
  runtime     = "python37"


  available_memory_mb   = 128
  source_archive_bucket = var.bucketname
  source_archive_object = google_storage_bucket_object.cl_funct_sq_file.name
  trigger_http          = true
  entry_point           = "sq_function"
}



resource "google_cloudfunctions_function_iam_member" "sq_invoker" {
  cloud_function = google_cloudfunctions_function.cl_funct_sq.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

### outputs 
output "cl_function_add_url" {
  value = google_cloudfunctions_function.cl_funct_add.https_trigger_url
}

output "cl_function_subtract_url" {
  value = google_cloudfunctions_function.cl_funct_subtract.https_trigger_url
}

output "cl_function_multi_url" {
  value = google_cloudfunctions_function.cl_funct_multi.https_trigger_url
}

output "cl_function_sq_url" {
  value = google_cloudfunctions_function.cl_funct_sq.https_trigger_url
}


