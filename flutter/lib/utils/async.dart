/// ResponseStatus for [AsyncResponse]
enum ResponseStatus {
  success,
  failed, //known exception i.e SocketIo
  unkown, //exception
  error, //custom error
  processing, //in between
  idle // idle or not ready
}

/// Repsents any async response
/// Object can be set as null if you don't want pass anything
class AsyncResponse<T> {
  final ResponseStatus state;
  final T object;
  AsyncResponse(this.state, this.object);
}
