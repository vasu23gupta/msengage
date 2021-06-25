package app.alan.alan_voice

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import android.widget.FrameLayout
import android.app.Activity
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.view.*
import com.alan.alansdk.Alan
import com.alan.alansdk.AlanCallback
import com.alan.alansdk.logging.AlanLogger
import com.alan.alansdk.button.AlanButton
import com.alan.alansdk.events.EventCommand
import com.alan.alansdk.events.EventRecognised
import com.alan.alansdk.events.EventText
import com.alan.alansdk.events.EventParsed
import com.alan.alansdk.qr.BarcodeEvent
import com.alan.alansdk.AlanState
import com.alan.alansdk.AlanConfig
import io.flutter.plugin.common.EventChannel
import io.flutter.view.FlutterView
import org.greenrobot.eventbus.EventBus
import org.greenrobot.eventbus.Subscribe
import org.greenrobot.eventbus.ThreadMode

class AlanVoicePlugin(registrar: Registrar): MethodCallHandler {

  private val activity: Activity = registrar.activity()
  private var alanButton: AlanButton? = null
  private var callBackChannel: EventChannel = EventChannel(registrar.messenger(), "alan_voice_callback")
  private val alanSink = AlanEventSink();

  init {
    EventBus.getDefault().register(this)
  }

  companion object {

    private val ARGUMENT_LOG_LEVEL = "logLevel"
    private val ARGUMENT_PROJECT_ID = "projectId"
    private val ARGUMENT_PROJECT_AUTH_JSON = "projectAuthJson"
    private val ARGUMENT_PROJECT_SERVER = "projectServer"
    private val ARGUMENT_PLUGIN_VERSION = "wrapperVersion"

    private val ARGUMENT_BUTTON_HORIZONTAL_ALIGN = "buttonAlign"
    private val ARGUMENT_BUTTON_TOP_MARGIN = "topMargin"
    private val ARGUMENT_BUTTON_BOTTOM_MARGIN = "bottomMargin"
    private val ARGUMENT_STT_VISIBLE = "sttVisible"

    private val ARGUMENT_METHOD_NAME = "method_name"
    private val ARGUMENT_METHOD_ARGS = "method_args"

    private val ARGUMENT_VISUALS = "visuals"
    private val ARGUMENT_TEXT = "text"
    private val ARGUMENT_COMMAND = "command"

    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "alan_voice")
      channel.setMethodCallHandler(AlanVoicePlugin(registrar))
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getVersion" -> version(result)
      "setLogLevel" -> setLogLevel(result, call)
      "addButton" -> addButton(result, call)
      "removeButton" -> removeButton()
      "showButton" -> showButton(result)
      "hideButton" -> hideButton(result)
      "activate" -> activate(result)
      "deactivate" -> deactivate(result)
      "callProjectApi" -> callScript(result, call)
      "setVisualState" -> setVisualState(result, call)
      "playText" -> playText(result, call)
      "playCommand" -> playCommand(result, call)
      "isActive" -> isActive(result, call)
      else -> result.notImplemented()
    }
  }

  private fun setLogLevel(result: Result, call: MethodCall) {
    val logLevel = call.argument<String>(ARGUMENT_LOG_LEVEL)
    if (logLevel == "all") {
        AlanLogger.LogLevel.EVENTS
    }
    else {
        AlanLogger.LogLevel.BASIC
    }
    result.success(true)
  }

  private fun setVisualState(result: Result, call: MethodCall) {
    if (alanButton != null) {
      alanButton?.setVisualState(call.argument<String>(ARGUMENT_VISUALS))
      alanButton?.post {
        result.success(true)
      }
    }
  }

  private fun playCommand(result: Result, call: MethodCall) {
    if (alanButton != null) {
      var command = call.argument<String>(ARGUMENT_COMMAND)
      alanButton?.playCommand(command) { method, body, error ->
        alanButton?.post {
          result.success(listOf(method, body, error))
        }
      }
    }
  }

  private fun playText(result: Result, call: MethodCall) {
    if (alanButton != null) {
        alanButton?.playText(call.argument<String>(ARGUMENT_TEXT))
      alanButton?.post {
        result.success(true)
      }
    }
  }

  private fun callScript(result: Result, call: MethodCall) {
    if (alanButton != null) {
      alanButton?.callProjectApi(call.argument<String>(ARGUMENT_METHOD_NAME),
              call.argument<String>(ARGUMENT_METHOD_ARGS)
      ) { method, body, error ->
        alanButton?.post {
          result.success(listOf(method, body, error))
        }
      }
    }
  }

  private fun version(result: Result) {
    if (alanButton != null) {
      result.success(alanButton?.sdk?.version ?: "")
    }
  }

  private fun isActive(result: Result, call: MethodCall) {
    if (alanButton != null) {
      result.success(alanButton?.isActive())
    }
  }

  private fun activate(result: Result) {
    alanButton?.activate()
    result.success(true)
  }

  private fun deactivate(result: Result) {
    alanButton?.deactivate()
    result.success(true)
  }

  private fun showButton(result: Result) {
    alanButton?.showButton()
    result.success(true)
  }

  private fun hideButton(result: Result) {
    alanButton?.hideButton()
    result.success(true)
  }

  private fun removeButton() {
    if (alanButton != null) {
      val rootView = activity.findViewById(android.R.id.content) as ViewGroup
      alanButton?.sdk?.clearCallbacks()
      alanButton?.getSDK()?.stop()
      rootView.removeView(alanButton)
      alanButton = null
    }
  }

  private fun addButton(result: Result, call: MethodCall) {
    Alan.PLATFORM_SUFFIX = "flutter"
    Alan.PLATFORM_VERSION_SUFFIX = call.argument<String>(ARGUMENT_PLUGIN_VERSION)
    Alan.QR_EVENT_BUS_ENABLED = true

    val projectId = call.argument<String>(ARGUMENT_PROJECT_ID)
    val authJson = call.argument<String>(ARGUMENT_PROJECT_AUTH_JSON)
    val server = call.argument<String>(ARGUMENT_PROJECT_SERVER)

    if (projectId == null) {
      result.error("No objectId, please provide objectId argument", null, null)
      return
    }

    val config = AlanConfig.builder()
              .setProjectId(projectId)
              .setDataObject(authJson)

    if (!server.isNullOrEmpty()) {
      config.setServer("wss://" + server)
    }

    if (alanButton == null) {
      createButton(call, null)
      subscribe()
      val buttonHorizontalAlignment = call.argument<Int?>(ARGUMENT_BUTTON_HORIZONTAL_ALIGN) ?: 1
      alanButton?.setButtonAlign(buttonHorizontalAlignment)

      alanButton?.requestAudioPermissions()
    }

    alanButton?.initWithConfig(config.build())

    subscribe()
    alanButton?.showButton()
    result.success(true)
    return
  }

  @Subscribe(threadMode = ThreadMode.ASYNC)
  fun onBarcodeEvent(event: BarcodeEvent?) {
    Handler(Looper.getMainLooper()).postDelayed({
      subscribe()
    }, 100)
  }

  inner class AlanEventSink : EventChannel.StreamHandler {
    private var sink : EventChannel.EventSink? = null

    override fun onListen(p0: Any?, p1: EventChannel.EventSink?) {
      sink = p1
    }

    override fun onCancel(p0: Any?) {
      sink = null
    }

    fun newAlanState(state: AlanState) {
      sink?.success(listOf("button_state_changed", state.name))
    }

    fun newCommand(payload: String) {
      sink?.success(listOf("command", payload))
    }

    fun newEvent(event: String, payload: String) {
      sink?.success(listOf("event", event, payload))
    }

    fun newOnButtonState(state: AlanState) {
      sink?.success(listOf("onButtonState", state.name))
    }

    fun newOnCommand(payload: String) {
      sink?.success(listOf("onCommand", payload))
    }

    fun newOnEvent(payload: String) {
      sink?.success(listOf("onEvent", payload))
    }
  }

  private fun subscribe() {

    callBackChannel.setStreamHandler(alanSink)

    alanButton?.registerCallback(object : AlanCallback() {
      override fun onAlanStateChanged(alanState: AlanState) {
        alanSink.newAlanState(alanState)
      }

      override fun onCommandReceived(eventCommand: EventCommand?) {
        alanSink.newCommand(eventCommand?.data?.getString("data") ?: "")
      }

      override fun onRecognizedEvent(eventRecognised: EventRecognised?) {
        val text = eventRecognised?.getText() ?: "";
        val final = eventRecognised?.isFinal() ?: false;
        alanSink.newEvent("recognized", "{\"text\":\"${text}\", \"final\":\"${final}\"}")
      }

      override fun onParsedEvent(eventParsed: EventParsed?) {
        val text = eventParsed?.getText() ?: "";
        alanSink.newEvent("parsed", "{\"text\":\"${text}\"}")
      }

      override fun onTextEvent(eventText: EventText?) {
        val text = eventText?.getText() ?: "";
        alanSink.newEvent("text", "{\"text\":\"${text}\"}")
      }

      override fun onEvent(event: String, payload: String) {
        alanSink.newEvent(event, payload)
      }

      override fun onEvent(payload: String) {
        alanSink.newOnEvent(payload)
      }

      override fun onCommand(eventCommand: EventCommand?) {
        alanSink.newOnCommand(eventCommand?.data?.getString("data") ?: "")
      }

      override fun onButtonState(alanState: AlanState) {
        alanSink.newOnButtonState(alanState)
      }
    })
  }

  private fun createButton(call: MethodCall, result: Result?) {
    val rootView = activity.findViewById(android.R.id.content) as ViewGroup
    setScreenshots()
    alanButton = AlanButton(activity, null)
    val params = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT)
    params.gravity = Gravity.BOTTOM or Gravity.END
    alanButton?.let {
      it.layoutParams = params
      it.visibility = View.GONE

      rootView.addView(it)
    }

    result?.success(true)
  }

  private fun setScreenshots() {
    Alan.getInstance(activity).setScreenshotAddon {
      val rootView = activity.findViewById(android.R.id.content) as ViewGroup
      val flutterView = rootView.getChildAt(0)

      if (flutterView is io.flutter.view.FlutterView) {
        flutterView.bitmap
      } else {
        if (flutterView is ViewGroup) {
          val childView = flutterView.getChildAt(0)
          if (childView is io.flutter.embedding.android.FlutterView) {
            getBitmapFromNewEmbeddedFlutterView(childView)
          } else {
            AlanLogger.e("Failed to get bitmap from ${flutterView}")
            null
          }
        } else {
          AlanLogger.e("Failed to get bitmap from ${flutterView}")
          null
        }
      }
    }
  }

  private fun getBitmapFromView(flutterView: View): Bitmap? {
    return if (flutterView is FlutterView) {
      flutterView.bitmap
    } else {
      AlanLogger.e("Failed to cast ${flutterView} to FlutterView")
      null
    }
  }

  private fun getBitmapFromNewEmbeddedFlutterView(flutterView: io.flutter.embedding.android.FlutterView): Bitmap {
      val bitmap = Bitmap.createBitmap(
              flutterView.width,
              flutterView.height,
              Bitmap.Config.ARGB_8888
      )
      val canvas = Canvas(bitmap)
      flutterView.layout(
              0,
              0,
              flutterView.measuredWidth,
              flutterView.measuredHeight
      )
      flutterView.draw(canvas)
      return bitmap
  }
}
