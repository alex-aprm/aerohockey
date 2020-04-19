part of server;

abstract class DbDriver {
  Future connect(DbConnectionInfo connection) async {
    if (connection.openCount == 0)
      await connectImpl(connection.id);
    connection.openCount++;
  }

  Future disconnect(DbConnectionInfo connection) async {
    connection.openCount--;
    if (connection.openCount == 0)
      await disconnectImpl(connection.id);
  }

  Future openTran(DbConnectionInfo connection) async {
    if (connection.tranCount == 0)
      await openTranImpl(connection.id);
    connection.tranCount++;
  }

  Future commitTran(DbConnectionInfo connection) async {
    connection.tranCount--;
    if (connection.tranCount == 0)
      await commitTranImpl(connection.id);
  }

  Future rollbackTran(DbConnectionInfo connection) async {
    connection.tranCount--;
    if (connection.tranCount == 0)
      await rollbackTranImpl(connection.id);
  }

  Future connectImpl(String id);
  Future disconnectImpl(String id);
  Future openTranImpl(String id);
  Future commitTranImpl(String id);
  Future rollbackTranImpl(String id);
  Future<Map<String, List<dynamic>>> sql(String id, String sql, Map params);

}

class DbConnectionInfo {
  String id;

  bool get connected => openCount > 0;
  bool get transaction => tranCount > 0;

  int openCount = 0;
  int tranCount = 0;

  DbConnectionInfo() {
    id = new Uuid().v1();
  }
}
