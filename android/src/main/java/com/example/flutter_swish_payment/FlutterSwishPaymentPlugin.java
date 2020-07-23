package com.example.flutter_swish_payment;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterSwishPaymentPlugin
 */
public class FlutterSwishPaymentPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private MethodChannel channel;
    private Context context;
    private static Activity activity;


    @Override
    public void onAttachedToEngine(FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "flutter_swish_payment");
        channel.setMethodCallHandler(this);
        context = flutterPluginBinding.getApplicationContext();
    }

    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_swish_payment");
        channel.setMethodCallHandler(new FlutterSwishPaymentPlugin());

    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("isSwishAppInstalled")) {
            final boolean isInstalled = isSwishInstalled(context);
            result.success(isInstalled);
            return;
        }
        if (call.method.equals("openSwishApp")) {
            final String token = call.argument("token");
            final String callBackUrl = call.argument("callBackUrl");
            final boolean hasItOpened = openSwishWithToken(context, token, callBackUrl);
            result.success(hasItOpened);
            return;
        }


        result.notImplemented();
    }

    @SuppressLint("NewApi")
    public static boolean openSwishWithToken(Context context, String token, String callBackUrl) {
        if (token == null
                || token.length() == 0
                || callBackUrl == null
                || callBackUrl.length() == 0 || context == null) {
            return false;
        }
        try {
            final Uri url
                    = new Uri.Builder()
                    .scheme("swish")
                    .authority("paymentrequest")
                    .appendQueryParameter("token", token)
                    .appendQueryParameter("callbackurl", callBackUrl)
                    .build();

            final Intent intent = new Intent(Intent.ACTION_VIEW, url);
            intent.setPackage("se.bankgirot.swish");

            if (activity != null) {

                activity.startActivity(intent);
            }


            return true;
        } catch (Exception e) {
            System.out.println("this is the exception " + e.getMessage());

            return false;
        }

    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    public static boolean isSwishInstalled(Context context) {
        try {
            context.getPackageManager().getPackageInfo("se.bankgirot.swish", 0);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
        //Get the application context
        context = activityPluginBinding.getActivity().getApplicationContext();
        activity = activityPluginBinding.getActivity();

    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
        onAttachedToActivity(activityPluginBinding);
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }
}
