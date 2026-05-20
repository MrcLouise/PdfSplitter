package com.mrc;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;

import javax.swing.*;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.awt.*;
import java.io.File;
import java.io.IOException;

public class PdfSplitter {

    public static void main(String[] args) {
        if (GraphicsEnvironment.isHeadless() || args.length > 0) {
            runCli(args);
        } else {
            runGui();
        }
    }

    private static void runCli(String[] args) {
        if (args.length < 1) {
            System.out.println("Usage: java -jar PdfSplitter.jar <input.pdf> [output_dir]");
            System.out.println("Example: java -jar PdfSplitter.jar /Users/mrc/document.pdf /Users/mrc/output");
            System.exit(1);
        }
        File input = new File(args[0]);
        File outputDir = args.length > 1 ? new File(args[1]) : new File(".");
        int pages = splitPdf(input, outputDir);
        System.out.println("\nDone! Split " + pages + " pages. Output: " + outputDir.getAbsolutePath());
    }

    private static void runGui() {
        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception ignored) {}

        JFrame frame = new JFrame("PDF Splitter Tool");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setSize(520, 240);
        frame.setLocationRelativeTo(null);
        frame.setResizable(false);

        JPanel panel = new JPanel(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(10, 15, 10, 15);
        gbc.fill = GridBagConstraints.HORIZONTAL;

        JLabel title = new JLabel("PDF Splitter", SwingConstants.CENTER);
        title.setFont(new Font("Dialog", Font.BOLD, 18));
        gbc.gridx = 0; gbc.gridy = 0; gbc.gridwidth = 2;
        panel.add(title, gbc);

        JLabel info = new JLabel("Select a multi-page PDF to split into single-page files", SwingConstants.CENTER);
        gbc.gridy = 1;
        panel.add(info, gbc);

        JButton btn = new JButton("Select PDF File");
        btn.setFont(new Font("Dialog", Font.PLAIN, 14));
        gbc.gridy = 2; gbc.ipady = 8;
        panel.add(btn, gbc);

        JLabel status = new JLabel(" ", SwingConstants.CENTER);
        status.setFont(new Font("Dialog", Font.PLAIN, 12));
        gbc.gridy = 3; gbc.ipady = 0;
        panel.add(status, gbc);

        btn.addActionListener(e -> {
            JFileChooser chooser = new JFileChooser();
            chooser.setFileFilter(new FileNameExtensionFilter("PDF Files (*.pdf)", "pdf"));
            chooser.setDialogTitle("Select PDF to Split");
            if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                File input = chooser.getSelectedFile();
                File outputDir = new File(chooser.getCurrentDirectory(), "split_output");
                btn.setEnabled(false);
                status.setText("Splitting, please wait...");

                new Thread(() -> {
                    try {
                        int pages = splitPdf(input, outputDir);
                        SwingUtilities.invokeLater(() -> {
                            status.setText("<html>Done! Split <b>" + pages + "</b> pages<br>Saved to: " + outputDir.getAbsolutePath() + "</html>");
                            btn.setEnabled(true);
                        });
                    } catch (Exception ex) {
                        SwingUtilities.invokeLater(() -> {
                            status.setText("Error: " + ex.getMessage());
                            btn.setEnabled(true);
                        });
                        ex.printStackTrace();
                    }
                }).start();
            }
        });

        frame.add(panel);
        frame.setVisible(true);
    }

    public static int splitPdf(File inputPdf, File outputDir) {
        if (!inputPdf.exists()) {
            throw new RuntimeException("File not found: " + inputPdf.getAbsolutePath());
        }
        if (!outputDir.exists()) {
            outputDir.mkdirs();
        }

        String baseName = inputPdf.getName();
        int dotIndex = baseName.lastIndexOf('.');
        if (dotIndex > 0) {
            baseName = baseName.substring(0, dotIndex);
        }

        try (PDDocument sourceDoc = PDDocument.load(inputPdf)) {
            int total = sourceDoc.getNumberOfPages();

            for (int i = 0; i < total; i++) {
                try (PDDocument singlePageDoc = new PDDocument()) {
                    PDPage page = sourceDoc.getPage(i);
                    singlePageDoc.addPage(page);
                    String outputName = String.format("%s_%03d.pdf", baseName, i + 1);
                    File outputFile = new File(outputDir, outputName);
                    singlePageDoc.save(outputFile);
                }
            }
            System.out.println("Split complete: " + total + " pages");
            return total;
        } catch (IOException e) {
            throw new RuntimeException("Split failed: " + e.getMessage(), e);
        }
    }
}