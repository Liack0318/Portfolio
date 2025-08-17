package com.zybooks.inventoryapp.viewmodel;

import android.app.Application;

import androidx.lifecycle.AndroidViewModel;
import androidx.lifecycle.LiveData;

import com.zybooks.inventoryapp.data.Category;
import com.zybooks.inventoryapp.repository.CategoryRepository;

import java.util.List;

public class CategoryViewModel extends AndroidViewModel {
    private CategoryRepository repository;

    public CategoryViewModel(Application application) {
        super(application);
        repository = new CategoryRepository(application);
    }

    public void insert(Category category) {
        repository.insert(category);
    }

    public void update(Category category) {
        repository.update(category);
    }

    public void delete(Category category) {
        repository.delete(category);
    }

    public LiveData<List<Category>> getAllCategories() {
        return repository.getAllCategories();
    }
}
