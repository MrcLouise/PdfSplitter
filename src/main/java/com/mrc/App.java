package com.mrc;

import com.mrc.pdf.PdfProcessor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class App {

    private static final Logger log = LoggerFactory.getLogger(App.class);

    public static void main(String[] args) {
        if (args.length < 1) {
            log.error("usage: PdfSplitter PROCESS <bulkUploadDir> [outputDir] [attachmentDir] [extraOutputDir]");
            System.exit(1);
        }

        String cmd = args[0].toUpperCase();
        if (!cmd.equals("PROCESS")) {
            log.error("unknown command: " + cmd);
            System.exit(1);
        }

        String[] subArgs = new String[args.length - 1];
        System.arraycopy(args, 1, subArgs, 0, subArgs.length);
        PdfProcessor.main(subArgs);
    }
}
