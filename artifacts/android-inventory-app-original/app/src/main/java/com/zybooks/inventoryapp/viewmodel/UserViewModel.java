package com.zybooks.inventoryapp.viewmodel;

import android.app.Application;

import androidx.lifecycle.AndroidViewModel;

import com.zybooks.inventoryapp.data.Users;
import com.zybooks.inventoryapp.repository.UserRepository;

public class UserViewModel extends AndroidViewModel {
    private UserRepository repository;

    public UserViewModel(Application application) {
        super(application);
        repository = new UserRepository(application);
    }

    public void insert(Users user) {
        repository.insert(user);
    }

    public void deleteAccount (String username) {
        repository.deleteUserByUsername(username);
    }

    public Users getUserByUsername(String username) {
        return repository.getUserByUsername(username);
    }

    public boolean isUsernameTaken(String username) {
        return repository.isUsernameTaken(username);
    }

    // Validate old password
    public boolean validateOldPassword(String username, String oldPassword) {
        Users user = repository.getUser(username, oldPassword);
        return user != null;
    }

    // Update password
    public void updatePassword(String username, String newPassword) {
        Users user = repository.getUserByUsername(username);
        if (user != null) {
            user.setPassword(newPassword);
            repository.update(user);
        }
    }
}
