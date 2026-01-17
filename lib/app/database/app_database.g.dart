// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  ChatsDao? _chatsDaoInstance;

  FriendDao? _friendDaoInstance;

  SingleMessageDao? _singleMessageDaoInstance;

  GroupMessageDao? _groupMessageDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `chats` (`chatId` TEXT NOT NULL, `id` TEXT NOT NULL, `chatType` INTEGER NOT NULL, `ownerId` TEXT NOT NULL, `toId` TEXT NOT NULL, `isMute` INTEGER NOT NULL, `isTop` INTEGER NOT NULL, `sequence` INTEGER NOT NULL, `name` TEXT NOT NULL, `avatar` TEXT NOT NULL, `unread` INTEGER NOT NULL, `message` TEXT, `messageTime` INTEGER NOT NULL, `draft` TEXT, PRIMARY KEY (`chatId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `friend` (`userId` TEXT, `friendId` TEXT, `name` TEXT, `alias` TEXT, `avatar` TEXT, `gender` INTEGER, `location` TEXT, `black` INTEGER, `flag` INTEGER, `birthday` TEXT, `selfSignature` TEXT, `sequence` INTEGER, PRIMARY KEY (`userId`, `friendId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `group_message` (`messageId` TEXT NOT NULL, `fromId` TEXT NOT NULL, `ownerId` TEXT NOT NULL, `groupId` TEXT NOT NULL, `messageBody` TEXT NOT NULL, `messageContentType` INTEGER NOT NULL, `messageTime` INTEGER NOT NULL, `messageType` INTEGER NOT NULL, `readStatus` INTEGER NOT NULL, `sequence` INTEGER NOT NULL, `extra` TEXT, PRIMARY KEY (`messageId`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `single_message` (`messageId` TEXT NOT NULL, `fromId` TEXT NOT NULL, `toId` TEXT NOT NULL, `ownerId` TEXT NOT NULL, `messageBody` TEXT NOT NULL, `messageContentType` INTEGER NOT NULL, `messageTime` INTEGER NOT NULL, `messageType` INTEGER NOT NULL, `readStatus` INTEGER NOT NULL, `sequence` INTEGER NOT NULL, `extra` TEXT, PRIMARY KEY (`messageId`))');
        await database.execute(
            'CREATE INDEX `index_chats_chatId_name` ON `chats` (`chatId`, `name`)');
        await database.execute(
            'CREATE INDEX `index_friend_userId_friendId_name` ON `friend` (`userId`, `friendId`, `name`)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  ChatsDao get chatsDao {
    return _chatsDaoInstance ??= _$ChatsDao(database, changeListener);
  }

  @override
  FriendDao get friendDao {
    return _friendDaoInstance ??= _$FriendDao(database, changeListener);
  }

  @override
  SingleMessageDao get singleMessageDao {
    return _singleMessageDaoInstance ??=
        _$SingleMessageDao(database, changeListener);
  }

  @override
  GroupMessageDao get groupMessageDao {
    return _groupMessageDaoInstance ??=
        _$GroupMessageDao(database, changeListener);
  }
}

class _$ChatsDao extends ChatsDao {
  _$ChatsDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _chatsInsertionAdapter = InsertionAdapter(
            database,
            'chats',
            (Chats item) => <String, Object?>{
                  'chatId': item.chatId,
                  'id': item.id,
                  'chatType': item.chatType,
                  'ownerId': item.ownerId,
                  'toId': item.toId,
                  'isMute': item.isMute,
                  'isTop': item.isTop,
                  'sequence': item.sequence,
                  'name': item.name,
                  'avatar': item.avatar,
                  'unread': item.unread,
                  'message': item.message,
                  'messageTime': item.messageTime,
                  'draft': item.draft
                }),
        _chatsUpdateAdapter = UpdateAdapter(
            database,
            'chats',
            ['chatId'],
            (Chats item) => <String, Object?>{
                  'chatId': item.chatId,
                  'id': item.id,
                  'chatType': item.chatType,
                  'ownerId': item.ownerId,
                  'toId': item.toId,
                  'isMute': item.isMute,
                  'isTop': item.isTop,
                  'sequence': item.sequence,
                  'name': item.name,
                  'avatar': item.avatar,
                  'unread': item.unread,
                  'message': item.message,
                  'messageTime': item.messageTime,
                  'draft': item.draft
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Chats> _chatsInsertionAdapter;

  final UpdateAdapter<Chats> _chatsUpdateAdapter;

  @override
  Future<List<Chats>?> getAllChats(String ownerId) async {
    return _queryAdapter.queryList('SELECT * FROM Chats WHERE ownerId = ?1',
        mapper: (Map<String, Object?> row) => Chats(
            id: row['id'] as String,
            chatId: row['chatId'] as String,
            chatType: row['chatType'] as int,
            ownerId: row['ownerId'] as String,
            toId: row['toId'] as String,
            isMute: row['isMute'] as int,
            isTop: row['isTop'] as int,
            sequence: row['sequence'] as int,
            name: row['name'] as String,
            avatar: row['avatar'] as String,
            unread: row['unread'] as int,
            message: row['message'] as String?,
            messageTime: row['messageTime'] as int,
            draft: row['draft'] as String?),
        arguments: [ownerId]);
  }

  @override
  Future<Chats?> getChatById(int id) async {
    return _queryAdapter.query('SELECT * FROM Chats WHERE id = ?1',
        mapper: (Map<String, Object?> row) => Chats(
            id: row['id'] as String,
            chatId: row['chatId'] as String,
            chatType: row['chatType'] as int,
            ownerId: row['ownerId'] as String,
            toId: row['toId'] as String,
            isMute: row['isMute'] as int,
            isTop: row['isTop'] as int,
            sequence: row['sequence'] as int,
            name: row['name'] as String,
            avatar: row['avatar'] as String,
            unread: row['unread'] as int,
            message: row['message'] as String?,
            messageTime: row['messageTime'] as int,
            draft: row['draft'] as String?),
        arguments: [id]);
  }

  @override
  Future<List<Chats>?> getChatByOwnerIdAndToId(
    String ownerId,
    String toId,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Chats WHERE (ownerId = ?1 and toId = ?2) or (ownerId = ?2 and toId = ?1)',
        mapper: (Map<String, Object?> row) => Chats(id: row['id'] as String, chatId: row['chatId'] as String, chatType: row['chatType'] as int, ownerId: row['ownerId'] as String, toId: row['toId'] as String, isMute: row['isMute'] as int, isTop: row['isTop'] as int, sequence: row['sequence'] as int, name: row['name'] as String, avatar: row['avatar'] as String, unread: row['unread'] as int, message: row['message'] as String?, messageTime: row['messageTime'] as int, draft: row['draft'] as String?),
        arguments: [ownerId, toId]);
  }

  @override
  Future<List<Chats>> searchGroupChats(
    String ownerId,
    String keyword,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Chats      WHERE ownerId = ?1      AND chatType = 1001     AND name LIKE \'%\' || ?2 || \'%\'',
        mapper: (Map<String, Object?> row) => Chats(id: row['id'] as String, chatId: row['chatId'] as String, chatType: row['chatType'] as int, ownerId: row['ownerId'] as String, toId: row['toId'] as String, isMute: row['isMute'] as int, isTop: row['isTop'] as int, sequence: row['sequence'] as int, name: row['name'] as String, avatar: row['avatar'] as String, unread: row['unread'] as int, message: row['message'] as String?, messageTime: row['messageTime'] as int, draft: row['draft'] as String?),
        arguments: [ownerId, keyword]);
  }

  @override
  Future<void> deleteChat(String id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM chats WHERE id = ?1', arguments: [id]);
  }

  @override
  Future<Chats?> getLastChat(String ownerId) async {
    return _queryAdapter.query(
        'SELECT * FROM Chats WHERE ownerId =?1 ORDER BY messageTime DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => Chats(id: row['id'] as String, chatId: row['chatId'] as String, chatType: row['chatType'] as int, ownerId: row['ownerId'] as String, toId: row['toId'] as String, isMute: row['isMute'] as int, isTop: row['isTop'] as int, sequence: row['sequence'] as int, name: row['name'] as String, avatar: row['avatar'] as String, unread: row['unread'] as int, message: row['message'] as String?, messageTime: row['messageTime'] as int, draft: row['draft'] as String?),
        arguments: [ownerId]);
  }

  @override
  Future<void> insertChat(Chats chat) async {
    await _chatsInsertionAdapter.insert(chat, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateChat(Chats chat) async {
    await _chatsUpdateAdapter.update(chat, OnConflictStrategy.abort);
  }
}

class _$FriendDao extends FriendDao {
  _$FriendDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _friendInsertionAdapter = InsertionAdapter(
            database,
            'friend',
            (Friend item) => <String, Object?>{
                  'userId': item.userId,
                  'friendId': item.friendId,
                  'name': item.name,
                  'alias': item.alias,
                  'avatar': item.avatar,
                  'gender': item.gender,
                  'location': item.location,
                  'black': item.black,
                  'flag': item.flag,
                  'birthday': item.birthday,
                  'selfSignature': item.selfSignature,
                  'sequence': item.sequence
                }),
        _friendUpdateAdapter = UpdateAdapter(
            database,
            'friend',
            ['userId', 'friendId'],
            (Friend item) => <String, Object?>{
                  'userId': item.userId,
                  'friendId': item.friendId,
                  'name': item.name,
                  'alias': item.alias,
                  'avatar': item.avatar,
                  'gender': item.gender,
                  'location': item.location,
                  'black': item.black,
                  'flag': item.flag,
                  'birthday': item.birthday,
                  'selfSignature': item.selfSignature,
                  'sequence': item.sequence
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Friend> _friendInsertionAdapter;

  final UpdateAdapter<Friend> _friendUpdateAdapter;

  @override
  Future<Friend?> getFriendById(
    String userId,
    String friendId,
  ) async {
    return _queryAdapter.query(
        'SELECT * FROM Friend WHERE userId=?1 AND friendId =?2',
        mapper: (Map<String, Object?> row) => Friend(
            userId: row['userId'] as String,
            friendId: row['friendId'] as String,
            name: row['name'] as String,
            alias: row['alias'] as String?,
            avatar: row['avatar'] as String?,
            gender: row['gender'] as int?,
            location: row['location'] as String?,
            black: row['black'] as int?,
            flag: row['flag'] as int?,
            birthday: row['birthday'] as String?,
            selfSignature: row['selfSignature'] as String?,
            sequence: row['sequence'] as int?),
        arguments: [userId, friendId]);
  }

  @override
  Future<List<Friend>?> list(String userId) async {
    return _queryAdapter.queryList('SELECT * FROM Friend WHERE userId=?1',
        mapper: (Map<String, Object?> row) => Friend(
            userId: row['userId'] as String,
            friendId: row['friendId'] as String,
            name: row['name'] as String,
            alias: row['alias'] as String?,
            avatar: row['avatar'] as String?,
            gender: row['gender'] as int?,
            location: row['location'] as String?,
            black: row['black'] as int?,
            flag: row['flag'] as int?,
            birthday: row['birthday'] as String?,
            selfSignature: row['selfSignature'] as String?,
            sequence: row['sequence'] as int?),
        arguments: [userId]);
  }

  @override
  Future<void> deleteFriend(
    String userId,
    String friendId,
  ) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM Friend WHERE userId =?1 AND friendId =?2',
        arguments: [userId, friendId]);
  }

  @override
  Future<List<Friend>> searchFriends(
    String userId,
    String keyword,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Friend      WHERE userId = ?1      AND (name LIKE \'%\' || ?2 || \'%\' OR friendId LIKE \'%\' || ?2 || \'%\')',
        mapper: (Map<String, Object?> row) => Friend(userId: row['userId'] as String, friendId: row['friendId'] as String, name: row['name'] as String, alias: row['alias'] as String?, avatar: row['avatar'] as String?, gender: row['gender'] as int?, location: row['location'] as String?, black: row['black'] as int?, flag: row['flag'] as int?, birthday: row['birthday'] as String?, selfSignature: row['selfSignature'] as String?, sequence: row['sequence'] as int?),
        arguments: [userId, keyword]);
  }

  @override
  Future<int?> getMaxSequence(String userId) async {
    return _queryAdapter.query(
        'SELECT IFNULL(MAX(sequence), 0) FROM Friend WHERE userId = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [userId]);
  }

  @override
  Future<void> insertFriend(Friend friend) async {
    await _friendInsertionAdapter.insert(friend, OnConflictStrategy.fail);
  }

  @override
  Future<void> updateFriend(Friend friend) async {
    await _friendUpdateAdapter.update(friend, OnConflictStrategy.abort);
  }
}

class _$SingleMessageDao extends SingleMessageDao {
  _$SingleMessageDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _singleMessageInsertionAdapter = InsertionAdapter(
            database,
            'single_message',
            (SingleMessage item) => <String, Object?>{
                  'messageId': item.messageId,
                  'fromId': item.fromId,
                  'toId': item.toId,
                  'ownerId': item.ownerId,
                  'messageBody': item.messageBody,
                  'messageContentType': item.messageContentType,
                  'messageTime': item.messageTime,
                  'messageType': item.messageType,
                  'readStatus': item.readStatus,
                  'sequence': item.sequence,
                  'extra': item.extra
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<SingleMessage> _singleMessageInsertionAdapter;

  @override
  Future<List<SingleMessage>?> getAllMessages(
    String fromId,
    String toId,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM single_message WHERE ( (fromId = ?1 AND toId = ?2 ) OR ( fromId = ?2 AND toId = ?1 ))',
        mapper: (Map<String, Object?> row) => SingleMessage(messageId: row['messageId'] as String, fromId: row['fromId'] as String, toId: row['toId'] as String, ownerId: row['ownerId'] as String, messageBody: row['messageBody'] as String, messageContentType: row['messageContentType'] as int, messageTime: row['messageTime'] as int, messageType: row['messageType'] as int, readStatus: row['readStatus'] as int, sequence: row['sequence'] as int, extra: row['extra'] as String?),
        arguments: [fromId, toId]);
  }

  @override
  Future<List<SingleMessage>?> getMessagesByPage(
    String fromId,
    String toId,
    int limit,
    int offset,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM single_message      WHERE ((fromId = ?1 AND toId = ?2) OR (fromId = ?2 AND toId = ?1))     ORDER BY messageTime DESC      LIMIT ?3 OFFSET ?4',
        mapper: (Map<String, Object?> row) => SingleMessage(messageId: row['messageId'] as String, fromId: row['fromId'] as String, toId: row['toId'] as String, ownerId: row['ownerId'] as String, messageBody: row['messageBody'] as String, messageContentType: row['messageContentType'] as int, messageTime: row['messageTime'] as int, messageType: row['messageType'] as int, readStatus: row['readStatus'] as int, sequence: row['sequence'] as int, extra: row['extra'] as String?),
        arguments: [fromId, toId, limit, offset]);
  }

  @override
  Future<SingleMessage?> getLastMessage(String ownerId) async {
    return _queryAdapter.query(
        'SELECT * FROM single_message      WHERE ownerId = ?1     ORDER BY messageTime DESC      LIMIT 1',
        mapper: (Map<String, Object?> row) => SingleMessage(messageId: row['messageId'] as String, fromId: row['fromId'] as String, toId: row['toId'] as String, ownerId: row['ownerId'] as String, messageBody: row['messageBody'] as String, messageContentType: row['messageContentType'] as int, messageTime: row['messageTime'] as int, messageType: row['messageType'] as int, readStatus: row['readStatus'] as int, sequence: row['sequence'] as int, extra: row['extra'] as String?),
        arguments: [ownerId]);
  }

  @override
  Future<List<SingleMessage>> searchMessages(
    String keyword,
    String userId,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM single_message      WHERE messageBody LIKE \'%\' || ?1 || \'%\'     AND ((fromId = ?2) OR (toId = ?2))     ORDER BY messageTime DESC',
        mapper: (Map<String, Object?> row) => SingleMessage(messageId: row['messageId'] as String, fromId: row['fromId'] as String, toId: row['toId'] as String, ownerId: row['ownerId'] as String, messageBody: row['messageBody'] as String, messageContentType: row['messageContentType'] as int, messageTime: row['messageTime'] as int, messageType: row['messageType'] as int, readStatus: row['readStatus'] as int, sequence: row['sequence'] as int, extra: row['extra'] as String?),
        arguments: [keyword, userId]);
  }

  @override
  Future<void> insertMessage(SingleMessage message) async {
    await _singleMessageInsertionAdapter.insert(
        message, OnConflictStrategy.abort);
  }
}

class _$GroupMessageDao extends GroupMessageDao {
  _$GroupMessageDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _groupMessageInsertionAdapter = InsertionAdapter(
            database,
            'group_message',
            (GroupMessage item) => <String, Object?>{
                  'messageId': item.messageId,
                  'fromId': item.fromId,
                  'ownerId': item.ownerId,
                  'groupId': item.groupId,
                  'messageBody': item.messageBody,
                  'messageContentType': item.messageContentType,
                  'messageTime': item.messageTime,
                  'messageType': item.messageType,
                  'readStatus': item.readStatus,
                  'sequence': item.sequence,
                  'extra': item.extra
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<GroupMessage> _groupMessageInsertionAdapter;

  @override
  Future<List<GroupMessage>?> getAllMessages(String ownerId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM group_message WHERE ownerId = ?1',
        mapper: (Map<String, Object?> row) => GroupMessage(
            messageId: row['messageId'] as String,
            fromId: row['fromId'] as String,
            ownerId: row['ownerId'] as String,
            groupId: row['groupId'] as String,
            messageBody: row['messageBody'] as String,
            messageContentType: row['messageContentType'] as int,
            messageTime: row['messageTime'] as int,
            messageType: row['messageType'] as int,
            readStatus: row['readStatus'] as int,
            sequence: row['sequence'] as int,
            extra: row['extra'] as String?),
        arguments: [ownerId]);
  }

  @override
  Future<List<GroupMessage>?> getMessagesByPage(
    String ownerId,
    int limit,
    int offset,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM group_message      WHERE ownerId = ?1     ORDER BY messageTime DESC      LIMIT ?2 OFFSET ?3',
        mapper: (Map<String, Object?> row) => GroupMessage(messageId: row['messageId'] as String, fromId: row['fromId'] as String, ownerId: row['ownerId'] as String, groupId: row['groupId'] as String, messageBody: row['messageBody'] as String, messageContentType: row['messageContentType'] as int, messageTime: row['messageTime'] as int, messageType: row['messageType'] as int, readStatus: row['readStatus'] as int, sequence: row['sequence'] as int, extra: row['extra'] as String?),
        arguments: [ownerId, limit, offset]);
  }

  @override
  Future<GroupMessage?> getLastMessage(String ownerId) async {
    return _queryAdapter.query(
        'SELECT * FROM group_message      WHERE ownerId = ?1     ORDER BY messageTime DESC      LIMIT 1',
        mapper: (Map<String, Object?> row) => GroupMessage(messageId: row['messageId'] as String, fromId: row['fromId'] as String, ownerId: row['ownerId'] as String, groupId: row['groupId'] as String, messageBody: row['messageBody'] as String, messageContentType: row['messageContentType'] as int, messageTime: row['messageTime'] as int, messageType: row['messageType'] as int, readStatus: row['readStatus'] as int, sequence: row['sequence'] as int, extra: row['extra'] as String?),
        arguments: [ownerId]);
  }

  @override
  Future<List<GroupMessage>> searchMessages(
    String keyword,
    String ownerId,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM group_message      WHERE messageBody LIKE \'%\' || ?1 || \'%\'     AND ownerId = ?2     ORDER BY messageTime DESC',
        mapper: (Map<String, Object?> row) => GroupMessage(messageId: row['messageId'] as String, fromId: row['fromId'] as String, ownerId: row['ownerId'] as String, groupId: row['groupId'] as String, messageBody: row['messageBody'] as String, messageContentType: row['messageContentType'] as int, messageTime: row['messageTime'] as int, messageType: row['messageType'] as int, readStatus: row['readStatus'] as int, sequence: row['sequence'] as int, extra: row['extra'] as String?),
        arguments: [keyword, ownerId]);
  }

  @override
  Future<void> insertMessage(GroupMessage message) async {
    await _groupMessageInsertionAdapter.insert(
        message, OnConflictStrategy.abort);
  }
}
