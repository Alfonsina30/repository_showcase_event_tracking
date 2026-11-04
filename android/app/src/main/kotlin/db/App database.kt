package com.alfonsinabeltre.focushabit.database

import android.content.Context
import android.util.Log
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.alfonsinabeltre.focushabit.categories.CategoriesDao
import com.alfonsinabeltre.focushabit.categories.Category
import com.alfonsinabeltre.focushabit.location.Location
import com.alfonsinabeltre.focushabit.location.LocationDao
import com.alfonsinabeltre.focushabit.task.Task
import com.alfonsinabeltre.focushabit.task.TaskDao
import com.alfonsinabeltre.focushabit.tasks_history.TaskHistory
import com.alfonsinabeltre.focushabit.tasks_history.TaskHistoryDao
import com.alfonsinabeltre.focushabit.userAuth.User
import com.alfonsinabeltre.focushabit.userAuth.UserDao
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch


///-- entities are all classes that are connected with the db
@Database(
    entities = [Task::class, User::class, Category::class, Location::class, TaskHistory::class],
    version = 27
)
abstract class AppDatabase : RoomDatabase(){

    abstract fun taskDao() : TaskDao
    abstract fun userDao():UserDao
    abstract fun categoryDao() : CategoriesDao
    abstract fun taskHistoryDao() : TaskHistoryDao
    abstract  fun locationDao() : LocationDao

    //--build an instance to db and re-use it
    companion object{
        const val INITIAL_UID = "EventApp0"
        private var INSTANCE : AppDatabase? = null

        fun getInstance(context : Context) : AppDatabase {
            if (INSTANCE == null){
                synchronized(this){
                    INSTANCE = Room.databaseBuilder(
                        context.applicationContext,
                        AppDatabase::class.java,
                        "taskContextApp.db"
                        )
                        //.createFromAsset("database/taskContextApp.db")
                        .fallbackToDestructiveMigration()
                        .addCallback(DatabaseCallback(context.applicationContext))
                        .addMigrations(
                           // migration_16_17,
                          //  migration_18_19,
                           // migration_23_24
                            migration_25_26
                            )
                        .build()
                }
            }
            return  INSTANCE!!
        }
            //---Migration(16,17) is old version db, new version db
            //---  need also change db version
//        val migration_16_17 = object : Migration(16,17){
//            override fun migrate(db: SupportSQLiteDatabase) {
//                db.execSQL("ALTER TABLE Task ADD COLUMN taskNotificationId TEXT")
//                db.execSQL("ALTER TABLE Task ADD COLUMN taskWorkerId TEXT")
//                db.execSQL("ALTER TABLE Task ADD COLUMN taskWorkerStatus TEXT")
//            }
//        }
//
//        val migration_17_18 = object : Migration(17,18){
//            override fun migrate(db: SupportSQLiteDatabase) {
//                db.execSQL("""
//                    CREATE TABLE TaskHistory (
//                        id INTEGER PRIMARY KEY NOT NULL,
//                        taskId INTEGER,
//                        user_id INTEGER,
//                        taskTitle TEXT,
//                        date TEXT,
//                        startTime TEXT,
//                        endTime TEXT,
//                        category_id INTEGER,
//                        description TEXT,
//                        location_id INTEGER,
//                        repeatDays TEXT,
//                        whenShowNotification TEXT,
//                        isUrgent INTEGER DEFAULT 0,
//                        taskDone INTEGER DEFAULT 0,
//                        taskNotificationId TEXT,
//                        taskWorkerId TEXT,
//                        taskWorkerStatus TEXT
//                    )
//                """)
//            }
//
//        }
//
//        val migration_18_19 = object : Migration(18,19){
//            override fun migrate(db: SupportSQLiteDatabase) {
//                db.execSQL("ALTER TABLE Location ADD COLUMN displayName TEXT")
//            }
//        }
//
//      private val  migration_23_24 = object : Migration(23,24){
//            override fun migrate(db: SupportSQLiteDatabase) {
//                db.execSQL("ALTER TABLE User ADD COLUMN role TEXT")
//                db.execSQL("ALTER TABLE User ADD COLUMN companyId TEXT")
//                db.execSQL("ALTER TABLE User ADD COLUMN password TEXT")
//                db.execSQL("ALTER TABLE User ADD COLUMN bearerToken TEXT")
//            }
//
//        }

        private val migration_25_26 = object : Migration(25,26){
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("""CREATE TABLE IF NOT EXISTS users_new (
                id_user TEXT NOT NULL PRIMARY KEY, 
                email TEXT NOT NULL, 
                name TEXT NOT NULL, 
                role TEXT, 
                companyId TEXT
            )
                """.trimMargin())

                db.execSQL("""
            INSERT INTO users_new (uid, email, name, role, companyId)
            SELECT id_user, email, name, role, companyId FROM User
        """.trimIndent())

                // 3. Eliminar la tabla vieja que tenía las columnas sensibles
                db.execSQL("DROP TABLE User")

                // 4. Renombrar la tabla temporal para que tome el nombre oficial
                db.execSQL("ALTER TABLE users_new RENAME TO User")

            }

        }

    }


    private class DatabaseCallback(
        private val context: Context
    ) : RoomDatabase.Callback() {

        // onOpen(db) is called when the database is opened during app startup 
        override fun onOpen(db: SupportSQLiteDatabase) {
            super.onOpen(db)

        }



        override fun onCreate(db: SupportSQLiteDatabase) {
            super.onCreate(db)

            Log.d("AppDatabase", "creating db")

Category.defaultCategoryInitial(INITIAL_UID).forEach { c ->
            db.execSQL(
                "INSERT INTO Category (name, icon, user_id) VALUES (?, ?, ?)",
                arrayOf(c.name, c.icon, c.user_id)
            )
        }




        }
    }


}
