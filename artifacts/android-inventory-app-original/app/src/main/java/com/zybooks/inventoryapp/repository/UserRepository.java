package com.zybooks.inventoryapp.repository;

import android.app.Application;

import com.zybooks.inventoryapp.data.AppDatabase;
import com.zybooks.inventoryapp.data.Users;
import com.zybooks.inventoryapp.data.UsersDao;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class UserRepository {
    private UsersDao userDao;
    private ExecutorService executorService;

    public UserRepository(Application application) {
        AppDatabase db = AppDatabase.getDatabase(application);
        userDao = db.userDao();
        executorService = Executors.newSingleThreadExecutor();
    }

    public void insert(Users user) {
        executorService.execute(() -> userDao.insert(user));
    }

    public void deleteUserByUsername(String username) {
        executorService.execute(() -> userDao.deleteUserByUsername(username));
    }

    public Users getUser(String username, String password) {
        return userDao.getUser(username, password);
    }

    public boolean isUsernameTaken(String username) {
        Users user = userDao.getUserByUsername(username);
        return user != null;
    }

    public Users getUserByUsername(String username) {
        return userDao.getUserByUsername(username);
    }

    public void update(Users user) {
        executorService.execute(() -> userDao.update(user));
    }

}
