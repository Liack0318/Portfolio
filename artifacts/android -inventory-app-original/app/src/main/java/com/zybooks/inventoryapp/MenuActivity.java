package com.zybooks.inventoryapp;

import android.content.Intent;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;

import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;

import com.zybooks.inventoryapp.R;
import com.zybooks.inventoryapp.utils.Dialogs;


public class MenuActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Enable the up button
        ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setDisplayHomeAsUpEnabled(true);
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.menu, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        int id = item.getItemId();

        // Handle the up button
        if (id == android.R.id.home) {
            onBackPressed();
            return true;
        }

        if (id == R.id.dashboard_menu) {
            startActivity(new Intent(this, MainActivity.class));
            return true;
        } else if (id == R.id.all_items_menu) {
            startActivity(new Intent(this, AllItems.class));
            return true;
        } else if (id == R.id.add_menu) {
            Dialogs.showAddItemDialog(this, null);
            return true;
        } else if (id == R.id.profile_menu) {
            startActivity(new Intent(this, Profile.class));
            return true;
        } else if (id == R.id.settings) {
            startActivity(new Intent(this, SettingsActivity.class));
            return true;
        }

        return super.onOptionsItemSelected(item);
    }


}
