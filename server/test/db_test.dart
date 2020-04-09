import 'dart:async';
import 'package:test/test.dart';
import 'package:server/server.dart';

void main() {
  DbContext db;

  setUpAll(() async {
    db = new DbContext(new PostgresDriver('localhost', 'postgres', 'postgres', 'postgres'));
  });

  test('select 1 test', () async {
    Future<String> query() => db.run((db) async {
      var data = await db.sql('select 1 as test', {});
      print('connectionId: ${db.connection.id}, data: $data');
      return db.connection.id;
    });

    try {
      await db.sql('select 1 as test', {});
      expect(true, false); //we never get here, as we are not inside db.run
    } catch(_) {
      expect(true, true);
    }
    var c1 = await query();
    var c2 = await query();
    expect(c1, isNot(c2));
    await db.run((db) async {
      var c3 = await query();
      var c4 = await query();
      expect(c3, c4);
      expect(c3, isNot(c1));
      expect(c3, isNot(c2));
    });
  });

  test('isolation test', () async {
    await db.run((db) async {
      await db.sql('drop table if exists test', {});
      await db.sql('create table test(i int, t text)', {});
      await db.sql('insert into test values (1, \'foo\')', {});
      print('First insert'); //insert one row, commit transaction
    });

    db.run((db) async { //note -- no await here. We don't wait this batch to complete
      await db.sql('insert into test values (2, \'bar\')', {});
      print('Second insert'); //insert one more row
      await new Future.delayed(new Duration(seconds: 5), () async {
        print('Delayed query finished');
      });
    });

    await new Future.delayed(new Duration(seconds: 1)); //wait for row to be inserted

    await db.run((db) async {
      print('Select: '); //here, only one row. Try to add transaction: false to second db.run
      var data = await db.sql('select * from test', {});
      print(data);
      expect(data, {'i': [1], 't': ['foo']});
    });

    await new Future.delayed(new Duration(seconds: 6));
  });

}