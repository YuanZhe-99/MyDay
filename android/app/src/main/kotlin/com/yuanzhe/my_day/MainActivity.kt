package com.yuanzhe.my_day

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    /** The bridge to Android AICore; see [GenAiChannel]. */
    private val genAi = GenAiChannel(this)

    /**
     * Purpose: Register the on-device AI channel for the Flutter engine.
     * Inputs: `flutterEngine`.
     * Returns: None.
     * Side effects: Installs the `com.yuanzhe.my_day/genai` method-channel handler.
     * Notes: [GenAiChannel] creates no AICore client here; see its own note on why.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        genAi.attach(flutterEngine)
    }

    /**
     * Purpose: Release the AICore client when the activity goes away.
     * Inputs: None.
     * Returns: None.
     * Side effects: Closes the on-device model session and cancels any request.
     * Notes: A model left open holds an AICore session, a shared device resource.
     */
    override fun onDestroy() {
        genAi.detach()
        super.onDestroy()
    }
}
