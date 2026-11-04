package com.alfonsinabeltre.focushabit.task

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.alfonsinabeltre.focushabit.userAuth.User
import kotlinx.coroutines.flow.Flow
import kotlin.coroutines.*


@Dao
interface TaskDao {
    @Query("SELECT * FROM Task where id =:taskId AND user_id =:userId")
    fun getTaskById(taskId : Long, userId : String) : Task?

    @Query("SELECT * FROM Task where user_id=:userId")
    suspend fun getAllTaskByUser(userId: String): List<Task>

    @Query("SELECT * FROM Task where user_id =:userId")
    fun getAllTaskFlow(userId : String) : Flow<List<Task>>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertTask(task:Task) : Long

    @Update
    suspend fun updateTask(task: Task) : Int

    @Delete
    suspend fun deleteTask(task: Task) : Int
}
