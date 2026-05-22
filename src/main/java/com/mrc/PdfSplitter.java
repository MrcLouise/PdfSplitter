package com.mrc;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import javax.swing.filechooser.FileNameExtensionFilter;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class PdfSplitter {

    private static final Color APPLE_BLUE = new Color(0, 122, 255);
    private static final Color APPLE_BLUE_DARK = new Color(0, 100, 210);
    private static final Color APPLE_BLUE_PRESSED = new Color(0, 80, 180);
    private static final Color BG_GRAY = new Color(245, 246, 250);
    private static final Color TEXT_DARK = new Color(50, 50, 50);
    private static final Color BORDER_GRAY = new Color(220, 220, 220);
    private static final Color DANGER_RED = new Color(220, 53, 69);

    // Unified button padding: same height for all buttons
    private static final Insets BTN_PADDING = new Insets(11, 28, 11, 28);
    private static final Font BTN_FONT = new Font("Dialog", Font.BOLD, 15);

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
        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        } catch (Exception ignored) {}

        JFrame frame = new JFrame("PDF Splitter Tool");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setSize(680, 580);
        frame.setLocationRelativeTo(null);
        frame.setResizable(true);
        frame.getContentPane().setBackground(BG_GRAY);

        JPanel mainPanel = new JPanel(new BorderLayout(15, 15));
        mainPanel.setBackground(BG_GRAY);
        mainPanel.setBorder(BorderFactory.createEmptyBorder(20, 25, 20, 25));

        // === TOP: Title + Buttons ===
        JPanel topPanel = new JPanel(new GridBagLayout());
        topPanel.setBackground(BG_GRAY);
        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(8, 5, 8, 5);
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.gridx = 0; gbc.gridy = 0;

        JLabel title = new JLabel("PDF Splitter", SwingConstants.CENTER);
        title.setFont(new Font("Dialog", Font.BOLD, 26));
        title.setForeground(TEXT_DARK);
        topPanel.add(title, gbc);

        gbc.gridy = 1;
        JLabel info = new JLabel("Select PDF files and output folder, then click Start Split", SwingConstants.CENTER);
        info.setFont(new Font("Dialog", Font.PLAIN, 14));
        info.setForeground(new Color(100, 100, 100));
        topPanel.add(info, gbc);

        gbc.gridy = 2;
        gbc.insets = new Insets(15, 5, 5, 5);
        JPanel btnPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 18, 0));
        btnPanel.setBackground(BG_GRAY);

        JButton selectBtn = createOutlineButton("Select PDF File(s)");
        btnPanel.add(selectBtn);

        JButton startBtn = createPrimaryButton("Start Split");
        startBtn.setEnabled(false);
        btnPanel.add(startBtn);

        JButton clearBtn = createGhostButton("Clear List");
        clearBtn.setEnabled(false);
        btnPanel.add(clearBtn);

        topPanel.add(btnPanel, gbc);
        mainPanel.add(topPanel, BorderLayout.NORTH);

        // === CENTER: File list + Output dir ===
        JPanel centerPanel = new JPanel(new BorderLayout(10, 10));
        centerPanel.setBackground(BG_GRAY);

        JPanel fileCard = new JPanel(new BorderLayout(5, 5));
        fileCard.setBackground(Color.WHITE);
        fileCard.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_GRAY, 1),
                BorderFactory.createEmptyBorder(12, 12, 12, 12)
        ));

        JLabel fileCardTitle = new JLabel("Selected Files");
        fileCardTitle.setFont(new Font("Dialog", Font.BOLD, 14));
        fileCardTitle.setForeground(TEXT_DARK);
        fileCardTitle.setBorder(new EmptyBorder(0, 4, 8, 0));
        fileCard.add(fileCardTitle, BorderLayout.NORTH);

        DefaultListModel<String> fileListModel = new DefaultListModel<>();
        JList<String> fileList = new JList<>(fileListModel);
        fileList.setFont(new Font("Dialog", Font.PLAIN, 14));
        fileList.setBackground(new Color(250, 250, 252));
        fileList.setBorder(BorderFactory.createEmptyBorder(5, 8, 5, 8));
        JScrollPane scrollPane = new JScrollPane(fileList);
        scrollPane.setBorder(BorderFactory.createLineBorder(BORDER_GRAY));
        scrollPane.setPreferredSize(new Dimension(550, 220));
        fileCard.add(scrollPane, BorderLayout.CENTER);
        centerPanel.add(fileCard, BorderLayout.CENTER);

        JPanel outputCard = new JPanel(new BorderLayout(10, 0));
        outputCard.setBackground(Color.WHITE);
        outputCard.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(BORDER_GRAY, 1),
                BorderFactory.createEmptyBorder(12, 15, 12, 15)
        ));

        JLabel outputTitle = new JLabel("Output Directory");
        outputTitle.setFont(new Font("Dialog", Font.BOLD, 13));
        outputTitle.setForeground(TEXT_DARK);

        JLabel outputLabel = new JLabel("split_output");
        outputLabel.setFont(new Font("Dialog", Font.PLAIN, 13));
        outputLabel.setForeground(new Color(80, 80, 80));

        JPanel outputTextPanel = new JPanel(new GridLayout(2, 1, 2, 2));
        outputTextPanel.setBackground(Color.WHITE);
        outputTextPanel.add(outputTitle);
        outputTextPanel.add(outputLabel);
        outputCard.add(outputTextPanel, BorderLayout.CENTER);

        JButton outputBtn = createSmallButton("Change...");
        outputCard.add(outputBtn, BorderLayout.EAST);

        centerPanel.add(outputCard, BorderLayout.SOUTH);
        mainPanel.add(centerPanel, BorderLayout.CENTER);

        // === BOTTOM: Status bar ===
        JPanel statusPanel = new JPanel(new BorderLayout());
        statusPanel.setBackground(new Color(230, 235, 245));
        statusPanel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(200, 210, 230), 1),
                BorderFactory.createEmptyBorder(10, 15, 10, 15)
        ));
        JLabel status = new JLabel("Ready - Please select PDF files", SwingConstants.CENTER);
        status.setFont(new Font("Dialog", Font.PLAIN, 13));
        status.setForeground(TEXT_DARK);
        statusPanel.add(status, BorderLayout.CENTER);
        mainPanel.add(statusPanel, BorderLayout.SOUTH);

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

    // === Button Styles - Unified height, round corners, Apple Blue ===

    private static JButton createPrimaryButton(String text) {
        JButton btn = new JButton(text);
        btn.setFont(BTN_FONT);
        btn.setBackground(APPLE_BLUE);
        btn.setForeground(Color.WHITE);
        btn.setOpaque(true);
        btn.setContentAreaFilled(true);
        btn.setBorderPainted(false);
        btn.setFocusPainted(false);
        btn.setCursor(new Cursor(Cursor.HAND_CURSOR));
        btn.setBorder(BorderFactory.createEmptyBorder(BTN_PADDING.top, BTN_PADDING.left, BTN_PADDING.bottom, BTN_PADDING.right));

        applyPrimaryColors(btn, true);

        btn.addMouseListener(new MouseAdapter() {
            public void mouseEntered(MouseEvent e) {
                if (btn.isEnabled()) {
                    btn.setBackground(APPLE_BLUE_DARK);
                    btn.setForeground(Color.WHITE);
                }
            }
            public void mouseExited(MouseEvent e) {
                if (btn.isEnabled()) applyPrimaryColors(btn, true);
            }
            public void mousePressed(MouseEvent e) {
                if (btn.isEnabled()) btn.setBackground(APPLE_BLUE_PRESSED);
            }
            public void mouseReleased(MouseEvent e) {
                if (btn.isEnabled()) btn.setBackground(APPLE_BLUE_DARK);
            }
        });

        btn.addPropertyChangeListener("enabled", evt -> {
            applyPrimaryColors(btn, (Boolean) evt.getNewValue());
        });

        return btn;
    }

    private static void applyPrimaryColors(JButton btn, boolean enabled) {
        if (enabled) {
            btn.setBackground(APPLE_BLUE);
            btn.setForeground(Color.WHITE);
        } else {
            btn.setBackground(new Color(200, 210, 230));
            btn.setForeground(new Color(140, 140, 140));
        }
    }

    private static JButton createOutlineButton(String text) {
        JButton btn = new JButton(text);
        btn.setFont(BTN_FONT);
        btn.setBackground(Color.WHITE);
        btn.setForeground(APPLE_BLUE);
        btn.setOpaque(true);
        btn.setContentAreaFilled(true);
        btn.setBorderPainted(true);
        btn.setFocusPainted(false);
        btn.setCursor(new Cursor(Cursor.HAND_CURSOR));
        // Border 2px + inner padding = same total height as primary button
        btn.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(APPLE_BLUE, 2),
                BorderFactory.createEmptyBorder(BTN_PADDING.top - 2, BTN_PADDING.left - 2, BTN_PADDING.bottom - 2, BTN_PADDING.right - 2)
        ));

        btn.addMouseListener(new MouseAdapter() {
            public void mouseEntered(MouseEvent e) {
                if (btn.isEnabled()) {
                    btn.setBackground(APPLE_BLUE);
                    btn.setForeground(Color.WHITE);
                }
            }
            public void mouseExited(MouseEvent e) {
                if (btn.isEnabled()) {
                    btn.setBackground(Color.WHITE);
                    btn.setForeground(APPLE_BLUE);
                }
            }
        });
        return btn;
    }

    private static JButton createGhostButton(String text) {
        JButton btn = new JButton(text);
        btn.setFont(BTN_FONT);
        btn.setForeground(new Color(100, 100, 100));
        btn.setBackground(BG_GRAY);
        btn.setOpaque(true);
        btn.setContentAreaFilled(true);
        btn.setBorderPainted(false);
        btn.setFocusPainted(false);
        btn.setCursor(new Cursor(Cursor.HAND_CURSOR));
        // Same padding = same height as primary button
        btn.setBorder(BorderFactory.createEmptyBorder(BTN_PADDING.top, BTN_PADDING.left, BTN_PADDING.bottom, BTN_PADDING.right));

        btn.addMouseListener(new MouseAdapter() {
            public void mouseEntered(MouseEvent e) {
                if (btn.isEnabled()) {
                    btn.setForeground(DANGER_RED);
                    btn.setBackground(new Color(255, 235, 238));
                }
            }
            public void mouseExited(MouseEvent e) {
                if (btn.isEnabled()) {
                    btn.setForeground(new Color(100, 100, 100));
                    btn.setBackground(BG_GRAY);
                }
            }
        });
        return btn;
    }

    private static JButton createSmallButton(String text) {
        JButton btn = new JButton(text);
        btn.setFont(new Font("Dialog", Font.PLAIN, 12));
        btn.setForeground(APPLE_BLUE);
        btn.setBackground(new Color(235, 245, 255));
        btn.setOpaque(true);
        btn.setBorderPainted(false);
        btn.setFocusPainted(false);
        btn.setCursor(new Cursor(Cursor.HAND_CURSOR));
        btn.setBorder(BorderFactory.createEmptyBorder(6, 16, 6, 16));

        btn.addMouseListener(new MouseAdapter() {
            public void mouseEntered(MouseEvent e) {
                if (btn.isEnabled()) btn.setBackground(new Color(220, 235, 255));
            }
            public void mouseExited(MouseEvent e) {
                if (btn.isEnabled()) btn.setBackground(new Color(235, 245, 255));
            }
        });
        return btn;
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