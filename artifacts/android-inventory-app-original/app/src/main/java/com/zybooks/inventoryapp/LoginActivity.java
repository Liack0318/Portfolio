package com.zybooks.inventoryapp;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;

import com.zybooks.inventoryapp.data.Users;
import com.zybooks.inventoryapp.utils.Dialogs;
import com.zybooks.inventoryapp.utils.PasswordUtils;
import com.zybooks.inventoryapp.viewmodel.ItemViewModel;
import com.zybooks.inventoryapp.viewmodel.UserViewModel;

public class LoginActivity extends AppCompatActivity {

    private static final long SESSION_DURATION = 10 * 60 * 1000; //10 minutes session duration.
    private EditText usernameEditText;
    private EditText passwordEditText;
    private CheckBox rememberMeCheckBox;
    private UserViewModel userViewModel;
    private ItemViewModel itemViewModel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_login);

        //ViewModels initialization
        userViewModel = new ViewModelProvider(this).get(UserViewModel.class);
        itemViewModel = new ViewModelProvider(this).get(ItemViewModel.class);

        //UI initialization
        usernameEditText = findViewById(R.id.username);
        passwordEditText = findViewById(R.id.password);
        rememberMeCheckBox = findViewById(R.id.remembermeCheckBox);
        TextView forgotPasswordTextView = findViewById(R.id.forgotPasswordTextView);

        //Forgot password listener
        forgotPasswordTextView.setOnClickListener(v -> Dialogs.showRecoverPasswordDialog(LoginActivity.this));

        //Check for an active session
        checkActiveSession();
    }

     //Checks if a user session is still active based on the stored session start time.
     //If the session is valid, the user is redirected to the MainActivity.
    private void checkActiveSession() {
        SharedPreferences sharedPreferences = getSharedPreferences("UserSession", MODE_PRIVATE);
        long sessionStartTime = sharedPreferences.getLong("SessionStartTime", 0);

        if (sessionStartTime != 0) {
            long currentTime = System.currentTimeMillis();
            if (currentTime - sessionStartTime < SESSION_DURATION) {
                //Session is still valid, proceed to main activity
                String currentUsername = sharedPreferences.getString("CurrentUsername", null);
                if (currentUsername != null) {
                    Intent intent = new Intent(LoginActivity.this, MainActivity.class);
                    startActivity(intent);
                    finish();
                }
            } else {
                //Session expired, clear the session data
                SharedPreferences.Editor editor = sharedPreferences.edit();
                editor.clear();
                editor.apply();
            }
        }
    }


    //Handle login button when clicked
    public void onLoginButtonClick(View view) {
        String username = usernameEditText.getText().toString().trim();
        String password = passwordEditText.getText().toString().trim();

        if (username.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "Please enter both username and password", Toast.LENGTH_SHORT).show();
            return;
        }

        //Hash the input password
        String hashedPassword = PasswordUtils.encryptPassword(password);

        new Thread(() -> {
            Users user = userViewModel.getUserByUsername(username);

            runOnUiThread(() -> {
                if (user != null && user.getPassword().equals(hashedPassword)) {
                    //Save user session and proceed to main activity
                    saveUserSession(username);
                    proceedAfterLogin();
                } else {
                    Toast.makeText(LoginActivity.this, "Invalid username or password", Toast.LENGTH_SHORT).show();
                }
            });
        }).start();
    }

    //Save the user session in SharedPreferences if remember me checked
    private void saveUserSession(String username) {
        SharedPreferences sharedPreferences = getSharedPreferences("UserSession", MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();

        if (rememberMeCheckBox.isChecked()) {
            editor.putLong("SessionStartTime", System.currentTimeMillis());
        } else {
            editor.remove("SessionStartTime");
        }

        editor.putString("CurrentUsername", username);
        editor.apply();
    }


    //Proceeds to the main activity after successful login, checking for any low stock items.
    private void proceedAfterLogin() {
        //Check low stock items and show alert if needed
        Dialogs.checkLowStockOnLogin(this, itemViewModel, this, this::proceedToMainActivity);
    }

    //Proceed to main activity
    private void proceedToMainActivity() {
        Intent intent = new Intent(LoginActivity.this, MainActivity.class);
        startActivity(intent);
        finish();
    }


    //redirect to Signup screen
    public void onSignUpClick(View view) {
        Intent intent = new Intent(this, SignUpActivity.class);
        startActivity(intent);
    }
}
