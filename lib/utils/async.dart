enum ResponseStatus {
  success,
  failed, //known exception i.e SocketIo
  unkown, //exception
  error //custom error
}

class AsyncResponse<T> {
  final ResponseStatus state;
  final T object;
  AsyncResponse(this.state, this.object);
}
