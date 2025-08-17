package com.zybooks.inventoryapp.utils;

import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.telephony.SmsManager;
import android.text.InputType;
import android.util.Patterns;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.SwitchCompat;
import androidx.lifecycle.LifecycleOwner;
import androidx.lifecycle.ViewModelProvider;

import com.zybooks.inventoryapp.AllItems;
import com.zybooks.inventoryapp.LoginActivity;
import com.zybooks.inventoryapp.R;
import com.zybooks.inventoryapp.data.Category;
import com.zybooks.inventoryapp.data.Item;
import com.zybooks.inventoryapp.data.ItemWithCategory;
import com.zybooks.inventoryapp.viewmodel.CategoryViewModel;
import com.zybooks.inventoryapp.viewmodel.ItemViewModel;
import com.zybooks.inventoryapp.viewmodel.UserViewModel;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class Dialogs {

    // Method to display a dialog to add new categories
    public static void showAddCategoryDialog(Context context, CategoryViewModel categoryViewModel) {
        // Initialize the AlertDialog builder and set up the custom view
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        LayoutInflater inflater = LayoutInflater.from(context);
        View dialogView = inflater.inflate(R.layout.add_category, null);

        // Set the view and title
        builder.setView(dialogView)
                .setTitle("Add Category")
                .setNegativeButton(android.R.string.cancel, (dialog, which) -> dialog.cancel());

        // Create and show the dialog
        AlertDialog dialog = builder.create();
        dialog.show();

        // Initialization of the UI
        EditText categoryEditText = dialogView.findViewById(R.id.editTextCategoryName);
        Button addCategoryButton = dialogView.findViewById(R.id.buttonAddCategory);

        // Set the click listener for the add category button
        addCategoryButton.setOnClickListener(v -> {
            String categoryName = categoryEditText.getText().toString();
            if (!categoryName.isEmpty()) {
                // Create a new category nd insert it into the database
                Category category = new Category();
                category.setName(categoryName);
                categoryViewModel.insert(category);

                // Notify the user the new category has been added and close dialog
                ((AppCompatActivity) context).runOnUiThread(() -> {
                    Toast.makeText(context, "Category added", Toast.LENGTH_SHORT).show();
                    dialog.dismiss();
                });
            } else {

                // Alert the user if category is empty
                Toast.makeText(context, "Category name cannot be empty", Toast.LENGTH_SHORT).show();
            }
        });
    }

    // Method to show the SMS Permission Dialog and request phone number
    public static void showPermissionDialog(Context context, Runnable onPermissionGranted, Runnable onPermissionDenied) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle("Permission Needed")
                .setMessage("SMS permission is needed to receive notifications");

        // Add phone number input field
        final EditText input = new EditText(context);
        input.setInputType(InputType.TYPE_CLASS_PHONE);
        input.setHint("Enter your phone number");
        builder.setView(input);

        // Set up the allow and deny buttons
        builder.setPositiveButton("Allow", (dialog, which) -> {
            String phoneNumber = input.getText().toString();
            if (Patterns.PHONE.matcher(phoneNumber).matches()) {
                savePhoneNumber(context, phoneNumber);
                onPermissionGranted.run(); // Proceed with permission granting process
            } else {
                Toast.makeText(context, "Invalid phone number. Please try again.", Toast.LENGTH_SHORT).show();
            }
        });

        builder.setNegativeButton("Deny", (dialog, which) -> {
            onPermissionDenied.run(); // Handle the permission denial
            dialog.dismiss();
        });

        // Create and show the dialog
        builder.create().show();
    }

    // Method to save the phone number in shared preferences
    private static void savePhoneNumber(Context context, String phoneNumber) {
        SharedPreferences sharedPreferences = context.getSharedPreferences("UserDetails", Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString("PhoneNumber", phoneNumber);
        editor.apply();
    }

    // Method to retrieve the saved phone number
    public static String getPhoneNumber(Context context) {
        SharedPreferences sharedPreferences = context.getSharedPreferences("UserDetails", Context.MODE_PRIVATE);
        return sharedPreferences.getString("PhoneNumber", null);
    }

    // Method for Low stock alert
    public static void showLowStockAlert(Context context, List<String> lowStockItems, Runnable onDismiss) {
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle("Low Stock Alert");

        //Construct the message listing all low stock items
        StringBuilder message = new StringBuilder("The following items are low on stock:\n\n");
        for (String item : lowStockItems) {
            message.append(item).append("\n");
        }

        //Set the message and the dismiss button
        builder.setMessage(message.toString());
        builder.setPositiveButton("Dismiss", (dialog, which) -> onDismiss.run());
        builder.setCancelable(false);
        builder.show();
    }

    // Method to notify via SMS about low stock
    public static void sendSmsNotification(Context context, String itemName, int quantity) {
        String phoneNumber = getPhoneNumber(context);
        if (phoneNumber != null) {
            SmsManager smsManager = SmsManager.getDefault();
            String message = "Low Stock Alert: " + itemName + " has only " + quantity + " items left.";
            smsManager.sendTextMessage(phoneNumber, null, message, null, null);
            Toast.makeText(context, "SMS sent for low stock item: " + itemName, Toast.LENGTH_SHORT).show();
        } else {
            Toast.makeText(context, "Phone number is not available. Cannot send SMS.", Toast.LENGTH_SHORT).show();
        }
    }

    // Method to save the Low stock items in shared preferences
    public static void saveLowStockItems(Context context, List<String> lowStockItems) {
        SharedPreferences sharedPreferences = context.getSharedPreferences("LowStockItems", Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putStringSet("items", new HashSet<>(lowStockItems));
        editor.apply();
    }

    // Method to check low stock items when logging in
    public static void checkLowStockOnLogin(Context context, ItemViewModel itemViewModel, LifecycleOwner lifecycleOwner, Runnable onProceed) {
        itemViewModel.getAllItemsWithCategories().observe(lifecycleOwner, itemsWithCategories -> {
            List<String> lowStockItems = new ArrayList<>();

            for (ItemWithCategory itemWithCategory : itemsWithCategories) {
                Item item = itemWithCategory.item;
                if (item.getQuantity() < 10) {
                    lowStockItems.add(item.getName() + " (Quantity: " + item.getQuantity() + ")");
                }
            }

            if (!lowStockItems.isEmpty()) {
                showLowStockAlert(context, lowStockItems, onProceed);
            } else {
                onProceed.run();
            }
        });
    }

    // Method to show the Add Item and Edit Dialog
    public static void showAddItemDialog(AppCompatActivity activity, Item item) {
        ItemViewModel itemViewModel = new ViewModelProvider(activity).get(ItemViewModel.class);
        CategoryViewModel categoryViewModel = new ViewModelProvider(activity).get(CategoryViewModel.class);

        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        LayoutInflater inflater = activity.getLayoutInflater();
        View dialogView = inflater.inflate(R.layout.add_item, null);

        builder.setView(dialogView);

        // Cancel Button
        builder.setNegativeButton(android.R.string.cancel, (dialog, which) -> dialog.cancel());

        //Dialog Title
        builder.setTitle(item != null ? "Edit Item" : "Add Item");

        // Create and show the dialog
        AlertDialog dialog = builder.create();
        dialog.show();

        // Initialize UI elements
        EditText itemNameEditText = dialogView.findViewById(R.id.editTextName);
        Spinner itemCategorySpinner = dialogView.findViewById(R.id.spinnerCategory);
        EditText itemQuantityEditText = dialogView.findViewById(R.id.editTextQuantity);
        EditText itemDescriptionEditText = dialogView.findViewById(R.id.editTextDescription);
        ImageButton addIcon = dialogView.findViewById(R.id.buttonAdd);
        ImageButton minusIcon = dialogView.findViewById(R.id.buttonMinus);

        List<Integer> categoryIds = new ArrayList<>();

        // Load categories from the database and set them to the spinner
        categoryViewModel.getAllCategories().observe(activity, categories -> {

            // Prevent crash by checking if category list is empty
        if (categories.isEmpty()) {
            Toast.makeText(activity, "You must create a category first", Toast.LENGTH_SHORT).show();
            dialog.dismiss();
            return;
        }

            List<String> categoryNames = new ArrayList<>();

            for (Category category : categories) {
                categoryNames.add(category.getName()); // Assuming Category has a getName() method
                categoryIds.add(category.getId()); // Assuming Category has a getId() method
            }

            ArrayAdapter<String> adapter = new ArrayAdapter<>(activity, android.R.layout.simple_spinner_item, categoryNames);
            adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            itemCategorySpinner.setAdapter(adapter);

            //Pre-select the category if editing and existing Item
            if (item != null) {
                int categoryPosition = categoryIds.indexOf(item.getCategoryId());
                if (categoryPosition >= 0) {
                    itemCategorySpinner.setSelection(categoryPosition);
                }
            }
        });

        //Pre-fill fields if editing
        if (item != null) {
            itemNameEditText.setText(item.getName());
            itemQuantityEditText.setText(String.valueOf(item.getQuantity()));
            itemDescriptionEditText.setText(item.getDescription());
        }

        // Add button click listener
        addIcon.setOnClickListener(v -> {
            String quantityText = itemQuantityEditText.getText().toString();
            int currentQuantity = 0;

            if (!quantityText.isEmpty()) {
                try {
                    currentQuantity = Integer.parseInt(quantityText);
                } catch (NumberFormatException e) {
                    currentQuantity = 0; // Fallback to 0 if there's a parsing error
                }
            }

            itemQuantityEditText.setText(String.valueOf(currentQuantity + 1));
        });

        // Minus button click listener
        minusIcon.setOnClickListener(v -> {
            String quantityText = itemQuantityEditText.getText().toString();
            int currentQuantity = 0;

            if (!quantityText.isEmpty()) {
                try {
                    currentQuantity = Integer.parseInt(quantityText);
                } catch (NumberFormatException e) {
                    currentQuantity = 0; // Fallback to 0 if there's a parsing error
                }
            }

            if (currentQuantity > 0) {
                itemQuantityEditText.setText(String.valueOf(currentQuantity - 1));
            } else {
                itemQuantityEditText.setText("0");
            }
        });

        // Handle the save button click
        Button saveButton = dialogView.findViewById(R.id.buttonSave);
        saveButton.setOnClickListener(v -> {
            String name = itemNameEditText.getText().toString();
            int selectedPosition = itemCategorySpinner.getSelectedItemPosition(); // Get the selected position
            int categoryId = categoryIds.get(selectedPosition); // Get the category ID based on the selected position
            int quantity = Integer.parseInt(itemQuantityEditText.getText().toString());
            String description = itemDescriptionEditText.getText().toString();

            //If editing update existing item, otherwise create a new item
            if (item != null) {
                item.setName(name);
                item.setCategoryId(categoryId);
                item.setQuantity(quantity);
                item.setDescription(description);
                itemViewModel.update(item);

                new Thread(() -> {
                    itemViewModel.update(item);
                    activity.runOnUiThread(() -> {
                        Toast.makeText(activity, "Item updated", Toast.LENGTH_SHORT).show();
                        dialog.dismiss(); // Close the dialog
                    });
                }).start();

            } else {

                Item newItem = new Item();
                newItem.setName(name);
                newItem.setCategoryId(categoryId);
                newItem.setQuantity(quantity);
                newItem.setDescription(description);

                new Thread(() -> {
                    itemViewModel.insert(newItem);
                    activity.runOnUiThread(() -> {
                        Toast.makeText(activity, "Item added", Toast.LENGTH_SHORT).show();
                        dialog.dismiss();
                    });
                }).start();
            }
        });
    }

    //Method to show reset password Dialog
    public static void showResetPasswordDialog(AppCompatActivity activity) {
        UserViewModel userViewModel = new ViewModelProvider(activity).get(UserViewModel.class);

        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        LayoutInflater inflater = activity.getLayoutInflater();
        View dialogView = inflater.inflate(R.layout.reset_password, null);

        builder.setView(dialogView)
                .setTitle("Reset Password")
                .setNegativeButton(android.R.string.cancel, (dialog, which) -> dialog.cancel());

        AlertDialog dialog = builder.create();
        dialog.show();

        EditText oldPasswordEditText = dialogView.findViewById(R.id.oldPasswordEditText);
        EditText newPasswordEditText = dialogView.findViewById(R.id.newPasswordEditText);
        EditText confirmNewPasswordEditText = dialogView.findViewById(R.id.confirmNewPasswordEditText);
        TextView errorTextView = dialogView.findViewById(R.id.errorTextView);
        Button resetPasswordButton = dialogView.findViewById(R.id.buttonResetPassword);

        resetPasswordButton.setOnClickListener(v -> {
            String oldPassword = oldPasswordEditText.getText().toString();
            String newPassword = newPasswordEditText.getText().toString();
            String confirmNewPassword = confirmNewPasswordEditText.getText().toString();

            if (oldPassword.isEmpty() || newPassword.isEmpty() || confirmNewPassword.isEmpty()) {
                errorTextView.setText("All fields are required.");
                errorTextView.setVisibility(View.VISIBLE);
            } else if (!newPassword.equals(confirmNewPassword)) {
                errorTextView.setText("New passwords do not match.");
                errorTextView.setVisibility(View.VISIBLE);
            } else {
                SharedPreferences sharedPreferences = activity.getSharedPreferences("UserSession", Context.MODE_PRIVATE);
                String currentUsername = sharedPreferences.getString("CurrentUsername", null);

                new Thread(() -> {
                    //Hash the old password to validate it
                    String hashedOldPassword = PasswordUtils.encryptPassword(oldPassword);
                    boolean isOldPasswordCorrect = userViewModel.validateOldPassword(currentUsername, hashedOldPassword);

                    if (isOldPasswordCorrect) {
                        //Hash the new password before updating it
                        String hashedNewPassword = PasswordUtils.encryptPassword(newPassword);
                        userViewModel.updatePassword(currentUsername, hashedNewPassword);

                        activity.runOnUiThread(() -> {
                            Toast.makeText(activity, "Password updated successfully", Toast.LENGTH_SHORT).show();
                            dialog.dismiss();
                        });
                    } else {
                        activity.runOnUiThread(() -> {
                            errorTextView.setText("Old password is incorrect.");
                            errorTextView.setVisibility(View.VISIBLE);
                        });
                    }
                }).start();
            }
        });
    }

    //Method to show search dialog
    public static void showSearchDialog(AppCompatActivity activity) {
        LayoutInflater inflater = LayoutInflater.from(activity);
        View dialogView = inflater.inflate(R.layout.search_item, null);
        AlertDialog.Builder builder = new AlertDialog.Builder(activity);

        builder.setView(dialogView);
        builder.setTitle(R.string.search_item);

        //Cancel button
        builder.setNegativeButton(android.R.string.cancel, (dialog, which) -> dialog.cancel());

        //Create and show the dialog
        AlertDialog dialog = builder.create();
        dialog.show();

        EditText inputText = dialogView.findViewById(R.id.input_text);
        Spinner categorySpinner = dialogView.findViewById(R.id.spinnerCategory);
        Button submitButton = dialogView.findViewById(R.id.submit_button);

        CategoryViewModel categoryViewModel = new ViewModelProvider(activity).get(CategoryViewModel.class);
        List<String> categoryNames = new ArrayList<>();
        categoryNames.add("All Categories");

        categoryViewModel.getAllCategories().observe(activity, categories -> {
            for (Category category : categories) {
                categoryNames.add(category.getName());
            }

            ArrayAdapter<String> adapter = new ArrayAdapter<>(activity, android.R.layout.simple_spinner_item, categoryNames);
            adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            categorySpinner.setAdapter(adapter);
        });

        // Handle submit button click
        submitButton.setOnClickListener(v -> {
            String query = inputText.getText().toString().trim();
            String selectedCategory = categorySpinner.getSelectedItem().toString();
            dialog.dismiss();

            // Start AllItems activity with search query and selected category
            Intent intent = new Intent(activity, AllItems.class);
            intent.putExtra("SEARCH_QUERY", query);
            intent.putExtra("SELECTED_CATEGORY", selectedCategory);
            activity.startActivity(intent);
        });
    }

    //Method to show edit category
    public static void showEditCategoryDialog(AppCompatActivity activity, CategoryViewModel categoryViewModel, ItemViewModel itemViewModel) {
        AlertDialog.Builder builder = new AlertDialog.Builder(activity);
        LayoutInflater inflater = activity.getLayoutInflater();
        View dialogView = inflater.inflate(R.layout.edit_category, null);

        builder.setView(dialogView)
                .setTitle("Edit Category")
                .setNegativeButton(android.R.string.cancel, (dialog, which) -> dialog.cancel());

        AlertDialog dialog = builder.create();
        dialog.show();

        Spinner categorySpinner = dialogView.findViewById(R.id.spinnerCategory);
        EditText categoryNameEditText = dialogView.findViewById(R.id.editTextCategoryName);
        Button saveButton = dialogView.findViewById(R.id.buttonSaveCategory);
        Button deleteButton = dialogView.findViewById(R.id.buttonDeleteCategory);

        List<Category> categories = new ArrayList<>();
        List<String> categoryNames = new ArrayList<>();

        categoryViewModel.getAllCategories().observe(activity, categoryList -> {
            categories.clear();
            categories.addAll(categoryList);

            categoryNames.clear();
            for (Category category : categories) {
                categoryNames.add(category.getName());
            }

            ArrayAdapter<String> adapter = new ArrayAdapter<>(activity, android.R.layout.simple_spinner_item, categoryNames);
            adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
            categorySpinner.setAdapter(adapter);
        });

        // Update EditText when a category is selected
        categorySpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                categoryNameEditText.setText(categories.get(position).getName());
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {
                categoryNameEditText.setText("");
            }
        });

        // Save button functionality
        saveButton.setOnClickListener(v -> {
            int selectedPosition = categorySpinner.getSelectedItemPosition();
            String newName = categoryNameEditText.getText().toString().trim();
            if (!newName.isEmpty()) {
                Category category = categories.get(selectedPosition);
                category.setName(newName);
                categoryViewModel.update(category);
                Toast.makeText(activity, "Category updated", Toast.LENGTH_SHORT).show();
                dialog.dismiss();
            } else {
                Toast.makeText(activity, "Category name cannot be empty", Toast.LENGTH_SHORT).show();
            }
        });

        // Delete button functionality
        deleteButton.setOnClickListener(v -> {
            int selectedPosition = categorySpinner.getSelectedItemPosition();
            Category categoryToDelete = categories.get(selectedPosition);

            new AlertDialog.Builder(activity)
                    .setTitle("Delete Category")
                    .setMessage("Deleting this category will also delete all items under this category. Do you want to proceed?")
                    .setPositiveButton("Delete", (deleteDialog, which) -> {
                        // Delete items under this category
                        itemViewModel.deleteItemsByCategory(categoryToDelete.getId());

                        // Delete the category itself
                        categoryViewModel.delete(categoryToDelete);

                        Toast.makeText(activity, "Category and its items deleted", Toast.LENGTH_SHORT).show();
                        dialog.dismiss();
                    })
                    .setNegativeButton("Cancel", (deleteDialog, which) -> deleteDialog.dismiss())
                    .create()
                    .show();
        });
    }

    //Method to show delete account dialog
    public static void showDeleteAccountDialog(AppCompatActivity activity, SwitchCompat deleteAccountSwitch) {
        UserViewModel userViewModel = new ViewModelProvider(activity).get(UserViewModel.class);

        new AlertDialog.Builder(activity)
                .setTitle("Delete Account")
                .setMessage("This action cannot be undone. Are you sure you want to proceed?")
                .setPositiveButton("Proceed", (dialog, which) -> {
                    //delete the currently signed-in account
                    SharedPreferences sharedPreferences = activity.getSharedPreferences("UserSession", Context.MODE_PRIVATE);
                    String currentUsername = sharedPreferences.getString("CurrentUsername", null);
                    if (currentUsername != null) {
                        userViewModel.deleteAccount(currentUsername);
                        //Clear the session
                        sharedPreferences.edit().clear().apply();
                        //Redirect to login screen
                        Intent intent = new Intent(activity, LoginActivity.class);
                        activity.startActivity(intent);
                        activity.finish();
                    } else {
                        Toast.makeText(activity, "No user found to delete", Toast.LENGTH_SHORT).show();
                    }
                })
                .setNegativeButton("Cancel", (dialog, which) -> {
                    deleteAccountSwitch.setChecked(false);
                    dialog.dismiss();
                })
                .show();
    }


    public static void showRecoverPasswordDialog(Context context) {
        //Inflate the custom layout for the dialog
        LayoutInflater inflater = LayoutInflater.from(context);
        View dialogView = inflater.inflate(R.layout.forgot_password, null);

        final EditText emailEditText = dialogView.findViewById(R.id.editTextRecoverEmail);

        //Create and show the alert dialog
        AlertDialog.Builder builder = new AlertDialog.Builder(context);
        builder.setTitle("Recover Password")
                .setView(dialogView)
                .setPositiveButton("Send Recovery Link", (dialog, which) -> {
                    String email = emailEditText.getText().toString().trim();

                    //Check if the email is valid
                    if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
                        Toast.makeText(context, "Please enter a valid email address", Toast.LENGTH_SHORT).show();
                        return;
                    }

                    sendRecoveryEmail(context, email);

                    // Notify the user that a recovery link will be sent
                    Toast.makeText(context, "A recovery link will be sent to " + email, Toast.LENGTH_SHORT).show();
                })
                .setNegativeButton("Cancel", (dialog, which) -> dialog.dismiss())
                .create()
                .show();
    }

    private static void sendRecoveryEmail(Context context, String email) {
        //TODO Implementation of this is coming as a personal project
    }


}