package cordova.plugin.biometricauth;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.apache.cordova.PluginResult;


import com.google.gson.Gson;


import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.content.res.Resources;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import java.util.ArrayList;
import java.util.List; 

import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import com.ozforensics.liveness.sdk.actions.model.OzDataResponse;
import com.ozforensics.liveness.sdk.activity.CameraActivity;
import com.ozforensics.liveness.sdk.network.manager.NetworkManager;
import com.ozforensics.liveness.sdk.utility.enums.Action;
import com.ozforensics.liveness.sdk.utility.enums.OzApiRequestErrors;
import com.ozforensics.liveness.sdk.utility.enums.OzApiStatusVideoAnalyse;
import com.ozforensics.liveness.sdk.utility.enums.OzLocale;
import com.ozforensics.liveness.sdk.utility.enums.ResultCode;
import com.ozforensics.liveness.sdk.utility.managers.OzLivenessSDK;
import com.ozforensics.liveness.sdk.actions.model.OzMediaResponse;
import com.ozforensics.liveness.sdk.network.manager.UploadAndAnalyzeStatusListener;
import com.ozforensics.liveness.sdk.network.manager.LoginStatusListener;
import com.ozforensics.liveness.sdk.utility.enums.NetworkMediaTags;
import com.ozforensics.liveness.sdk.actions.model.LivenessCheckResult;

/**
 * This class echoes a string called from JavaScript.
 */
public class BiometricAuth extends CordovaPlugin {
	
	private CallbackContext mCallbackContext;
	private String path;
	
    private UploadAndAnalyzeStatusListener analyzeStatusListener = new UploadAndAnalyzeStatusListener() {

        @Override
        public void onSuccess(@NotNull List<LivenessCheckResult> result, @Nullable String stringInterpretation) {
            //if (stringInterpretation != null) showHint(stringInterpretation);
			mCallbackContext.success(stringInterpretation);
        }

        @Override
        public void onStatusChanged(@Nullable String status) {
            //if (status != null) showHint(status);			
        }

        @Override
        public void onError(@NotNull List<LivenessCheckResult> result, @NotNull String errorMessage) {
            //showHint(errorMessage);
			mCallbackContext.error(errorMessage);
        }
    };

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
		mCallbackContext = callbackContext;
        if (action.equals("analyze")) {
            path = args.getString(0);
			String lang = args.getString(1);
            this.analyze(callbackContext, lang);
            return true;
        }
        return false;
    }

    private void analyze(CallbackContext callbackContext, String lang) {

		final CordovaPlugin that = this;
		LoginStatusListener loginStatusListener = new LoginStatusListener() {
            @Override
            public void onSuccess(@NotNull String token) {
                	List<OzLivenessSDK.OzAction> actions = new ArrayList<>();
					actions.add(OzLivenessSDK.OzAction.Smile);
					actions.add(OzLivenessSDK.OzAction.Scan);

					Intent intent = OzLivenessSDK.INSTANCE.createStartIntent(that.cordova.getActivity(), actions, 3, 3, true, null, null);
					that.cordova.startActivityForResult(that, intent, 5);
            }

            @Override
            public void onError(int errorCode, @NotNull String errorMessage) {
                callbackContext.error(errorMessage);
            }
        };
		
		if(lang.equals("en")) {
			OzLivenessSDK.INSTANCE.setLocale(OzLocale.EN);
		} else if(lang.equals("ru")) {
			OzLivenessSDK.INSTANCE.setLocale(OzLocale.RU);
		} else {
			OzLivenessSDK.INSTANCE.setLocale(OzLocale.HY);
		}
		
		Context context = this.cordova.getActivity();
		String packageName = context.getPackageName();
		Resources resources = context.getResources();
		String api = context.getString(resources.getIdentifier("api_url", "string", packageName));
		String username = context.getString(resources.getIdentifier("username", "string", packageName));
		String password = context.getString(resources.getIdentifier("password", "string", packageName));
        OzLivenessSDK.INSTANCE.login(this.cordova.getActivity().getApplicationContext(), api, username, password, loginStatusListener);
    }
	
	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent data) {
        //super.onActivityResult(requestCode, resultCode, data);

        String error = OzLivenessSDK.INSTANCE.getErrorFromIntent(data);
        List<OzMediaResponse> sdkMediaResult = OzLivenessSDK.INSTANCE.getResultFromIntent(data);
		
		
        if (resultCode == -1) { // Ok Result
            uploadAndAnalyze(sdkMediaResult);
        } else if (resultCode == 0) { // Canceled Result
			mCallbackContext.error("canceled");
		}
    }
	
	private void uploadAndAnalyze(List<OzMediaResponse> mediaList) {
        if (mediaList != null) {
			mediaList.add(new OzMediaResponse(OzMediaResponse.Type.PHOTO, path, NetworkMediaTags.PhotoIdFront));
            OzLivenessSDK.INSTANCE.uploadMediaAndAnalyze(
                    this.cordova.getActivity().getApplicationContext(),
                    mediaList,
                    analyzeStatusListener
            );
        }
    } 
}
