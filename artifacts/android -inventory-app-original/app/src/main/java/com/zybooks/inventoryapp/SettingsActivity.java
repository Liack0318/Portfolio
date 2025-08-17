package com.zybooks.inventoryapp;

import android.Manifest;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.telephony.SmsManager;
import android.view.LayoutInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.appcompat.widget.SwitchCompat;
import androidx.lifecycle.ViewModelProvider;
import com.zybooks.inventoryapp.data.Category;
import com.zybooks.inventoryapp.data.Item;
import com.zybooks.inventoryapp.data.ItemWithCategory;
import com.zybooks.inventoryapp.utils.Dialogs;
import com.zybooks.inventoryapp.viewmodel.CategoryViewModel;
import com.zybooks.inventoryapp.viewmodel.ItemViewModel;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class SettingsActivity extends MenuActivity {

    private static final int REQUEST_SMS_PERMISSION = 1;
    private SwitchCompat smsNotificationSwitch;
    private SwitchCompat deleteAccountSwitch;
    private CategoryViewModel categoryViewModel;
    private ItemViewModel itemViewModel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_settings);

        //UI initialization
        smsNotificationSwitch = findViewById(R.id.switch_sms_notification);
        deleteAccountSwitch = findViewById(R.id.switch_delete_account);
        Button logOutButton = findViewById(R.id.logoutButton);

        logOutButton.setOnClickListener(this::onLogoutButtonClick);

        //ViewModels initialization
        categoryViewModel = new ViewModelProvider(this).get(CategoryViewModel.class);
        itemViewModel = new ViewModelProvider(this).get(ItemViewModel.class);

        //Check if sms permission is granted
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED) {
            smsNotificationSwitch.setChecked(true);
        } else {
            smsNotificationSwitch.setChecked(false);
        }

        //Listener for sms switch
        smsNotificationSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked) {
                    Dialogs.showPermissionDialog(SettingsActivity.this,
                            SettingsActivity.this::requestSmsPermission,
                            () -> smsNotificationSwitch.setChecked(false));
                } else {
                    Toast.makeText(SettingsActivity.this, "SMS Notifications Disabled", Toast.LENGTH_SHORT).show();
                }
            }
        });

        //Listener for Delete swithc
        deleteAccountSwitch.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked) {
                    Dialogs.showDeleteAccountDialog(SettingsActivity.this, deleteAccountSwitch);
                } else {
                    Toast.makeText(SettingsActivity.this, "Delete Account Disabled", Toast.LENGTH_SHORT).show();
                }
            }
        });

        //up botton in action bar
        ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setDisplayHomeAsUpEnabled(true);
        }

        findViewById(R.id.add_categories_icon).setOnClickListener(view ->
                Dialogs.showAddCategoryDialog(SettingsActivity.this, categoryViewModel)
        );

        findViewById(R.id.edit_categories_icon).setOnClickListener(view ->
                Dialogs.showEditCategoryDialog(SettingsActivity.this, categoryViewModel, itemViewModel)
        );
    }

    //Handle the logout button
    public void onLogoutButtonClick(View view) {
        //Clear the user session
        SharedPreferences sharedPreferences = getSharedPreferences("UserSession", MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.clear();
        editor.apply();

        //Navigate to the login screen and clear activity stack
        Intent intent = new Intent(SettingsActivity.this, LoginActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK); // Clear the activity stack
        startActivity(intent);
        finish();
    }

    //Request SMS permission
    private void requestSmsPermission() {
        ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.RECEIVE_SMS}, REQUEST_SMS_PERMISSION);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_SMS_PERMISSION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                Toast.makeText(this, "SMS Notifications Enabled", Toast.LENGTH_SHORT).show();
                smsNotificationSwitch.setChecked(true);

                Dialogs.showPermissionDialog(this,
                        this::checkLowStockItems,
                        () -> Toast.makeText(this, "Phone number is required for SMS notifications", Toast.LENGTH_SHORT).show());

            } else {
                Toast.makeText(this, "Permission denied to receive SMS", Toast.LENGTH_SHORT).show();
                smsNotificationSwitch.setChecked(false);
            }
        }
    }

    //Checks for items with low stock and handles SMS notifications if permission is granted.
    private void checkLowStockItems() {
        itemViewModel.getAllItemsWithCategories().observe(this, itemsWithCategories -> {
            List<String> lowStockItems = new ArrayList<>();
            boolean isSmsPermissionGranted = ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED;

            for (ItemWithCategory itemWithCategory : itemsWithCategories) {
                Item item = itemWithCategory.item;

                if (item.getQuantity() < 10) {
                    if (isSmsPermissionGranted) {
                        Dialogs.sendSmsNotification(this, item.getName(), item.getQuantity());
                    } else {
                        lowStockItems.add(item.getName());
                    }
                }
            }

            if (!lowStockItems.isEmpty() && !isSmsPermissionGranted) {
                Dialogs.saveLowStockItems(this, lowStockItems);
            }
        });
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            finish();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
}
