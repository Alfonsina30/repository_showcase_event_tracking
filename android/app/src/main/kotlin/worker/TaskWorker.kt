package com.alfonsinabeltre.focushabit.task

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.work.CoroutineWorker
import androidx.work.Data
import androidx.work.OneTimeWorkRequest
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.alfonsinabeltre.focushabit.database.AppDatabaseApplication
import com.alfonsinabeltre.focushabit.permission_app.notification.HandlerNotification
import com.alfonsinabeltre.focushabit.tasks_history.TaskHistory
import com.alfonsinabeltre.focushabit.tasks_history.TaskHistoryRepositoryImpl
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.DayOfWeek
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit
import java.util.concurrent.TimeUnit


//-- CoroutineWorker: if workManager decides to stop or cancel your worker the coroutine will be automatically
//-- canceled, preventing memory leadk
//-- in fun doWork() is schedule notification
class TaskWorker(private val appContext : Context, params: WorkerParameters) :
    CoroutineWorker(appContext, params) {

/************************* INITIAL SCHEDULE WORKER *******************************************/
    companion object {

    private const val recurrenceDayKeyWorker = "RECURRENCE_DAYS"
    private const val reminderTaskKeyWorker = "REMINDER"
    private const val taskIdKeyWorker = "TASK_ID"
    private const val userIdKeyWorker = "USER_ID"

        @SuppressLint("SuspiciousIndentation")
        @RequiresApi(Build.VERSION_CODES.O)
        fun scheduleOrReplaceWorker(
            taskId: Long,
            userId : String,
            taskMethodChannel: MethodChannel,
            context: Context,
            coroutineScopeIO : CoroutineScope
        ){

            coroutineScopeIO.launch {
                try {
                    val taskRepository = TaskRepositoryImp(AppDatabaseApplication.roomDatabase.taskDao())

                    val task = withContext(Dispatchers.IO){
                        taskRepository.getTaskById(
                            taskId = taskId,
                            userId = userId
                        )
                    }
                    println("✅Dentro de scheduleOrReplaceWorker TRY {} getTaskById taskId $task✅ ")

                    /***** TASK IS NOT NULL ****/
                    if(task != null){
                        val now = LocalDateTime.now()

                        //--- calcular fecha y hora de inicio exacta de la task
                        val parseDate = LocalDateTime.parse(task.date)
                        val parseStartTime = LocalDateTime.parse(task.startTime.toString())

                        //--- concatenar fecha y hora de inicio exacta de la task
                        val taskDateStartTime = LocalDateTime.of(parseDate.year, parseDate.month, parseDate.dayOfMonth,
                            parseStartTime.hour, parseStartTime.minute)

                        // Si es nulo o vacío, usamos 0
                        val reminderMinutes = task.whenShowNotification?.toLongOrNull() ?: 0L

                        val notificationTargetTime = taskDateStartTime.minusMinutes(reminderMinutes)

                        val delayToNotification = ChronoUnit.MILLIS.between(now, notificationTargetTime)
                        val delayToStartTime = ChronoUnit.MILLIS.between(now, taskDateStartTime)

                        var remind :String? = null

                        Log.d("workmanager", "delayToNotification: $delayToNotification delayToStartTime: $delayToStartTime")

                        val initialDelay = if (delayToNotification > 0) {
                            // reminder is future
                            Log.d("workmanager", "Programando Ideal: Notificación a $reminderMinutes min antes. Retardo: $delayToNotification ms.")

                            remind = reminderMinutes.toString()

                            delayToNotification

                        } else if (delayToStartTime > 0) {
                            // the reminder has passed but the start time hasn't

                            Log.d("workmanager", "the reminder has passed but the start time hasn't---delayToStartTime: $delayToStartTime ms.")

                            delayToStartTime
                        } else {
                            Log.d("workmanager", "the start time has passed, running now delay: 0 ms.")
                            0L
                        }

                        Log.d("workmanager","✅TODAY: $now  taskDateStartTime: $taskDateStartTime✅ " +
                                "initialDelay: $initialDelay ")

                        withContext(Dispatchers.Main){

                            Log.d("workmanager", "✅scheduleWorker✅")

                           val requestWorker = scheduleWorker(
                                taskId = taskId,
                                userId = userId,
                                initialDelayMillis = initialDelay,
                                recurrenceDays =  task.repeatDays ?: " ",
                                reminderMinutesStr = remind.toString(),
                                appContext = context
                               )

                            if(requestWorker != null){

                                //-- active Flow on TaskDao
                                val updatedTask = task.copy(
                                    taskNotificationId = task.id.toString(),
                                    taskWorkerId = requestWorker.id.toString(),
                                    taskWorkerStatus = "scheduled"

                                )

                                withContext(Dispatchers.IO){

                                    taskRepository.updateTask(updatedTask)

                                    Log.d("workmanager", "✅TASK $taskId updated con workerID: ${updatedTask.taskWorkerId}✅")
                                }

                                WorkStatusMonitor.startMonitoring(
                                    context,
                                    requestWorker.id,
                                    taskMethodChannel,
                                    taskId
                                )

                            }

                        }
                    }
                    /********** TASK IS NULL ********/
                    else{
                        withContext(Dispatchers.Main){
                            val resultArgs = mapOf(
                                "taskId" to taskId,
                                "success" to false
                            )
                            Log.d("workmanager", "✅Dentro de scheduleWorker TRY {} else{} TASK is null Send RESULT FLUTTER resultArgs $resultArgs** ✅")
                            //TODO: LLAMAR A WORKSTATUSMONITOR O AL CHANNEL CORRESPONDIENTE PARA INDICAR QUE LA TASK NO FUE PROGRAMADA
                            taskMethodChannel.invokeMethod(TaskMethodChannel.INVOKE_TASK_NULL, resultArgs)
                        }

                    }
                }
                /*** EXCEPTION ***/
                catch (e:Exception){
                    withContext(Dispatchers.Main){

                        val resultArgs = mapOf(
                            "taskId" to taskId,
                            "success" to false
                        )
                        Log.d("workmanager","✅Dentro de scheduleWorker  catch (e:Exception): $e *** Send RESULT FLUTTER resultArgs $resultArgs** ✅")
                        //TODO: LLAMAR A WORKSTATUSMONITOR O AL CHANNEL CORRESPONDIENTE PARA INDICAR QUE LA TASK NO FUE PROGRAMADA

                        taskMethodChannel.invokeMethod(TaskMethodChannel.INVOKE_TASK_NULL, resultArgs)
                    } }
            }
        }
    /**
     * Create a new OneTimeWorkRequest.
     * @return true if schedule was success or false if was failed.
     */
    private fun scheduleWorker(
        taskId: Long,
        userId: String,
        initialDelayMillis: Long,
        recurrenceDays: String,
        reminderMinutesStr : String,
        appContext : Context
    ): OneTimeWorkRequest? {

        val inputData = Data.Builder()
            .putLong(taskIdKeyWorker, taskId)
            .putString(userIdKeyWorker, userId)
            .putString(recurrenceDayKeyWorker, recurrenceDays)
            .putString(reminderTaskKeyWorker, reminderMinutesStr)
            .build()

        val nextRequest = OneTimeWorkRequestBuilder<TaskWorker>()
            .setInitialDelay(initialDelayMillis, TimeUnit.MILLISECONDS)
            .setInputData(inputData)
            .addTag("TASK_WORKER_TAG") // is use for cancel all worker
            .build()

        val uniqueWorkName = "TASK_WORKER${taskId}"
       // val uniqueWorkName = "RECURRENCE_${taskId}"

        return try {
            WorkManager.getInstance(appContext)
                .beginUniqueWork(
                    uniqueWorkName,
                    androidx.work.ExistingWorkPolicy.REPLACE,
                    nextRequest
                )
                .enqueue()

            Log.d("workmanager", "✅✅***** Worker enqueue ******✅ ✅ Task $taskId uniqueWorkName $uniqueWorkName.")

            nextRequest
        } catch (e: Exception) {
            Log.e("workmanager", "❌ Exception taskId $taskId: e.message ${e.message}")
            null
        }
    }



     fun cancelWorker(taskId: Long, appContext : Context ){
        val uniqueWorkName = "TASK_WORKER${taskId}"

        WorkManager.getInstance(appContext).cancelUniqueWork(uniqueWorkName)
        Log.d("workmanager", "✅✅***** Worker canceled ******✅✅")

    }
    }

    /*************************************** DO WORK **************************************/
    @SuppressLint("SuspiciousIndentation")
    @RequiresApi(Build.VERSION_CODES.O)
    override suspend fun doWork(): Result {
        return withContext(Dispatchers.IO){

            try {

                //-- get Data.Builder() send to Worker
                val taskId = inputData.getLong(taskIdKeyWorker, -1)
                val userId = inputData.getString(userIdKeyWorker)
                val recurrenceDaysString = inputData.getString(recurrenceDayKeyWorker) ?: ""
                val reminderMinutesStr = inputData.getString(reminderTaskKeyWorker)

                Log.d("workmanager", " ✅TaskWorker doWork() recibido  ✅ task id: $taskId " +
                        "userId $userId recurrenceDaysString: $recurrenceDaysString " +
                        "reminderMinutesStr: $reminderMinutesStr"
                )

                //-- 1L is default value
                if (taskId != -1L && (!userId.isNullOrEmpty())){

                    val taskRepository = TaskRepositoryImp(AppDatabaseApplication.roomDatabase.taskDao())
                    var reEnqueuedSuccessfully = false
                    val currentScheduledTask = taskRepository.getTaskById(taskId, userId)

                        if (currentScheduledTask != null){

                            Log.d("workmanager", " ✅TaskWorker taskRepository.getTaskById task FOUND IT: $currentScheduledTask ✅" )

                            ///---- controller taskDone
                            if(currentScheduledTask.taskDone == 1L){
                                //-- dont show notification
                                Log.d("workmanager", "✅ TASK DONE-- WORKER NOT SCHEDULE")

                                HandlerNotification.cancelNotification(appContext, currentScheduledTask.id)

                                Log.d("workmanager", "✅ NOTIFICATION CANCELED")

                                /********* REPEAT DAYS **************/
                                if (currentScheduledTask.repeatDays.isNullOrEmpty()){
                                    //-- tarea de una sola vez
                                    //--- clean state task and return worker
                                  val task =  currentScheduledTask.copy(
                                      //  taskNotificationId = null,
                                        taskWorkerId = null,
                                        taskWorkerStatus = null
                                    )

                                    taskRepository.updateTask(task)

                                    //--- use archivateCurrentTask only here
                                    //---> if user markTaskDone withOut Open App and first that notification is displayed
                                    archivateCurrentTask(task)

                                    reEnqueuedSuccessfully = true

                                    return@withContext Result.success()
                                }
                                /*************** TASK NOT DONE ********/
                            }else{

                                // 1. Preparar contenido de la notificación
                                val reminderTime = reminderMinutesStr?.toLongOrNull() ?: 0L

                                val notificationContent = if (reminderTime > 0) {
                                    "Scheduled reminder $reminderTime minutes before."
                                } else {
                                    currentScheduledTask.description ?: "¡It's time to start your event!"
                                }

                                HandlerNotification.builderNotification(
                                    context = appContext,
                                    channelId = HandlerNotification.channelId,
                                    notificationId = currentScheduledTask.id.toInt(),
                                    title = currentScheduledTask.taskTitle ?: " ",
                                    content = notificationContent
                                )

                                /***** Lógica de Recurrencia (si la tarea es repetible)***********/
                                // Usamos task.repeatDays para verificar que la tarea tiene recurrencia habilitada en DB.
                                if (currentScheduledTask.repeatDays != null && recurrenceDaysString.isNotEmpty()) {

                                    /****** SCHEDULE NEXT RECURRENCE *****/
                                    val (workRequest, nextDate) = scheduleTaskRecurrenceDays(
                                        task = currentScheduledTask,
                                        recurrenceDaysString = recurrenceDaysString
                                    )

                                    reEnqueuedSuccessfully = workRequest != null

                                    if (reEnqueuedSuccessfully){
                                        //---- modify old task for create new task schedule

                                        val updatedTask = currentScheduledTask.copy(
                                            date = nextDate.toString(),
                                            startTime = nextDate.toString(),
                                            taskDone = 0,
                                            taskWorkerStatus = "scheduled",
                                            taskWorkerId = workRequest!!.id.toString()
                                        )

                                        Log.d("workmanager", "✅ TASK UPDATED: $updatedTask")

                                    }else {

                                        // Si falló la re-programación, marcar como inactiva
                                        val failedTask = currentScheduledTask.copy(
                                            taskWorkerStatus = "failed",
                                            taskWorkerId = workRequest!!.id.toString()
                                        )


                                     //   archivateCurrentTask(failedTask)

                                        taskRepository.updateTask(failedTask)
                                    }

                                    Log.d("workmanager", "✅ Tarea $taskId re-programada con éxito: $reEnqueuedSuccessfully")

                                }

                                /************** tarea de una sola vez   **************/
                                else{
                                    val task =  currentScheduledTask.copy(
                                     //   taskNotificationId = null,
                                        taskWorkerId = null,
                                        taskWorkerStatus = null
                                    )

                                    taskRepository.updateTask(task)

                                  //  archivateCurrentTask(task)

                                    reEnqueuedSuccessfully = true

                                    //--- el codigo no continua compilando
                                    return@withContext Result.success()
                                }

                            }


                            val outputData = Data.Builder()
                                .putBoolean("Progress", reEnqueuedSuccessfully) // set 'true' to the key 'Progress' that will be listen to WorkStatusMonitor
                                .build()


                            //-- send outputData to TaskWorker where is take it
                            return@withContext  Result.success(outputData)




                        }else {
                            // Tarea no encontrada: Finaliza con fracaso o éxito sin datos de progreso
                            Log.d("workmanager", "❌ Task not found for ID $taskId.")
                            return@withContext Result.failure()
                        }

                }else{
                    Log.d("workmanager", " ✅TaskWorker dentro else{}" )
                    return@withContext  Result.failure()
                }

                return@withContext  Result.success()
            }catch (e:Exception){

                Log.d("workmanager", " ✅TaskWorker dentro catch exception $e" )
                return@withContext Result.failure()
            }
        }
    }

    private fun archivateCurrentTask(taskScheduledUpdated : Task){
        try {

            val taskHistoryRepository = TaskHistoryRepositoryImpl(AppDatabaseApplication.roomDatabase.taskHistoryDao())

            //-- ARCHIVAR
            val taskHistory =  TaskHistory.fromMap(taskScheduledUpdated.toMap())

            CoroutineScope(Dispatchers.IO).launch {
                taskHistoryRepository.updateTask(taskHistory)

                Log.d("workmanager", "✅ TASK UPDATED: $taskHistory")
            }

        }catch (e:Exception){
            Log.d("workmanager", "✅ Task not updated error catch")

        }
    }


    /**************************** SCHEDULE TASK RECURRENCE DAYS ******************/
    @RequiresApi(Build.VERSION_CODES.O)
private suspend fun scheduleTaskRecurrenceDays(
        task: Task, recurrenceDaysString: String) : Pair<OneTimeWorkRequest?, LocalDateTime?> {

        Log.d("workmanager","✅DENTRO FUNCION ***** scheduleTaskRecurrenceDays ******✅")

        val parseDate = LocalDateTime.parse(task.date)

        //-- startTime User
        val parseStartTime : LocalDateTime = LocalDateTime.parse(task.startTime.toString())
        val taskStartTime = LocalDateTime.of(parseDate.year, parseDate.month, parseDate.dayOfMonth,
            parseStartTime.hour, parseStartTime.minute)
        val reminderMinutes = task.whenShowNotification?.toLongOrNull() ?: 0L
      //  val repeatDays = task.repeatDays ?: ""

        //--
        val (nextDelay, nextTaskDate) = calculateNextScheduledDelay(
          
