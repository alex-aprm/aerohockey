part of api;

typedef BaseClient HttpClientResolver();

HttpClientResolver getClient = () => throw 'Unable to resolve HTTP client';

String token;

class HttpClient extends BaseClient {

  BaseClient _inner;
  BaseClient get inner => _inner ?? getClient();

  Future<StreamedResponse> send(BaseRequest request) async {
    request.headers['Authorization'] = token;
    if (request.method == 'POST')
      request.headers['Content-Type'] = 'application/json';
    var response = await inner.send(request);
    return response;
  }

  Future<Response> post(url, {Map<String, String> headers, body, Encoding encoding}) async {
    var response = await super.post(url, headers: headers, body: body, encoding: encoding);
    return _checkError(response);
  }

  Future<Response> delete(url, {Map<String, String> headers}) async {
    var response = await super.delete(url, headers: headers);
    return _checkError(response);
  }

  Future<Response> get(url, {Map<String, String> headers, bool suppressException = false}) async {
    var response = await super.get(url, headers: headers);
    if (suppressException)
      return response;
    return _checkError(response);
  }

  Response _checkError(Response response) {
    if (response.statusCode >= 400)
      throw '[${response.statusCode}] ${response.body}';
    return response;
  }
}