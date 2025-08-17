package com.zybooks.inventoryapp;

import android.content.Intent;
import android.os.Bundle;
import android.util.Base64;
import android.util.Patterns;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.lifecycle.ViewModelProvider;

import com.zybooks.inventoryapp.data.Users;
import com.zybooks.inventoryapp.utils.PasswordUtils;
import com.zybooks.inventoryapp.viewmodel.UserViewModel;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.regex.Pattern;

public class SignUpActivity extends AppCompatActivity {

    private EditText usernameEditText;
    private EditText passwordEditTex;
    private EditText confirmPasswordEditText;
    private EditText emailEditText;
    private UserViewModel userViewModel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_sign_up);

        //ViewModel initialization
        userViewModel = new ViewModelProvider(this).get(UserViewModel.class);

        //UI initialization
        usernameEditText = findViewById(R.id.username);
        passwordEditTex = findViewById(R.id.password);
        confirmPasswordEditText = findViewById(R.id.confirmPassword);
        emailEditText = findViewById(R.id.email);
    }

    //Handle the signup button
    public void onSignUpButtonClick(View view) {
        String username = usernameEditText.getText().toString();
        String password = passwordEditTex.getText().toString();
        String confirmPassword = confirmPasswordEditText.getText().toString();
        String email = emailEditText.getText().toString();

        //Email validation
        if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            Toast.makeText(this, "Invalid email address", Toast.LENGTH_SHORT).show();
            return;
        }

        //Username length validation
        if (username.length() < 4) {
            Toast.makeText(this, "Username must be at least 4 characters long", Toast.LENGTH_SHORT).show();
            return;
        }

        //Password strength validation
        if (!isPasswordStrong(password)) {
            Toast.makeText(this, "Password must be at least 8 characters long, contain at least one uppercase letter, and one number", Toast.LENGTH_SHORT).show();
            return;
        }

        //Password match validation
        if (!password.equals(confirmPassword)) {
            Toast.makeText(this, "Passwords don't match", Toast.LENGTH_SHORT).show();
            return;
        }

        //Perform signup
        new Thread(() -> {
            if (userViewModel.isUsernameTaken(username)) {
                runOnUiThread(() -> Toast.makeText(SignUpActivity.this, "Username is already taken", Toast.LENGTH_SHORT).show());
                return;
            }

            //Encrypt password and save new user
            String encryptedPassword = PasswordUtils.encryptPassword(password);

            Users user = new Users();
            user.setUsername(username);
            user.setPassword(encryptedPassword);
            user.setEmail(email);

            userViewModel.insert(user);

            //Redirect user to login if success
            runOnUiThread(() -> {
                Toast.makeText(SignUpActivity.this, "Sign up successful", Toast.LENGTH_SHORT).show();

                Intent intent = new Intent(SignUpActivity.this, LoginActivity.class);
                startActivity(intent);
                finish();
            });
        }).start();
    }

 //Redirects to Login screen
    public void onLoginClick(View view) {
        Intent intent = new Intent(this, LoginActivity.class);
        startActivity(intent);
        finish();
    }

    //Password strength checker
    private boolean isPasswordStrong(String password) {
        // Password must be at least 8 characters, contain at least one uppercase letter, and one number
        return password.length() >= 8 &&
                Pattern.compile("[A-Z]").matcher(password).find() &&
                Pattern.compile("[0-9]").matcher(password).find();
    }

}

