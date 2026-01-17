import 'package:floor/floor.dart';

import '../../models/chats.dart';

@dao
abstract class ChatsDao {
  @Query('SELECT * FROM Chats WHERE ownerId = :ownerId')
  Future<List<Chats>?> getAllChats(String ownerId);

  @Query('SELECT * FROM Chats WHERE id = :id')
  Future<Chats?> getChatById(int id);

  // @Query('SELECT * FROM Chats WHERE id = :id')
  // Stream<Chats> getChatByIdStream(int id);
  @Query(
      'SELECT * FROM Chats WHERE (ownerId = :ownerId and toId = :toId) or (ownerId = :toId and toId = :ownerId)')
  Future<List<Chats>?> getChatByOwnerIdAndToId(String ownerId, String toId);

  @Query('''
    SELECT * FROM Chats 
    WHERE ownerId = :ownerId 
    AND chatType = 1001
    AND name LIKE '%' || :keyword || '%'
  ''')
  Future<List<Chats>> searchGroupChats(String ownerId, String keyword);

  @insert
  Future<void> insertChat(Chats chat);

  @update
  Future<void> updateChat(Chats chat);

  @Query('DELETE FROM chats WHERE id = :id')
  Future<void> deleteChat(String id);

  @Query(
      'SELECT * FROM Chats WHERE ownerId =:ownerId ORDER BY messageTime DESC LIMIT 1')
  Future<Chats?> getLastChat(String ownerId);
}
