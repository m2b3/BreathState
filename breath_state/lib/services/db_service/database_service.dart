import 'package:breath_state/constants/db_constants.dart';
import 'package:breath_state/services/hrv_analysis/hrv_time_domain.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class DatabaseService {
  static Database? _db;
  static final DatabaseService instance = DatabaseService._constructor();
  DatabaseService._constructor();

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await getDatabase();
    return _db!;
  }

  static const String _createHrvTable = '''
    CREATE TABLE IF NOT EXISTS $HRV_TABLE_NAME (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id    TEXT    NOT NULL,
      timestamp     TEXT    NOT NULL,
      mean_nn       REAL,
      sdnn          REAL,
      rmssd         REAL,
      sdsd          REAL,
      cvnn          REAL,
      cvsd          REAL,
      median_nn     REAL,
      mad_nn        REAL,
      mcvnn         REAL,
      iqrnn         REAL,
      sdrmssd       REAL,
      prc20nn       REAL,
      prc80nn       REAL,
      pnn50         REAL,
      pnn20         REAL,
      min_nn        REAL,
      max_nn        REAL,
      hti           REAL,
      tinn          REAL,
      sdann1        REAL,
      sdann2        REAL,
      sdann5        REAL,
      sdnni1        REAL,
      sdnni2        REAL,
      sdnni5        REAL
    )
  ''';

  Future<Database> getDatabase() async {
    var databasePath = await getDatabasesPath();
    String path = join(databasePath, DB_NAME);

    Database database = await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('Create table $BREATH_TABLE_NAME (date TEXT, rate INTEGER)');
        await db.execute('Create table $HEART_TABLE_NAME (date TEXT, rate INTEGER)');
        await db.execute(_createHrvTable);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(_createHrvTable);
        }
      },
    );

    return database;
  }

  Future<void> addData(int rate, String tableName) async {
    Database db = await database;
    final now = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    int status = await db.insert(tableName, {
      "date": formattedDateTime,
      "rate": rate,
    });
    if (status == 0) {
      developer.log("Error inserting");
      throw Error();
    }
  }

  Future<List<Map>> getData(String tableName) async {
    
    Database db = await database;
    List<Map> rows = await db.query(tableName);

    return rows;
  }

  Future<void> insertHrvResult({
    required String sessionId,
    required HrvTimeDomainResult result,
  }) async {
    Database db = await database;
    final now = DateTime.now();
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final map = result.toMap();

    await db.insert(HRV_TABLE_NAME, {
      'session_id': sessionId,
      'timestamp': formattedDateTime,
      'mean_nn': map['HRV_MeanNN'],
      'sdnn': map['HRV_SDNN'],
      'rmssd': map['HRV_RMSSD'],
      'sdsd': map['HRV_SDSD'],
      'cvnn': map['HRV_CVNN'],
      'cvsd': map['HRV_CVSD'],
      'median_nn': map['HRV_MedianNN'],
      'mad_nn': map['HRV_MadNN'],
      'mcvnn': map['HRV_MCVNN'],
      'iqrnn': map['HRV_IQRNN'],
      'sdrmssd': map['HRV_SDRMSSD'],
      'prc20nn': map['HRV_Prc20NN'],
      'prc80nn': map['HRV_Prc80NN'],
      'pnn50': map['HRV_pNN50'],
      'pnn20': map['HRV_pNN20'],
      'min_nn': map['HRV_MinNN'],
      'max_nn': map['HRV_MaxNN'],
      'hti': map['HRV_HTI'],
      'tinn': map['HRV_TINN'],
      'sdann1': map['HRV_SDANN1'],
      'sdann2': map['HRV_SDANN2'],
      'sdann5': map['HRV_SDANN5'],
      'sdnni1': map['HRV_SDNNI1'],
      'sdnni2': map['HRV_SDNNI2'],
      'sdnni5': map['HRV_SDNNI5'],
    });

    developer.log("HRV result inserted for session $sessionId");
  }

  Future<HrvTimeDomainResult?> getHrvResult(String sessionId) async {
    Database db = await database;
    final rows = await db.query(
      HRV_TABLE_NAME,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final r = rows.first;

    return HrvTimeDomainResult(
      meanNN: (r['mean_nn'] as num?)?.toDouble() ?? 0,
      sdnn: (r['sdnn'] as num?)?.toDouble() ?? 0,
      rmssd: (r['rmssd'] as num?)?.toDouble() ?? 0,
      sdsd: (r['sdsd'] as num?)?.toDouble() ?? 0,
      cvnn: (r['cvnn'] as num?)?.toDouble() ?? 0,
      cvsd: (r['cvsd'] as num?)?.toDouble() ?? 0,
      medianNN: (r['median_nn'] as num?)?.toDouble() ?? 0,
      madNN: (r['mad_nn'] as num?)?.toDouble() ?? 0,
      mcvnn: (r['mcvnn'] as num?)?.toDouble() ?? 0,
      iqrnn: (r['iqrnn'] as num?)?.toDouble() ?? 0,
      sdrmssd: (r['sdrmssd'] as num?)?.toDouble() ?? 0,
      prc20nn: (r['prc20nn'] as num?)?.toDouble() ?? 0,
      prc80nn: (r['prc80nn'] as num?)?.toDouble() ?? 0,
      pnn50: (r['pnn50'] as num?)?.toDouble() ?? 0,
      pnn20: (r['pnn20'] as num?)?.toDouble() ?? 0,
      minNN: (r['min_nn'] as num?)?.toDouble() ?? 0,
      maxNN: (r['max_nn'] as num?)?.toDouble() ?? 0,
      hti: (r['hti'] as num?)?.toDouble() ?? 0,
      tinn: (r['tinn'] as num?)?.toDouble() ?? 0,
      sdann1: (r['sdann1'] as num?)?.toDouble(),
      sdann2: (r['sdann2'] as num?)?.toDouble(),
      sdann5: (r['sdann5'] as num?)?.toDouble(),
      sdnni1: (r['sdnni1'] as num?)?.toDouble(),
      sdnni2: (r['sdnni2'] as num?)?.toDouble(),
      sdnni5: (r['sdnni5'] as num?)?.toDouble(),
    );
  }
}
