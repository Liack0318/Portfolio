package com.zybooks.inventoryapp.viewmodel;

import android.app.Application;

import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;

import com.zybooks.inventoryapp.data.Item;
import com.zybooks.inventoryapp.data.ItemWithCategory;
import com.zybooks.inventoryapp.repository.ItemRepository;

import java.util.List;

public class ItemViewModel extends AndroidViewModel {
    private ItemRepository repository;
    private LiveData<List<ItemWithCategory>> allItemsWithCategories;

    public ItemViewModel(Application application) {
        super(application);
        repository = new ItemRepository(application);
        allItemsWithCategories = repository.getAllItemsWithCategories();
    }

    public void insert(Item item) {
        repository.insert(item);
    }

    public LiveData<List<ItemWithCategory>> getAllItemsWithCategories() {
        return allItemsWithCategories;
    }

    public Item findByName(String name) {
        return repository.findByName(name);
    }

    public void delete(Item item) {
        repository.delete(item);
    }

    public void deleteItemsByCategory(int categoryId) {
        repository.deleteItemsByCategory(categoryId);
    }

    public void update(Item item) {
        repository.update(item);
    }

}
