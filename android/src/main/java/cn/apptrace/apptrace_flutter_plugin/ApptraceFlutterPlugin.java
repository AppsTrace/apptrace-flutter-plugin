package cn.apptrace.apptrace_flutter_plugin;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import com.queyuan.apptracesdk.AppData;
import com.queyuan.apptracesdk.Configuration;
import com.queyuan.apptracesdk.AppTrace;
import com.queyuan.apptracesdk.listener.AppInstallListener;
import com.queyuan.apptracesdk.listener.AppWakeUpListener;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

public class ApptraceFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.NewIntentListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private static final String TAG = "ApptraceFlutterPlugin";

    private static final String METHOD_GET_INSTALL_TRACE = "getInstall";
    private static final String METHOD_REGISTER_WAKEUP = "registerWakeUp";
    private static final String METHOD_INIT = "init";
    private static final String ON_FLUTTER_INSTALL_RSP_EVENT = "onInstallResponse";
    private static final String ON_FLUTTER_WAKEUP_RSP_EVENT = "onWakeUpResponse";

    private MethodChannel methodChannel;
    private boolean hasInit;
    private Intent wakeUpCacheIntent;
    private FlutterPluginBinding cacheFlutterPluginBinding;

    private static final String KEY_CODE = "code";
    private static final String KEY_MSG = "msg";
    private static final String KEY_PARAMSDATA = "paramsData";

    private boolean hasRegisterWakeUp = false;
    private AppData cacheWakeUpData = null;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        cacheFlutterPluginBinding = flutterPluginBinding;
        methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "apptrace_flutter_plugin");
        methodChannel.setMethodCallHandler(this);
    }

    @SuppressLint("LongLogTag")
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equalsIgnoreCase(METHOD_GET_INSTALL_TRACE)) {
            _getInstall();
        } else if (call.method.equalsIgnoreCase(METHOD_REGISTER_WAKEUP)) {
            _registerWakeUp();
        } else if (call.method.equalsIgnoreCase(METHOD_INIT)) {
            Boolean enableClipboard = Boolean.TRUE;
            try {
                enableClipboard = call.argument("enableClipboard");
            } catch (Throwable e) {
                Log.d(TAG, "enableClipboard parsed error: " + e.getMessage());
            }

            _initSDK(Boolean.TRUE.equals(enableClipboard));
        } else {
            result.notImplemented();
        }
    }

    private void _initSDK(boolean enableClipboard) {
        if (cacheFlutterPluginBinding == null || hasInit) {
            return;
        }
        hasInit = true;

        Configuration configuration = new Configuration();
        configuration.setEnableClipboard(enableClipboard);

        Context applicationContext = cacheFlutterPluginBinding.getApplicationContext();

        AppTrace.init(applicationContext, configuration);

        if (wakeUpCacheIntent != null) {
            _getWakeUp(wakeUpCacheIntent);

            wakeUpCacheIntent = null;
        }
    }

    @SuppressLint("LongLogTag")
    private void _getInstall() {
        Log.e(TAG, "Apptrace getInstallTrace did call");

        if (!hasInit) {
            Log.e(TAG, "Apptrace not init!");
            return;
        }

        AppTrace.getInstall(new AppInstallListener() {
            @Override
            public void onInstallFinish(AppData appData) {
                Log.i(TAG, "onInstallFinish");

                if (appData == null) {
                    Map<String, String> result = _parseToResult(
                            -1,
                            "Extract data fail.",
                            "");
                    _dispatchEventToFlutter(ON_FLUTTER_INSTALL_RSP_EVENT, result);

                    return;
                }
                Map<String, String> result = _parseToResult(
                        200,
                        "Success",
                        appData.getParams());
                _dispatchEventToFlutter(ON_FLUTTER_INSTALL_RSP_EVENT, result);
            }

            @Override
            public void onError(int code, String message) {
                Log.e(TAG, "onError");

                Map<String, String> result = _parseToResult(
                        code,
                        message,
                        "");
                _dispatchEventToFlutter(ON_FLUTTER_INSTALL_RSP_EVENT, result);
            }
        });
    }

    @SuppressLint("LongLogTag")
    private void _getWakeUp(Intent intent) {
        if (intent == null) {
            Log.e(TAG, "intent is null!");

            return;
        }

        if (!hasInit) {
            wakeUpCacheIntent = intent;

            Log.e(TAG, "Apptrace not init!");
            return;
        }

        AppTrace.getWakeUp(intent, new AppWakeUpListener() {
            @Override
            public void onWakeUpFinish(AppData appData) {
                if (appData == null) {
                    return;
                }

                if (hasRegisterWakeUp) {
                    Map<String, String> result = _parseToResult(
                            200,
                            "Success",
                            appData.getParams());
                    _dispatchEventToFlutter(ON_FLUTTER_WAKEUP_RSP_EVENT, result);

                    cacheWakeUpData = null;
                } else {
                    cacheWakeUpData = appData;
                }
            }
        });
    }

    @SuppressLint("LongLogTag")
    private void _registerWakeUp() {
        if (!hasInit) {
            Log.e(TAG, "Apptrace not init!");
            return;
        }

        hasRegisterWakeUp = true;

        if (cacheWakeUpData != null) {
            AppData appData = cacheWakeUpData;
            Map<String, String> result = _parseToResult(
                    200,
                    "Success",
                    appData.getParams());
            _dispatchEventToFlutter(ON_FLUTTER_WAKEUP_RSP_EVENT, result);

            cacheWakeUpData = null;
        }
    }

    @SuppressLint("LongLogTag")
    private void _dispatchEventToFlutter(String eventName, Map<String, String> ret) {
        Log.d(TAG, "_dispatchEventToFlutter: " + eventName + ", result: " + ret.toString());

        if (methodChannel == null) {
            Log.e(TAG, "methodChannel is null");

            return;
        }
        methodChannel.invokeMethod(eventName, ret);
    }

    private static Map<String, String> _parseToResult(int code, String msg, String paramsData) {
        Map<String, String> result = new HashMap<>();
        result.put(KEY_CODE, String.valueOf(code));
        result.put(KEY_MSG, msg);
        result.put(KEY_PARAMSDATA, _defaultValue(paramsData));
        return result;
    }

    private static String _defaultValue(String str) {
        if (TextUtils.isEmpty(str)) {
            return "";
        }

        return str;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        binding.addOnNewIntentListener(this);
        Intent intent = binding.getActivity().getIntent();

        _getWakeUp(intent);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        binding.addOnNewIntentListener(this);
    }

    @Override
    public void onDetachedFromActivity() {
    }

    @Override
    public boolean onNewIntent(@NonNull Intent intent) {
        _getWakeUp(intent);
        return false;
    }
}
