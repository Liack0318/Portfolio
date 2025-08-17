package com.zybooks.inventoryapp.repository;

import android.app.Application;

import androidx.lifecycle.LiveData;

import com.zybooks.inventoryapp.data.AppDatabase;
import com.zybooks.inventoryapp.data.Item;
import com.zybooks.inventoryapp.data.ItemDao;
import com.zybooks.inventoryapp.data.ItemWithCategory;

import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class ItemRepository {
    private ItemDao itemDao;
    private LiveData<List<ItemWithCategory>> allItemsWithCategories;
    private ExecutorService executorService;

    public ItemRepository(Application application) {
        AppDatabase db = AppDatabase.getDatabase(application);
        itemDao = db.itemDao();
        allItemsWithCategories = itemDao.getAllItemsWithCategories();
        executorService = Executors.newSingleThreadExecutor();
    }

    public void insert(Item item) {
        executorService.execute(() -> itemDao.insert(item));
    }

    public LiveData<List<ItemWithCategory>> getAllItemsWithCategories() {
        return allItemsWithCategories;
    }

    public Item findByName(String name) {
        return itemDao.findByName(name);
    }

    public void delete(Item item) {
        executorService.execute(() -> itemDao.delete(item));
    }

    public void deleteItemsByCategory(int categoryId) {
        executorService.execute(() -> itemDao.deleteItemsByCategory(categoryId));
    }

    public void update(Item item) {
        executorService.execute(() -> itemDao.update(item));
    }
}

