part of server;

typedef dynamic DatabaseAction(DbContext db);

class DbContext {

  DbConnectionInfo connection;
  DbDriver driver;

  DbContext(this.driver, {DbConnectionInfo connection}) {
    this.connection = connection ?? new DbConnectionInfo();
  }

  Future<dynamic> run(DatabaseAction action, {bool transaction: true}) async {
    var connectionInfo = Zone.current[#dbConnection];
    var db = new DbContext(driver, connection: connectionInfo);
    try {
      await driver.connect(db.connection);
      if (transaction)
        await driver.openTran(db.connection);

      var result = await runZoned(() async {
        return await action(db);
      }, zoneValues: {
        #dbConnection: db.connection
      });
      if (transaction)
        await driver.commitTran(db.connection);
      return result;
    } catch (x) {
      if (transaction)
        await driver.rollbackTran(db.connection);
      rethrow;
    } finally {
      await driver.disconnect(db.connection);
    }
  }

  DbRepository<Player> get players => new DbRepository<Player>(this);
  DbRepository<Game> get games => new DbRepository<Game>(this);
  DbRepository<Session> get sessions => new DbRepository<Session>(this);

  Future<Map<String, List<dynamic>>> sql(String sql, Map params) => driver.sql(connection.id, sql, params);
}
