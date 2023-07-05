bring cloud;

// WIP
// Nearly all of this is a stub

let api = new cloud.Api();
let docBucket = new cloud.Bucket() as "gdpr_docs";
let emailIdGenerator = new cloud.Counter();
let emailsTable = new cloud.Table(
  name: "email",
  primaryKey: "id", // corresponds to the id of a document
  columns: {
    "emailId" => cloud.ColumnType.NUMBER
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
  extern "./lib.js" static inflight extractEmails(file: str): Array<str>;
} 

test "FileParseService -> extractEmails" {
  let result = FileParseService.extractEmails("This is a string with an email: gard.jordin@gmail.com. It actually has two: abc@def.org");
  let expected = ["gard.jordin@gmail.com","abc@def.org"];
  assert(result.at(0) == expected.at(0));
  assert(result.at(1) == expected.at(1));
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
    log("Ending because key is not prefixed with '${KEY_ORIGINAL}'");
    return;
  }

  let fileStr = docBucket.get(key);
  let emails = FileParseService.extractEmails(fileStr);
  if emails.length == 0 {
    log("Ended because no emails were found");
    return;
  }

  let emailIdMap = MutMap<num>{};
  for e in emails {
    let emailId = emailIdGenerator.inc();
    emailsTable.insert(e, Json { emailId: emailId });
    emailIdMap.set(e, emailId);
  }

  // TODO: pass emails back to another js extern function to replace within the document
  // TODO: upload the replaced document and delete the original
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
