package com.torx.chat

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

// To enable this functionality (autostart), uncomment the relevant section in android/app/src/main/AndroidManifest.xml (if commented) and debug
// Also set ForegroundTaskOptions "autoRunOnBoot: true" Note: it autostarts successfully using its own mechanism.

class BootBroadcastReceiver : BroadcastReceiver() {
	override fun onReceive(context: Context?, intent: Intent) {
		val action = intent.action
		if(action == "android.intent.action.QUICKBOOT_POWERON" || action == "android.intent.action.BOOT_COMPLETED") {
			val launchIntent = context?.packageManager?.getLaunchIntentForPackage(context.packageName)
			launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			context?.startActivity(launchIntent)
		//	val launchIntent = Intent(context, MainActivity::class.java)
		//	launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
		//	context?.startActivity(launchIntent)
		}
		if(action != null)
			Log.d("Checkpoint Kotlin:", action)
		else
			Log.d("Checkpoint Kotlin:", "intent.action is null")
	}
}