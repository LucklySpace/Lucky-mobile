import 'package:floor/floor.dart';

import '../../models/friend.dart';

@dao
abstract class FriendDao {
  @Query('SELECT * FROM Friend WHERE userId=:userId AND friendId =:friendId')
  Future<Friend?> getFriendById(String userId, String friendId);

  @Query('SELECT * FROM Friend WHERE userId=:userId')
  Future<List<Friend>?> list(String userId);

  @Insert(onConflict: OnConflictStrategy.fail)
  Future<void> insertFriend(Friend friend);

  @update
  Future<void> updateFriend(Friend friend);

  @Query('DELETE FROM Friend WHERE userId =:userId AND friendId =:friendId')
  Future<void> deleteFriend(String userId, String friendId);

  @Query('''
    SELECT * FROM Friend 
    WHERE userId = :userId 
    AND (name LIKE '%' || :keyword || '%' OR friendId LIKE '%' || :keyword || '%')
  ''')
  Future<List<Friend>> searchFriends(String userId, String keyword);

  @Query('SELECT IFNULL(MAX(sequence), 0) FROM Friend WHERE userId = :userId')
  Future<int?> getMaxSequence(String userId);

  Future<void> insertOrUpdate(Friend friend) async {
    await insertFriend(friend);
  }
}
