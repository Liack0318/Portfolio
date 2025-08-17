package com.zybooks.inventoryapp.data;

import androidx.room.Embedded;
import androidx.room.Relation;

public class ItemWithCategory {

    @Embedded
    public Item item;

    @Relation(
            parentColumn = "categoryId",
            entityColumn = "id"
    )
    public Category category;
}
