package com.zybooks.inventoryapp.data;

import android.content.Context;

import androidx.room.Database;
import androidx.room.Room;
import androidx.room.RoomDatabase;

@Database(entities = {Users.class, Item.class, Category.class}, version = 3, exportSchema = false)
public abstract class AppDatabase extends RoomDatabase {

    //Methods for DAOs
    public abstract UsersDao userDao();
    public abstract ItemDao itemDao();
    public abstract CategoryDao categoryDao();

    //Singleton instance for the database
    private static volatile AppDatabase INSTANCE;

    // Gets the singleton instance of the AppDatabase. If the database does not exist, it is created.
    public static AppDatabase getDatabase(final Context context) {
        if(INSTANCE == null) {
            synchronized (AppDatabase.class) {
                if (INSTANCE == null) {
                    //Build the database instance
                    INSTANCE = Room.databaseBuilder(context.getApplicationContext(),
                            AppDatabase.class, "app_database")
                            .fallbackToDestructiveMigration()
                            .build();
                }
            }
        }

        return INSTANCE;
    }
}
