package com.zybooks.inventoryapp;

import android.content.Context;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.RecyclerView;

import com.zybooks.inventoryapp.data.Item;
import com.zybooks.inventoryapp.utils.Dialogs;
import com.zybooks.inventoryapp.viewmodel.ItemViewModel;

import java.util.List;

public class ItemsAdapter extends RecyclerView.Adapter<ItemsAdapter.ViewHolder> {

    private List<itemsList> mData;
    private LayoutInflater mInflater;
    private Context context;
    private ItemViewModel itemViewModel;

    //Adapter constructor
    public ItemsAdapter(List<itemsList> itemList,Context context,ItemViewModel itemViewModel) {
        this.mInflater = LayoutInflater.from(context);
        this.context = context;
        this.mData = itemList;
        this.itemViewModel = itemViewModel;
    }

    // Total number of items
    @Override
    public int getItemCount() {
        return mData.size();
    }

    //Create new views
    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        View view = mInflater.inflate(R.layout.recicler_elements, parent, false);
        return new ViewHolder(view);
    }

    //Replace the contents of a view
    @Override
    public void onBindViewHolder(final ViewHolder holder, final int position) {
        holder.bindData(mData.get(position));

        holder.editIcon.setOnClickListener(v -> {
            int pos = holder.getAdapterPosition();
            if(pos != RecyclerView.NO_POSITION) {
                itemsList currentItem = mData.get(pos);

                //Find item in database
                new Thread(() -> {
                    Item itemToEdit = itemViewModel.findByName(currentItem.getName());
                    if(itemToEdit != null) {
                        ((AppCompatActivity) context).runOnUiThread(() -> {
                            Dialogs.showAddItemDialog((AppCompatActivity) context, itemToEdit);
                        });
                    }
                }).start();
            }
        });
    }

    //update the lists of items
    public void setItems(List<itemsList> items) {
        mData = items;
    }

    //Holds the item view
    public class ViewHolder extends RecyclerView.ViewHolder {

        ImageView itemIcon;
        TextView itemName, itemsQuantity, itemsCategoryTextView;
        ImageView deleteIcon, editIcon;

        ViewHolder(View itemView) {
            super(itemView);
            itemIcon = itemView.findViewById(R.id.itemIcon);
            itemName = itemView.findViewById(R.id.itemName);
            itemsQuantity = itemView.findViewById(R.id.itemsQuantity);
            deleteIcon = itemView.findViewById(R.id.deleteIcon);
            editIcon = itemView.findViewById(R.id.editIcon);
            itemsCategoryTextView = itemView.findViewById(R.id.itemsCategoryTextView);

            //Icon listener to delete item from database
            deleteIcon.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    int position = getAdapterPosition();
                    if (position != RecyclerView.NO_POSITION) {
                        itemsList currentItem = mData.get(position);

                        //Find the item in the database and delete it
                        new Thread(() -> {
                            Item itemToDelete = itemViewModel.findByName(currentItem.getName());
                            if (itemToDelete != null) {
                                itemViewModel.delete(itemToDelete);
                            }
                        }).start();

                        //Remove the item from the adapter's data list and notify adapter
                        mData.remove(position);
                        notifyItemRemoved(position);
                    }
                }
            });
        }

        //Binds the data to the view
        void bindData(final itemsList item) {
            itemIcon.setColorFilter(Color.parseColor(item.getColor()), PorterDuff.Mode.SRC_IN);
            itemName.setText(item.getName());
            itemsQuantity.setText("Qy: " + item.getQuantity());
            String categoryName = item.getCategoryName();
            itemsCategoryTextView.setText("Category: " + (categoryName != null ? categoryName : "Unknown"));
        }
    }
}
