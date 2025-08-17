package com.zybooks.inventoryapp.data;

import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.Query;
import androidx.room.Update;

@Dao
public interface UsersDao {
    @Insert
    void insert(Users user);

    @Query("SELECT * FROM users WHERE username = :username AND password = :password")
    Users getUser(String username, String password);

    @Query("SELECT * FROM users WHERE username = :username LIMIT 1")
    Users getUserByUsername(String username);

    @Update
    void update(Users user);

    @Query("DELETE FROM users WHERE username = :username")
    void deleteUserByUsername(String username);
}
