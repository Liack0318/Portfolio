package com.zybooks.inventoryapp;

public class itemsList {
    private String color;
    private String name;
    private String quantity;
    private String categoryName;

    //Constructor to initialize all fields
    public itemsList(String color, String name, String quantity, String categoryName) {
        this.color = color;
        this.name = name;
        this.quantity = quantity;
        this.categoryName = categoryName;

    }

    //Getters and setters
    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getQuantity() {
        return quantity;
    }

    public String getCategoryName() {
        return categoryName;
    }

}
