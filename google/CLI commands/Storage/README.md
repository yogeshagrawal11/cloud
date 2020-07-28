# Cloud storage

gsutil rewrite -s [STORAGE_CLASS] gs://[PATH_TO_OBJECT] ### to change buckets storage class
gsutil mv gs://[SOURCE_BUCKET_NAME]/[SOURCE_OBJECT_NAME] gs://[DESTINATION_BUCKET_NAME]/[DESTINATION_OBJECT_NAME]
gsutil mb gs://[BUCKET_NAME]/

# Bigtable 

setup of bigtable environment
  gcloud components install cbt ### to install toold
  echo instance = [instance name] >> ~/.cbtrc
  
gcloud beta bugtable instances list

Bigtable HBASE operations 

  Create Bigtable 
    create 'tablename'.'column_family_name'
  Insert Column 
    put 'tablename','rowkey','columnfamily_name:column_name','column_name'
    
  Check all rows
    scan 'tablename'
   
  update Row 
    put 'table_name', 'rowkey', 'columnfamily_name:column_name','new_value'
  
  Disable Table 
    disable 'tablename'
  
  Delete Table 
     drop 'tablename'
     
CLI ACCESS
  cbt createtable [tablename]
  
  cbt ls
  
  cbt createfamily [tablename] [family name]
  
  cbt set [tablename] [rowid] [colfamily]:[colume name]=[value] #### to add row and colume
  
  cbt read [tablename]
  


# Cloud SQL

Cloud SQL Instance list
  gcloud sql instances list

Connect to Cloud SQL instance
  gcloud sql connect [INSTANCE-NAME] --user=root
  
  gcloud sql backups create ––async ––instance [INSTANCE_NAME] #### on demand backup
  
  gcloud sql instances patch [INSTANCE_NAME] –backup-start-time [HH:MM] #### automatic backup
  
  gcloud sql instances describe [INSTANCE_NAME] ### to get details about database and service account
  
  gsutil acl ch -u [SERVICE_ACCOUNT_ADDRESS]:W gs://[BUCKET_NAME] ### db service account access to write data to cloud storage bucket
  
  gcloud sql export sql [INSTANCE_NAME] gs://[BUCKET_NAME]/[FILE_NAME] --database=[DATABASE_NAME] ### export cloud sql database to cloud storage
  
  gcloud sql import sql [INSTANCE_NAME] gs://[BUCKET_NAME]/[IMPORT_FILE_NAME] --database=[DATABASE_NAME] ### to import database
  
  
  
# Cloud Datastore 
  Import/Export datastore database
  
    gcloud –namespaces='[NAMESPACE]' gs://[BUCKET_NAME}
    
    gcloud datastore export –namespaces='(default)' gs://[BUCKET_NAME] ### to export databse
    
    gcloud datastore import gs://[BUCKET]/[PATH]/[FILE].overall_export_metadata ## to import datanase
    
    
    
    



