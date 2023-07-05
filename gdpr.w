bring cloud;

let api = new cloud.Api();

inflight class RequestController {
  static inflight handleRequest(request: cloud.ApiRequest): cloud.ApiResponse {
    return cloud.ApiResponse {
      status: 200,
      body: "Hello, world!"
    };
  }
}

api.get("/", RequestController.handleRequest);