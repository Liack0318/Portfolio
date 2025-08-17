package com.zybooks.inventoryapp.repository;

import android.app.Application;

import androidx.lifecycle.LiveData;

import com.zybooks.inventoryapp.data.AppDatabase;
import com.zybooks.inventoryapp.data.Category;
import com.zybooks.inventoryapp.data.CategoryDao;

import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class CategoryRepository {
    private CategoryDao categoryDao;
    private ExecutorService executorService;

    public CategoryRepository(Application application) {
        AppDatabase db = AppDatabase.getDatabase(application);
        categoryDao = db.categoryDao();
        executorService = Executors.newSingleThreadExecutor();
    }

    public void insert(Category category) {
        executorService.execute(() -> categoryDao.insert(category));
    }

    public void update(Category category) {
        executorService.execute(() -> categoryDao.update(category));
    }

    public void delete(Category category) {
        executorService.execute(() -> categoryDao.delete(category));
    }

    public LiveData<List<Category>> getAllCategories() {
        return categoryDao.getAllCategories();
    }

    public Category getCategoryById(int id) {
        return categoryDao.getCategoryById(id);
    }
}
