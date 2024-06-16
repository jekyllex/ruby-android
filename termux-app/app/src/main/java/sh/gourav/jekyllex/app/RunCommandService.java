package sh.gourav.jekyllex.app;

import android.app.Service;
import android.content.Intent;
import android.net.Uri;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.Properties;

/**
 * When allow-external-apps property is set to "true" in ~/.termux/termux.properties, Termux 
 * is able to process execute intents sent by third-party applications.
 *
 * Third-party program must declare sh.gourav.jekyllex.permission.RUN_COMMAND permission and it should be
 * granted by user.
 * Full path of command or script must be given in "RUN_COMMAND_PATH" extra.
 * The "RUN_COMMAND_ARGUMENTS", "RUN_COMMAND_WORKDIR" and "RUN_COMMAND_BACKGROUND" extras are 
 * optional. The background mode defaults to false.
 *
 * Sample code to run command "top" with java:
 *   Intent intent = new Intent();
 *   intent.setClassName("sh.gourav.jekyllex", "sh.gourav.jekyllex.app.RunCommandService");
 *   intent.setAction("sh.gourav.jekyllex.RUN_COMMAND");
 *   intent.putExtra("sh.gourav.jekyllex.RUN_COMMAND_PATH", "/data/data/sh.gourav.jekyllex/files/usr/bin/top");
 *   intent.putExtra("sh.gourav.jekyllex.RUN_COMMAND_ARGUMENTS", new String[]{"-n", "5"});
 *   intent.putExtra("sh.gourav.jekyllex.RUN_COMMAND_WORKDIR", "/data/data/sh.gourav.jekyllex/files/home");
 *   intent.putExtra("sh.gourav.jekyllex.RUN_COMMAND_BACKGROUND", false);
 *   startService(intent);
 *
 * Sample code to run command "top" with "am startservice" command:
 * am startservice --user 0 -n sh.gourav.jekyllex/sh.gourav.jekyllex.app.RunCommandService
 * -a sh.gourav.jekyllex.RUN_COMMAND
 * --es sh.gourav.jekyllex.RUN_COMMAND_PATH '/data/data/sh.gourav.jekyllex/files/usr/bin/top'
 * --esa sh.gourav.jekyllex.RUN_COMMAND_ARGUMENTS '-n,5'
 * --es sh.gourav.jekyllex.RUN_COMMAND_WORKDIR '/data/data/sh.gourav.jekyllex/files/home'
 * --ez sh.gourav.jekyllex.RUN_COMMAND_BACKGROUND 'false'
 */
public class RunCommandService extends Service {

    public static final String RUN_COMMAND_ACTION = "sh.gourav.jekyllex.RUN_COMMAND";
    public static final String RUN_COMMAND_PATH = "sh.gourav.jekyllex.RUN_COMMAND_PATH";
    public static final String RUN_COMMAND_ARGUMENTS = "sh.gourav.jekyllex.RUN_COMMAND_ARGUMENTS";
    public static final String RUN_COMMAND_WORKDIR = "sh.gourav.jekyllex.RUN_COMMAND_WORKDIR";
    public static final String RUN_COMMAND_BACKGROUND = "sh.gourav.jekyllex.RUN_COMMAND_BACKGROUND";

    class LocalBinder extends Binder {
        public final RunCommandService service = RunCommandService.this;
    }

    private final IBinder mBinder = new RunCommandService.LocalBinder();

    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }

    public int onStartCommand(Intent intent, int flags, int startId) {
        if (allowExternalApps() && RUN_COMMAND_ACTION.equals(intent.getAction())) {
            Uri programUri = new Uri.Builder().scheme("sh.gourav.jekyllex.file").path(intent.getStringExtra(RUN_COMMAND_PATH)).build();

            Intent execIntent = new Intent(TermuxService.ACTION_EXECUTE, programUri);
            execIntent.setClass(this, TermuxService.class);
            execIntent.putExtra(TermuxService.EXTRA_ARGUMENTS, intent.getStringArrayExtra(RUN_COMMAND_ARGUMENTS));
            execIntent.putExtra(TermuxService.EXTRA_CURRENT_WORKING_DIRECTORY, intent.getStringExtra(RUN_COMMAND_WORKDIR));
            execIntent.putExtra(TermuxService.EXTRA_EXECUTE_IN_BACKGROUND, intent.getBooleanExtra(RUN_COMMAND_BACKGROUND, false));

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                this.startForegroundService(execIntent);
            } else {
                this.startService(execIntent);
            }
        }

        return Service.START_NOT_STICKY;
    }

    private boolean allowExternalApps() {
        File propsFile = new File(TermuxService.HOME_PATH + "/.termux/termux.properties");
        if (!propsFile.exists())
            propsFile = new File(TermuxService.HOME_PATH + "/.config/termux/termux.properties");

        Properties props = new Properties();
        try {
            if (propsFile.isFile() && propsFile.canRead()) {
                try (FileInputStream in = new FileInputStream(propsFile)) {
                    props.load(new InputStreamReader(in, StandardCharsets.UTF_8));
                }
            }
        } catch (Exception e) {
            Log.e("termux", "Error loading props", e);
        }

        return props.getProperty("allow-external-apps", "false").equals("true");
    }
}
