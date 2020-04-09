part of server;

class PostgresDriver extends DbDriver {

  pgpool.Pool pool;
  Map<String, pg.Connection> connections = {};

  PostgresDriver(String server, String db, String login, String password) {
    pool = new pgpool.Pool('postgres://${Uri.encodeComponent(login)}:${Uri.encodeComponent(password)}@${Uri.encodeComponent(server)}:5432/${Uri.encodeComponent(db)}',
        minConnections: 2, maxConnections: 100);
  }

  @override
  Future commitTranImpl(String id) async {
    if (!connections.containsKey(id))
      throw 'Connection "$id" not found';
    await connections[id].execute('commit transaction');
  }

  @override
  Future connectImpl(String id) async {
    if (pool.state != pgpool.PoolState.running)
      await pool.start();
    if (connections.containsKey(id))
      return;
    connections[id] = await pool.connect(debugName: id);
  }

  @override
  Future disconnectImpl(String id) async {
    if (!connections.containsKey(id))
      throw 'Connection "$id" not found';
    await connections[id].close();
  }

  @override
  Future openTranImpl(String id) async {
    if (!connections.containsKey(id))
      throw 'Connection "$id" not found';
    await connections[id].execute('begin transaction');
  }

  @override
  Future rollbackTranImpl(String id) async {
    if (!connections.containsKey(id))
      throw 'Connection "$id" not found';
    await connections[id].execute('rollback transaction');
  }

  @override
  Future<Map<String, List>> sql(String id, String sql, Map params) async {
    if (!connections.containsKey(id))
      throw 'Connection "$id" not found';
    var data = await connections[id].query(sql, params).toList();

    var results = new Map<String, List>();
    for(var row in data) {
      for (var col in row.getColumns()) {
        var lst = results[col.name];
        if (lst == null)
          results[col.name] = lst = [];
        lst.add(row[col.index]);
      }
    }
    return results;
  }
}