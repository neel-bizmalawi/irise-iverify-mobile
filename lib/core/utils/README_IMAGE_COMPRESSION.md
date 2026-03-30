# Image Compression Implementation

## Overview
This implementation provides image capture and compression functionality for the BeneficiaryRegistrationScreen and EditHouseholdScreen.

## Features

### 1. Image Capture
- **Camera**: Capture images directly from device camera
- **Gallery**: Select images from device gallery
- User-friendly bottom sheet modal for source selection

### 2. Image Compression
- **Target Size**: 500KB (configurable)
- **Quality**: Starts at 85% and reduces if needed
- **Resolution**: Max 1024x1024 pixels
- **Automatic**: Compression happens automatically after capture

### 3. Storage
- Images are saved to app documents directory
- Compressed images are stored in local database
- File paths are saved in beneficiary table

## Usage

### BeneficiaryRegistrationScreen
Captures three types of images:
1. **National ID Image**: Photo of beneficiary's national ID card
2. **House Image**: Photo of beneficiary's house (not implemented in registration, only in edit)
3. **Cookstove Image**: Photo of cookstove (not implemented in registration, only in edit)

### EditHouseholdScreen
Captures two types of images:
1. **House Image**: Photo of beneficiary's house
2. **Cookstove Image**: Photo of installed cookstove

## Technical Details

### Dependencies
```yaml
image_picker: ^1.0.7          # For camera/gallery access
flutter_image_compress: ^2.1.0 # For image compression
```

### Compression Algorithm
1. Check original file size
2. If > 500KB, compress with quality 85%
3. If still > 500KB, reduce quality by 15% and retry
4. Minimum quality: 50%
5. Maximum resolution: 1024x1024

### File Naming Convention
```
{prefix}_{timestamp}.{extension}
```
Examples:
- `national_id_1711234567890.jpg`
- `house_1711234567890.jpg`
- `cookstove_1711234567890.jpg`

## Permissions Required

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to capture images</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select images</string>
```

## Database Storage
Images are stored as file paths in the beneficiary table:
- `national_id_attachment`: Path to national ID image
- `house_pic`: Path to house image
- `cookstove_pic`: Path to cookstove image
- Corresponding timestamp fields for each image

## Error Handling
- Permission denied: Shows error message
- Compression failed: Returns original file
- Save failed: Shows error snackbar
- Loading indicators during processing

## Future Improvements
- Add image preview before saving
- Support for multiple images per type
- Cloud storage integration
- Image quality selection by user
- Batch compression for multiple images
