package com.mrc;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;

import javax.swing.*;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.awt.*;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

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
            System.exit(1);
        }
        File input = new File(args[0]);
        File outputDir = args.length > 1 ? new File(args[1]) : new File(".");
        int pages = splitPdf(input, outputDir);
        System.out.println("\nDone! Split " + pages + " pages. Output: " + outputDir.getAbsolutePath());
    }

    private static void runGui() {
        System.setProperty("awt.useSystemAAFontSettings", "lcd");
        System.setProperty("swing.aatext", "true");
        System.setProperty("sun.java2d.uiScale", "1.0");

        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception ignored) {}

        JFrame frame = new JFrame("PDF Splitter Tool");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setSize(600, 500);
        frame.setLocationRelativeTo(null);
        frame.setResizable(true);

        JPanel mainPanel = new JPanel(new BorderLayout(10, 10));
        mainPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        // === TOP: Title + Buttons ===
        JPanel topPanel = new JPanel(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(5, 5, 5, 5);
        gbc.gridx = 0;

        JLabel title = new JLabel("PDF Splitter", SwingConstants.CENTER);
        title.setFont(new Font("Segoe UI", Font.BOLD, 22));
        gbc.gridy = 0;
        topPanel.add(title, gbc);

        JLabel info = new JLabel("Select PDF files and output folder, then click Start Split", SwingConstants.CENTER);
        info.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        gbc.gridy = 1;
        topPanel.add(info, gbc);

        JPanel btnPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 10, 0));
        gbc.gridy = 2;
        gbc.insets = new Insets(10, 5, 5, 5);

        JButton selectBtn = new JButton("Select PDF File(s)");
        JButton startBtn = new JButton("Start Split");
        startBtn.setEnabled(false);
        JButton clearBtn = new JButton("Clear List");
        clearBtn.setEnabled(false);

        btnPanel.add(selectBtn);
        btnPanel.add(startBtn);
        btnPanel.add(clearBtn);
        topPanel.add(btnPanel, gbc);
        mainPanel.add(topPanel, BorderLayout.NORTH);

        // === CENTER: File list + Output dir ===
        JPanel centerPanel = new JPanel(new BorderLayout(10, 10));

        JLabel fileLabel = new JLabel("Selected Files:");
        fileLabel.setFont(new Font("Segoe UI", Font.BOLD, 13));
        DefaultListModel<String> fileListModel = new DefaultListModel<>();
        JList<String> fileList = new JList<>(fileListModel);
        fileList.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        JScrollPane scrollPane = new JScrollPane(fileList);
        scrollPane.setPreferredSize(new Dimension(550, 200));

        JPanel filePanel = new JPanel(new BorderLayout(5, 5));
        filePanel.add(fileLabel, BorderLayout.NORTH);
        filePanel.add(scrollPane, BorderLayout.CENTER);
        centerPanel.add(filePanel, BorderLayout.CENTER);

        JPanel outputPanel = new JPanel(new BorderLayout(10, 0));
        JLabel outputLabel = new JLabel("split_output");
        outputLabel.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        JButton outputBtn = new JButton("Change...");

        JPanel outputLeft = new JPanel(new GridLayout(2, 1, 2, 2));
        JLabel outputTitle = new JLabel("Output Directory:");
        outputTitle.setFont(new Font("Segoe UI", Font.BOLD, 13));
        outputLeft.add(outputTitle);
        outputLeft.add(outputLabel);

        outputPanel.add(outputLeft, BorderLayout.CENTER);
        outputPanel.add(outputBtn, BorderLayout.EAST);
        centerPanel.add(outputPanel, BorderLayout.SOUTH);
        mainPanel.add(centerPanel, BorderLayout.CENTER);

        // === BOTTOM: Status bar ===
        JLabel status = new JLabel("Ready - Please select PDF files", SwingConstants.CENTER);
        status.setFont(new Font("Segoe UI", Font.PLAIN, 13));
        status.setBorder(BorderFactory.createEmptyBorder(8, 5, 8, 5));
        mainPanel.add(status, BorderLayout.SOUTH);

        frame.add(mainPanel);
        frame.setVisible(true);

        // === State ===
        final List<File> selectedFiles = new ArrayList<>();
        final File[] outputDirHolder = new File[1];
        outputDirHolder[0] = new File("split_output");

        // === Select Output Directory ===
        outputBtn.addActionListener(e -> {
            JFileChooser chooser = new JFileChooser();
            chooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
            chooser.setDialogTitle("Select Output Directory");
            chooser.setCurrentDirectory(new File("."));

            if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                File selected = chooser.getSelectedFile();
                outputDirHolder[0] = selected;
                outputLabel.setText(selected.getAbsolutePath());
                status.setText("Output set to: " + selected.getAbsolutePath());
            }
        });

        // === Select PDF Files ===
        selectBtn.addActionListener(e -> {
            JFileChooser chooser = new JFileChooser();
            chooser.setFileFilter(new FileNameExtensionFilter("PDF Files (*.pdf)", "pdf"));
            chooser.setDialogTitle("Select PDF(s) to Split");
            chooser.setMultiSelectionEnabled(true);

            if (chooser.showOpenDialog(frame) == JFileChooser.APPROVE_OPTION) {
                File[] inputs = chooser.getSelectedFiles();

                for (File f : inputs) {
                    boolean exists = false;
                    for (File existing : selectedFiles) {
                        if (existing.getAbsolutePath().equals(f.getAbsolutePath())) {
                            exists = true;
                            break;
                        }
                    }
                    if (!exists) {
                        selectedFiles.add(f);
                        fileListModel.addElement(f.getName());
                    }
                }

                if (!selectedFiles.isEmpty()) {
                    startBtn.setEnabled(true);
                    clearBtn.setEnabled(true);
                    status.setText("Selected " + selectedFiles.size() + " file(s) total. Output: " + outputDirHolder[0].getAbsolutePath());
                }
            }
        });

        // === Clear Button ===
        clearBtn.addActionListener(e -> {
            selectedFiles.clear();
            fileListModel.clear();
            startBtn.setEnabled(false);
            clearBtn.setEnabled(false);
            status.setText("Ready - Please select PDF files");
        });

        // === Start Split Button ===
        startBtn.addActionListener(e -> {
            if (selectedFiles.isEmpty()) {
                status.setText("Error: No files selected");
                return;
            }

            final File finalOutputDir = outputDirHolder[0];

            startBtn.setEnabled(false);
            selectBtn.setEnabled(false);
            clearBtn.setEnabled(false);
            outputBtn.setEnabled(false);
            status.setText("Processing " + selectedFiles.size() + " file(s)...");

            new Thread(() -> {
                int totalFiles = 0;
                int totalPages = 0;
                StringBuilder errors = new StringBuilder();

                for (int idx = 0; idx < selectedFiles.size(); idx++) {
                    File input = selectedFiles.get(idx);
                    try {
                        int pages = splitPdf(input, finalOutputDir);
                        totalFiles++;
                        totalPages += pages;
                        SwingUtilities.invokeLater(() -> {
                            String name = input.getName();
                            for (int i = 0; i < fileListModel.size(); i++) {
                                if (fileListModel.get(i).equals(name)) {
                                    fileListModel.set(i, "[Done] " + name + " (" + pages + " pages)");
                                    break;
                                }
                            }
                        });
                    } catch (Exception ex) {
                        errors.append(input.getName()).append(": ").append(ex.getMessage()).append("\n");
                        SwingUtilities.invokeLater(() -> {
                            String name = input.getName();
                            for (int i = 0; i < fileListModel.size(); i++) {
                                if (fileListModel.get(i).equals(name)) {
                                    fileListModel.set(i, "[Error] " + name);
                                    break;
                                }
                            }
                        });
                    }
                }

                final int finalFiles = totalFiles;
                final int finalPages = totalPages;
                final String finalErrors = errors.toString();

                SwingUtilities.invokeLater(() -> {
                    if (finalFiles > 0) {
                        String msg = "Done! Processed " + finalFiles + " file(s), " + finalPages + " pages total. Output: " + finalOutputDir.getAbsolutePath();
                        if (!finalErrors.isEmpty()) {
                            msg += " | Errors: " + finalErrors.replace("\n", " ");
                        }
                        status.setText(msg);
                    } else {
                        status.setText("Error: No files were processed. " + finalErrors.replace("\n", " "));
                    }
                    startBtn.setEnabled(true);
                    selectBtn.setEnabled(true);
                    clearBtn.setEnabled(true);
                    outputBtn.setEnabled(true);
                });
            }).start();
        });
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
            System.out.println("Split complete: " + inputPdf.getName() + " -> " + total + " pages");
            return total;
        } catch (IOException e) {
            throw new RuntimeException("Split failed: " + e.getMessage(), e);
        }
    }
}