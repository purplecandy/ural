enum ResponseStatus {
  success,
  failed, //known exception i.e SocketIo
  unkown, //exception
  error, //custom error
  processing, //in between
  idle // idle or not ready
}

enum StreamEvents { update }

class AsyncResponse<T> {
  final ResponseStatus state;
  final T object;
  AsyncResponse(this.state, this.object);
}
