bring cloud;

let api = new cloud.Api();
let docBucket = new cloud.Bucket() as "gdpr_docs";
let emailIdGenerator = new cloud.Counter();

let emailsTable = new cloud.Table(
  name: "email",
  primaryKey: "id", 
  columns: {
    "emailId" => cloud.ColumnType.NUMBER,
    "email" => cloud.ColumnType.STRING 
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

let getModifiedKeyFromOriginalKey = inflight (key: str): str => {
  let rawKey = key.split("/").at(1).split(".").at(0);
  return getModifiedKey(rawKey);
};

let getEmailDataByEmailKey = inflight (email: str): str => {
  return "by_email:${email}";
};

let getEmailDataByIdKey = inflight (emailId: num): str => {
  return "by_id:${emailId}";
};


inflight class FileParseService {
  extern "./js/lib.js" static inflight extractEmails(file: str): Array<str>;
  extern "./js/lib.js" static inflight extractGdprIds(file: str): Array<num>;
  extern "./js/lib.js" static inflight generateCompliantDoc(file: str, emailToIdMap: Map<num>): str;
  extern "./js/lib.js" static inflight generateOriginalDoc(file: str, idToEmailMap: Map<str>): str;
} 

test "FileParseService -> extractEmails" {
  let result = FileParseService.extractEmails("This is a string with an email: gard.jordin@gmail.com. It actually has two: abc@def.org.");
  let expected = ["gard.jordin@gmail.com","abc@def.org"];
  assert(result.at(0) == expected.at(0));
  assert(result.at(1) == expected.at(1));
}

test "FileParseService -> extractGdprIds" {
  let result = FileParseService.extractGdprIds("This is a string with an id: 1@gdpr. It actually has two: 2@gdpr.");
  let expected = [1, 2];
  assert(result.at(0) == expected.at(0));
  assert(result.at(1) == expected.at(1));
}

test "FileParseService -> generateCompliantDoc" {
  let result = FileParseService.generateCompliantDoc(
    "This is a string with an email: gard.jordin@gmail.com. It actually has two: abc@def.org.", 
    Map<num>{
      "gard.jordin@gmail.com" => 1,
      "abc@def.org" => 2
    }
  );

  assert(result == "This is a string with an email: 1@gdpr. It actually has two: 2@gdpr.");
}

test "FileParseService -> generateOriginalDoc" {
  log("generating original doc in a sec");
  let result = FileParseService.generateOriginalDoc(
    "This is a string with an email: 1@gdpr. It actually has two: 2@gdpr.", 
    Map<str>{
      "1" => "gard.jordin@gmail.com",
      "2" => "abc@def.org"
    }
  );

  assert(result == "This is a string with an email: gard.jordin@gmail.com. It actually has two: abc@def.org.");
}

/**
  Given an email address:
  - checks to see if it's already stored in the emails table
    - if so, returns its id 
    - if not, generates an id, stores it in the emails table, and returns its id
*/
let ensureEmailId = inflight (email: str): num => {
  let maybeEmailId = emailsTable.get(getEmailDataByEmailKey(email)).tryGet("emailId")?.tryAsNum();
  if let emailId = maybeEmailId {
    return emailId;
  }

  let emailId = emailIdGenerator.inc();
  emailsTable.insert(getEmailDataByEmailKey(email), Json { email: email, emailId: emailId });
  emailsTable.insert(getEmailDataByIdKey(emailId), Json { email: email, emailId: emailId });
  return emailId;
};

test "ensureEmailId: generates novel ids for novel emails" {
  let emailId1 = ensureEmailId("gard.jordin@gmail.com");
  let emailId2 = ensureEmailId("abc@def.com");
  let emailId3 = ensureEmailId("123@pbs.org");
  assert(emailId1 != emailId2);
  assert(emailId2 != emailId3);
  assert(emailId1 != emailId2);
}

test "ensureEmailId: returns existing ids for existing emails" {
  let emailId1 = ensureEmailId("gard.jordin@gmail.com");
  let emailId2 = ensureEmailId("gard.jordin@gmail.com");
  let emailId3 = ensureEmailId("gard.jordin@gmail.com");
  assert(emailId1 == emailId2);
  assert(emailId2 == emailId3);
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
    log("Ending because key is not an original");
    return;
  }

  let fileStr = docBucket.get(key);
  let emails = FileParseService.extractEmails(fileStr);
  if emails.length == 0 {
    log("Ending because no emails were found");
    return;
  }

  let emailIdMap = MutMap<num>{};
  for e in emails {
    emailIdMap.set(e, ensureEmailId(e));
  }

  let compliantFileStr = FileParseService.generateCompliantDoc(fileStr, emailIdMap.copy());
  let modifiedKey = getModifiedKeyFromOriginalKey(key);

  docBucket.put(modifiedKey, compliantFileStr);
  log("Successfully uploaded GDPR-compliant file to ${modifiedKey}");

  docBucket.delete(key);
  log("Successfully deleted non-compliant file from ${key}");
});

api.get("/doc/{id}", inflight (request: cloud.ApiRequest): cloud.ApiResponse => {
  let id = request.vars.get("id");

  let keyModified = getModifiedKey(id);

  let maybeDocModified = docBucket.tryGet(keyModified);
  if !maybeDocModified? {
    let keyOriginal = getOriginalKey(id);
    let docOriginal = docBucket.tryGet(keyOriginal);
    if !docOriginal? {
      return cloud.ApiResponse {
        status: 404,
        body: "Doc not found"
      };
    }
    return cloud.ApiResponse {
      status: 200,
      body: docOriginal
    };
  }

  if let docModified = maybeDocModified {
    let ids = FileParseService.extractGdprIds(docModified);

    let idToEmailMap = MutMap<str>{};
    for i in ids {
      let maybeEmail = emailsTable.get(getEmailDataByIdKey(i)).tryGet("email")?.tryAsStr();
      if let email = maybeEmail {
        idToEmailMap.set("${i}", email);
      }
    }

    return cloud.ApiResponse {
      status: 200,
      body: FileParseService.generateOriginalDoc(docModified, idToEmailMap.copy())
    };
  }
});
