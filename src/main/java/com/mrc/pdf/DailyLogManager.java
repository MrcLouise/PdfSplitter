package com.mrc.pdf;

import java.io.File;
import java.io.FileFilter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardOpenOption;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Manages daily rotation of logfile.txt inside a log subfolder.
 */
public class DailyLogManager {

    private static final String LOG_FILE_NAME = "logfile.txt";
    private static final String DATE_SUFFIX_FORMAT = "yyyyMMdd";
    private static final SimpleDateFormat SDF = new SimpleDateFormat(DATE_SUFFIX_FORMAT);

    private final File logFile;

    public DailyLogManager(File logDir) {
        if (logDir == null) {
            throw new IllegalArgumentException("log directory is required");
        }
        File actualLogDir = new File(logDir, "log");
        if (!actualLogDir.exists() && !actualLogDir.mkdirs()) {
            throw new IllegalStateException("cannot create log directory: " + actualLogDir.getAbsolutePath());
        }
        this.logFile = new File(actualLogDir, LOG_FILE_NAME);
    }

    /**
     * Rotate the log file when it belongs to a previous day.
     */
    public void rotateIfNeeded() {
        if (!logFile.exists()) {
            return;
        }

        String today = SDF.format(new Date());
        String lastModified = SDF.format(new Date(logFile.lastModified()));
        if (today.equals(lastModified)) {
            return;
        }

        File backup = new File(logFile.getParent(), "logfile.txt" + lastModified);
        int counter = 1;
        while (backup.exists()) {
            backup = new File(logFile.getParent(), "logfile.txt" + lastModified + "_" + counter);
            counter++;
        }

        if (!logFile.renameTo(backup)) {
            throw new IllegalStateException("failed to rotate log file to " + backup.getAbsolutePath());
        }
    }

    /**
     * Append a timestamped line to the log file.
     */
    public void writeLine(String line) throws IOException {
        String timestamped = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date()) + " " + line;
        Files.write(logFile.toPath(),
                (timestamped + System.lineSeparator()).getBytes(StandardCharsets.UTF_8),
                StandardOpenOption.CREATE, StandardOpenOption.APPEND);
    }

    public File getLogFile() {
        return logFile;
    }
}
