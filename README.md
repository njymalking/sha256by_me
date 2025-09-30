# Flutter SHA256 + PDF Report

A minimal Flutter app that:
- Computes SHA256 of input text or a picked file.
- Generates a simple PDF report containing the computed hash and metadata.
- Uses `file_picker` to select files, `crypto` for hashing, and `pdf` + `printing` to create/share the PDF.

## How to use
1. Install Flutter SDK (stable).
2. From project root run:
   ```bash
   flutter pub get
   flutter run
   ```
3. On the app:
   - Enter text and tap **Compute SHA256 (text)** to compute a hash.
   - Or tap **Pick File & Compute** to pick a file and compute its SHA256.
   - When a hash is available, tap **Create PDF Report** to generate and share the PDF.

## Notes
- The code uses `Printing.sharePdf` which opens the platform share/print UI.
- Adjust dependency versions in `pubspec.yaml` if necessary for your Flutter SDK.
