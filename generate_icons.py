#!/usr/bin/env python3
"""Generate launcher icons for Android and iOS from the logo.png file."""

from PIL import Image
import os

# Base paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
LOGO_PATH = os.path.join(BASE_DIR, 'assets/icon/logo.png')

# Android icon sizes (mipmap)
ANDROID_SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# iOS icon sizes
IOS_SIZES = [
    (20, 'Icon-App-20x20@1x.png'),
    (40, 'Icon-App-20x20@2x.png'),
    (60, 'Icon-App-20x20@3x.png'),
    (29, 'Icon-App-29x29@1x.png'),
    (58, 'Icon-App-29x29@2x.png'),
    (87, 'Icon-App-29x29@3x.png'),
    (40, 'Icon-App-40x40@1x.png'),
    (80, 'Icon-App-40x40@2x.png'),
    (120, 'Icon-App-40x40@3x.png'),
    (57, 'Icon-App-57x57@1x.png'),
    (114, 'Icon-App-57x57@2x.png'),
    (60, 'Icon-App-60x60@1x.png'),
    (120, 'Icon-App-60x60@2x.png'),
    (180, 'Icon-App-60x60@3x.png'),
    (72, 'Icon-App-72x72@1x.png'),
    (144, 'Icon-App-72x72@2x.png'),
    (76, 'Icon-App-76x76@1x.png'),
    (152, 'Icon-App-76x76@2x.png'),
    (167, 'Icon-App-83.5x83.5@2x.png'),
    (1024, 'Icon-App-1024x1024@1x.png'),
]

def generate_android_icons(logo_img):
    """Generate Android launcher icons."""
    android_dir = os.path.join(BASE_DIR, 'android/app/src/main/res')
    
    for folder, size in ANDROID_SIZES.items():
        output_dir = os.path.join(android_dir, folder)
        os.makedirs(output_dir, exist_ok=True)
        
        # Create foreground icon (with padding for adaptive icon)
        foreground = logo_img.resize((size, size), Image.Resampling.LANCZOS)
        foreground_path = os.path.join(output_dir, 'ic_launcher_foreground.png')
        foreground.save(foreground_path)
        
        # Create regular icon
        icon = logo_img.resize((size, size), Image.Resampling.LANCZOS)
        icon_path = os.path.join(output_dir, 'ic_launcher.png')
        icon.save(icon_path)
        
        # Create round icon
        round_icon_path = os.path.join(output_dir, 'ic_launcher_round.png')
        icon.save(round_icon_path)
        
        print(f'Generated Android {folder} icons ({size}x{size})')

def generate_ios_icons(logo_img):
    """Generate iOS launcher icons."""
    ios_dir = os.path.join(BASE_DIR, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    os.makedirs(ios_dir, exist_ok=True)
    
    for size, filename in IOS_SIZES:
        icon = logo_img.resize((size, size), Image.Resampling.LANCZOS)
        icon_path = os.path.join(ios_dir, filename)
        icon.save(icon_path)
        print(f'Generated iOS {filename} ({size}x{size})')
    
    # Generate Contents.json
    contents = {
        "images": [
            {
                "filename": f,
                "idiom": "universal",
                "platform": "ios",
                "size": f"{s}x{s}"
            }
            for s, f in IOS_SIZES
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    import json
    contents_path = os.path.join(ios_dir, 'Contents.json')
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    print('Generated iOS Contents.json')

def main():
    print(f'Loading logo from {LOGO_PATH}')
    logo_img = Image.open(LOGO_PATH)
    
    # Convert to RGBA if necessary
    if logo_img.mode != 'RGBA':
        logo_img = logo_img.convert('RGBA')
    
    print(f'Logo size: {logo_img.size}')
    
    # Generate Android icons
    generate_android_icons(logo_img)
    
    # Generate iOS icons
    generate_ios_icons(logo_img)
    
    print('\nAll icons generated successfully!')

if __name__ == '__main__':
    main()
