part of api;

typedef BaseClient HttpClientResolver();

HttpClientResolver getClient = () => throw 'Unable to resolve HTTP client';

class HttpClient extends BaseClient {

  BaseClient _inner;
  BaseClient get inner => _inner ?? getClient();

  Future<StreamedResponse> send(BaseRequest request) async {
    var response = await inner.send(request);
    return response;
  }
}