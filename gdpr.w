bring cloud;

// WIP
// Nearly all of this is a stub

let api = new cloud.Api();
let counter = new cloud.Counter();

let docBucket = new cloud.Bucket();

let emailTable = new cloud.Table(
  name: "emails",
  primaryKey: "id",
  columns: {
    "email" => cloud.ColumnType.STRING,
    "doc_id" => cloud.ColumnType.STRING
  }
);

api.post("/doc/{id}", inflight (request: cloud.ApiRequest): cloud.ApiResponse => {
  // TODO: 
  // - get document from request
  // - store the document in docBucket
  // - handle emails (store in table, replace with id, create /modified, delete /origin)
  return cloud.ApiResponse {
    status: 200,
    body: Json.stringify({})
  };
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