package com.richardgms.sketchblade.update;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;
import com.google.android.play.core.appupdate.AppUpdateManagerFactory;
import com.google.android.play.core.install.model.UpdateAvailability;

/** Read-only Play availability; installation stays in the Play Store. */
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
}
