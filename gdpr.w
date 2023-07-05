bring cloud;

// WIP
// Nearly all of this is a stub

let api = new cloud.Api();
let counter = new cloud.Counter();

let docBucket = new cloud.Bucket() as "gdpr_docs";

let docEmailsTable = new cloud.Table(
  name: "doc_emails",
  primaryKey: "id", // corresponds to the id of a document
  columns: {
    "email_data" => cloud.ColumnType.JSON
  }
);

let KEY_ORIGINAL = "origin/";
let KEY_MODIFIED = "modified/";

let getOriginalKey = inflight (key: str): str => {
  return "${KEY_ORIGINAL}${key}.txt";
};

let getModifiedKey = inflight (key: str): str => {
  return "${KEY_MODIFIED}${key}.txt";
};

inflight class FileParseService {
  extern "./lib.js" static inflight extractEmails(file: str): void;
} 

/**
  Allow users to upload files, which are put into an S3 bucket
*/
api.post("/doc/{id}", inflight (request: cloud.ApiRequest): cloud.ApiResponse => {
  if let body = request.body {
    let docId = request.vars.get("id");
    docBucket.put(getOriginalKey(docId), body);
    return cloud.ApiResponse {
      status: 201,
      body: docId
    };
  }
  else {
    return cloud.ApiResponse {
      status: 500,
      body: "A request body is required"
    };
  }
});

/**
  When a file is stored in the bucket..
  - if the file contains emails:
    - store the emails in a table
    - replace the emails inline with {email-id}@gdpr where 'email-id' is the id of the email in the table
    - store the modified document under /modified/{id}.txt
    - delete the original document at /origin/{id}.txt
  - else:
    - do nothing
*/
docBucket.onCreate(inflight (key: str, type: cloud.BucketEventType): void => {
  if !key.startsWith(KEY_ORIGINAL) {
    log("Early return because key is not prefixed with '${KEY_ORIGINAL}'");
    return;
  }

  let fileStr = docBucket.get(key);
  // TODO: utilize js extern 
});

api.get("/doc/{id}", inflight (request: cloud.ApiRequest): cloud.ApiResponse => {
  // TODO: 
  // - lookup document: check for /modified version first, and if not exists, return /origin
  // - if modified, restore emails 
  // - return doc
  return cloud.ApiResponse {
    status: 200,
    body: Json.stringify({})
  };
});
