# `ExportGS.rb`

The script `ExportGS.rb` allow you to download Address.csv from Google Spreadsheet.

## Synopsis

```
ExportGS2CSV.rb -c CONFIG_CSV
```

Here, 

* `CONFIG_CSV`: file provides mapping of file-id in Google Drive, expected export type, and file-name used for exported data.

## Format of `CONFIG_CSV`

The CSV file is like this:

|ID|Type|Filename|
|--|----|--------|
|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|text/csv|Address.csv|

In this case, this script tries to acccess Google Drive,
open file which has ID=`xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`,
and export it to the file `Address.csv` using `text/csv` format.

## Preparation to run the script - Authentication of Script.

The script is expecting to use OAuth 2.0 for authentication.

1. Please retrieve `credentials.json` from Google and place it on the folder where you run the script.
	1. Easiest way is to reuse project for Drive API Quickstart.
	   Please refer: https://developers.google.com/drive/api/v3/quickstart/ruby
	   and follow the step `ENABLE THE DRIVE API` to retrieve the JSON file.
	1. Othewise, create (or use existing) project which has access to Google Drive API.
1. Execute this script on your working folder.
1. Follow the instruction of this script. Usually it requests you to access specific URI to allow access.
   At final part of the Authentication, you'll get Refresh Token.
   Please paste Refresh Token to the script console.
   The Token is stored as `token.yaml` in the execution folder.

After you run this script once, authentication is stored in the file `token.yaml`
and you will not be required to perform authentication any more.

## Note about ExportGS.rb

This scripts request you to provide read-only file access to your google drive.
Please be careful.
