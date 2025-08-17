package com.zybooks.inventoryapp.data;

import androidx.lifecycle.LiveData;
import androidx.room.Dao;
import androidx.room.Delete;
import androidx.room.Insert;
import androidx.room.Query;
import androidx.room.Transaction;
import androidx.room.Update;

import java.util.List;

@Dao
public interface ItemDao {

    @Insert
    void insert(Item item);

    @Transaction
    @Query("SELECT items. *, categories.name AS categoryName FROM items INNER JOIN categories ON items.categoryId = categories.id")
    LiveData<List<ItemWithCategory>> getAllItemsWithCategories();

    @Delete
    void delete(Item item);

    @Query("DELETE FROM items WHERE categoryId = :categoryId")
    void deleteItemsByCategory(int categoryId);

    @Query("SELECT * FROM items WHERE name = :name LIMIT 1")
    Item findByName(String name);

    @Query("SELECT * FROM items")
    LiveData<List<Item>> getAllItems();

    @Update
    void update(Item item);

}
