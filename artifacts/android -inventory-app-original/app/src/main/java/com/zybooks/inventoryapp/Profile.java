package com.zybooks.inventoryapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.lifecycle.ViewModelProvider;

import com.zybooks.inventoryapp.data.Users;
import com.zybooks.inventoryapp.utils.Dialogs;
import com.zybooks.inventoryapp.viewmodel.UserViewModel;

public class Profile extends MenuActivity {

    private UserViewModel userViewModel;
    private TextView profileUsernameTextView;
    private TextView profileEmailTextView;
    private Button resetPasswordButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_profile);

        //UI initialization
        profileUsernameTextView = findViewById(R.id.profileUsernameTextView);
        profileEmailTextView = findViewById(R.id.profileEmailTextView);
        resetPasswordButton = findViewById(R.id.resetPasswordButton);

        //ViewModel initialization
        userViewModel = new ViewModelProvider(this).get(UserViewModel.class);

        //LogOut button set up
        Button logOutButton = findViewById(R.id.logoutButton);
        logOutButton.setOnClickListener(this::onLogoutButtonClick);

        //Loads the current user's profile information from SharedPreferences
        SharedPreferences sharedPreferences = getSharedPreferences("UserSession", MODE_PRIVATE);
        String currentUsername = sharedPreferences.getString("CurrentUsername", null);

        if (currentUsername != null) {
            new Thread(() -> {
                Users user = userViewModel.getUserByUsername(currentUsername);
                if (user != null) {
                    runOnUiThread(() -> {
                        profileUsernameTextView.setText(user.getUsername());
                        profileEmailTextView.setText(user.getEmail());
                    });
                }
            }).start();
        }

        //Set up the reset password button
        resetPasswordButton.setOnClickListener(v -> Dialogs.showResetPasswordDialog(Profile.this));
    }

    //Handles de logout button
    public void onLogoutButtonClick(View view) {
        //Clear user's session
        SharedPreferences sharedPreferences = getSharedPreferences("UserSession", MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.clear();
        editor.apply();

        //Navigate to login screen and clear activity stack
        Intent intent = new Intent(Profile.this, LoginActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK); //clear the activity stack
        startActivity(intent);
        finish();
    }

}
