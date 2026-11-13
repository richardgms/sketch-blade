package com.richardgms.sketchblade.update;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;
import com.google.android.play.core.appupdate.AppUpdateManagerFactory;
import com.google.android.play.core.install.model.UpdateAvailability;
import com.google.android.play.core.review.ReviewManager;
import com.google.android.play.core.review.ReviewManagerFactory;

/** Read-only Play availability (installation stays in the Play Store) and the in-app review sheet. */
public final class PlayUpdatePlugin extends GodotPlugin {
    // 0 pending, 1 no update, 2 available, -1 failed.
    private volatile int state = 0;
    private volatile int availableCode = 0;

    public PlayUpdatePlugin(Godot godot) { super(godot); }

    @Override public String getPluginName() { return "SketchBladePlayUpdate"; }

    @UsedByGodot public void query_update() {
        state = 0;
        availableCode = 0;
        if (getActivity() == null) { state = -1; return; }
        getActivity().runOnUiThread(() -> {
            try {
                AppUpdateManagerFactory.create(getActivity()).getAppUpdateInfo()
                    .addOnSuccessListener(info -> {
                        if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE) {
                            availableCode = info.availableVersionCode();
                            state = 2;
                        } else { state = 1; }
                    })
                    .addOnFailureListener(error -> state = -1);
            } catch (RuntimeException error) { state = -1; }
        });
    }

    @UsedByGodot public int get_update_state() { return state; }
    @UsedByGodot public int get_available_version_code() { return availableCode; }

    // In-app review: 0 running, 1 finished (Play never says if the sheet showed), -1 failed.
    private volatile int reviewState = 1;

    @UsedByGodot public void request_review() {
        reviewState = 0;
        if (getActivity() == null) { reviewState = -1; return; }
        getActivity().runOnUiThread(() -> {
            try {
                ReviewManager manager = ReviewManagerFactory.create(getActivity());
                manager.requestReviewFlow().addOnCompleteListener(request -> {
                    if (!request.isSuccessful() || getActivity() == null) { reviewState = -1; return; }
                    manager.launchReviewFlow(getActivity(), request.getResult())
                        .addOnCompleteListener(flow -> reviewState = 1);
                });
            } catch (RuntimeException error) { reviewState = -1; }
        });
    }

    @UsedByGodot public int get_review_state() { return reviewState; }
}
