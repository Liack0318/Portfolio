package com.zybooks.inventoryapp;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.zybooks.inventoryapp.data.Category;
import com.zybooks.inventoryapp.data.Item;
import com.zybooks.inventoryapp.data.ItemWithCategory;
import com.zybooks.inventoryapp.utils.Dialogs;
import com.zybooks.inventoryapp.viewmodel.CategoryViewModel;
import com.zybooks.inventoryapp.viewmodel.ItemViewModel;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class AllItems extends MenuActivity {

    private RecyclerView recyclerView;
    private ItemsAdapter adapter;
    private ItemViewModel itemViewModel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_all_items);

        //Initialize ViewModel
        itemViewModel = new ViewModelProvider(this).get(ItemViewModel.class);

        //RecyclerView setup with a linear layout
        recyclerView = findViewById(R.id.all_items_list_recycler);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));

        //Initialize the adapter with an empty list initiallly
        adapter = new ItemsAdapter(new ArrayList<>(), this, itemViewModel);
        recyclerView.setAdapter(adapter);

        //Retrieve search query and selected category from the intent
        String query = getIntent().getStringExtra("SEARCH_QUERY");
        String selectedCategory = getIntent().getStringExtra("SELECTED_CATEGORY");

        //Live data from the ViewModel to update UI
        itemViewModel.getAllItemsWithCategories().observe(this, itemsWithCategories -> {
            if (itemsWithCategories != null) {
                List<itemsList> itemsList = new ArrayList<>();
                List<itemsList> filteredItemsList = new ArrayList<>();
                Random random = new Random();

                for (ItemWithCategory itemWithCategory : itemsWithCategories) {
                    //Random color for each icon in Items
                    String color = String.format("#%06X", (0xFFFFFF & random.nextInt(0xFFFFFF)));
                    String displayName = itemWithCategory.item.getName();
                    String categoryName = itemWithCategory.category.getName();
                    itemsList.add(new itemsList(color, displayName, String.valueOf(itemWithCategory.item.getQuantity()), categoryName));

                    //Filter items based on search query and category
                    boolean matchesQuery = (query == null || query.isEmpty()) || itemWithCategory.item.getName().toLowerCase().contains(query.toLowerCase());
                    boolean matchesCategory = (selectedCategory == null || selectedCategory.equals("All Categories")) || selectedCategory.equals(itemWithCategory.category.getName());

                    if (matchesQuery && matchesCategory) {
                        filteredItemsList.add(new itemsList(color, displayName, String.valueOf(itemWithCategory.item.getQuantity()), categoryName));
                    }
                }

                //If no query or category filter is applied, show all items
                if ((query == null || query.isEmpty()) && (selectedCategory == null || selectedCategory.equals("All Categories"))) {
                    adapter.setItems(itemsList);
                } else if (filteredItemsList.isEmpty()) {
                    //Show a message if no items are found
                    Toast.makeText(AllItems.this, "No items found", Toast.LENGTH_SHORT).show();
                    adapter.setItems(new ArrayList<>()); // Clear the list in the adapter
                } else {
                    //Show filtered items
                    adapter.setItems(filteredItemsList);
                }

                adapter.notifyDataSetChanged();
            }
        });



        //Padding for system bars to avoid overlapping
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        //Add item icon listener
        findViewById(R.id.add_item_icon).setOnClickListener(view ->
                Dialogs.showAddItemDialog(AllItems.this, null)
        );

        //Click listener for search Card
        findViewById(R.id.search_item_icon).setOnClickListener(view ->
                Dialogs.showSearchDialog(AllItems.this)
        );
    }
}