package com.zybooks.inventoryapp;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;

import com.zybooks.inventoryapp.utils.Dialogs;
import com.zybooks.inventoryapp.viewmodel.CategoryViewModel;

public class MainActivity extends MenuActivity {

    private CategoryViewModel categoryViewModel;

    private void setUpAddCategoryCard() {
        findViewById(R.id.add_category_card).setOnClickListener(view ->
                Dialogs.showAddCategoryDialog(MainActivity.this, categoryViewModel)
        );
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);

        categoryViewModel = new ViewModelProvider(this).get(CategoryViewModel.class);

        //Click listener for add category
        setUpAddCategoryCard();


        //Click listener for all items Card (show all the categories in the app.
        findViewById(R.id.all_items_card).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(MainActivity.this, AllItems.class);
                startActivity(intent);
            }
        });

        //Click listener for search Card
        findViewById(R.id.search_item_card).setOnClickListener(view ->
                Dialogs.showSearchDialog(MainActivity.this)
        );



        //Click listener for profile card
        findViewById(R.id.profile_card).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(MainActivity.this, Profile.class);
                startActivity(intent);
            }
        });

        //Click listener for add items card
        findViewById(R.id.add_items_card).setOnClickListener(view ->
            Dialogs.showAddItemDialog(MainActivity.this, null)
        );

        //Click listener for settings card
        findViewById(R.id.settings_card).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(MainActivity.this, SettingsActivity.class);
                startActivity(intent);
            }
        });
    }

}
